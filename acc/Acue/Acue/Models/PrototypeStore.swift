//
//  PrototypeStore.swift
//  Acue
//

import SwiftUI
import Combine

enum AppScreen: String, CaseIterable, Identifiable {
    case unpaired
    case coPresence
    case soloOnline
    case partnerOnly
    case idle
    case unreadSignal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unpaired: return "未配对"
        case .coPresence: return "同在"
        case .soloOnline: return "仅你在"
        case .partnerOnly: return "留空位"
        case .idle: return "各自在"
        case .unreadSignal: return "未读叩"
        }
    }
}

struct CoTimeEntry: Identifiable {
    let id = UUID()
    let label: String
    let duration: String
}

struct SignalEntry: Identifiable {
    let id = UUID()
    let time: String
    let pattern: String
    let dictionaryLabel: String?
}

struct LampState: Equatable {
    var isOnline: Bool = true
    var warmth: Double = 0.5
    var brightness: Double = 1.0
    var breathPeriod: Double = 3.0
    var shaded: Bool = false
    var caption: String = ""
    var moodLabel: String = ""
    var hasUnreadHalo: Bool = false
}

@MainActor
final class PrototypeStore: ObservableObject {
    @Published var screen: AppScreen = .unpaired
    @Published var inviteCode: String = ""
    @Published var showRecords = false
    @Published var recordsTab: RecordsTab = .coTime
    @Published var selfLamp = LampState(isOnline: true, caption: "", moodLabel: "")
    @Published var partnerLamp = LampState(isOnline: false, caption: "", moodLabel: "")
    @Published var coTimeMinutes: Int = 0
    @Published var lastCoPresenceLabel = "上次同在  —"
    @Published var flashSelf = false
    @Published var flashPartner = false
    @Published var toast: String?
    @Published var isPairingBusy = false
    @Published var iCloudReady = false
    @Published var usePrototypeOverrides = false

    @Published private(set) var syncedSignalEntries: [SignalEntry] = []

    private let pairSync = PairSyncService.shared
    private var lastAppliedCoPresenceMinutes = 0

    let coTimeEntries: [CoTimeEntry] = [
        CoTimeEntry(label: "6/28  23:14 – 00:22", duration: "1h 08m"),
        CoTimeEntry(label: "6/27  21:03 – 22:41", duration: "1h 38m"),
        CoTimeEntry(label: "6/25  00:11 – 01:47", duration: "1h 36m")
    ]

    var signalEntries: [SignalEntry] {
        syncedSignalEntries.isEmpty ? defaultSignalEntries : syncedSignalEntries
    }

    private let defaultSignalEntries: [SignalEntry] = [
        SignalEntry(time: "昨天 23:05", pattern: "· · ·", dictionaryLabel: "拍了拍你的狗头"),
        SignalEntry(time: "6/28 14:32", pattern: "· — · · —", dictionaryLabel: nil)
    ]

    var bottomMetric: String? {
        switch screen {
        case .coPresence:
            return "共时 \(coTimeMinutes) 分钟"
        case .soloOnline, .partnerOnly, .idle, .unreadSignal:
            return lastCoPresenceLabel
        case .unpaired:
            return nil
        }
    }

    var isPaired: Bool { screen != .unpaired }

    func bootstrap() async {
        iCloudReady = await pairSync.checkAccountStatus()
        guard pairSync.isPairedLocally else {
            screen = .unpaired
            return
        }

        resumeCloudSync()
        do {
            let snapshot = try await pairSync.fetchSnapshot()
            selfLamp.isOnline = snapshot.selfOnline
            selfLamp.caption = snapshot.selfCaption
            selfLamp.moodLabel = snapshot.selfMood
            applySnapshot(snapshot, notifyKnock: false)
            await pushLocalPresence()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    func prepareInviteIfNeeded() async {
        guard !pairSync.isPairedLocally else { return }
        guard iCloudReady else {
            showToast("跨网络配对需 iCloud + 付费开发者账号")
            return
        }

        isPairingBusy = true
        defer { isPairingBusy = false }

        do {
            inviteCode = try await pairSync.prepareHostInvite()
            startWaitingForPartner()
        } catch {
            showToast(error.localizedDescription)
        }
    }

    func joinPair(with code: String) async {
        guard iCloudReady else {
            showToast("跨网络配对需 iCloud + 付费开发者账号")
            return
        }

        isPairingBusy = true
        defer { isPairingBusy = false }

        do {
            try await pairSync.join(with: code)
            inviteCode = code.uppercased()
            resumeCloudSync()
            let snapshot = try await pairSync.fetchSnapshot()
            selfLamp.isOnline = snapshot.selfOnline
            selfLamp.caption = snapshot.selfCaption
            selfLamp.moodLabel = snapshot.selfMood
            applySnapshot(snapshot, notifyKnock: false)
            await pushLocalPresence()
            showToast("已连接")
        } catch {
            showToast(error.localizedDescription)
        }
    }

    func unpair() {
        pairSync.unpair()
        pairSync.stopPolling()
        screen = .unpaired
        inviteCode = ""
        coTimeMinutes = 0
        partnerLamp = LampState(isOnline: false)
        selfLamp = LampState(isOnline: true)
        syncedSignalEntries = []
        LiveActivityManager.shared.endImmediately()
        showToast("已解除配对")
    }

    func applyScreen(_ screen: AppScreen) {
        guard usePrototypeOverrides else { return }
        self.screen = screen
        switch screen {
        case .unpaired:
            LiveActivityManager.shared.endImmediately()
        case .coPresence:
            selfLamp.isOnline = true
            selfLamp.caption = "熬夜中"
            selfLamp.moodLabel = "累了"
            partnerLamp.isOnline = true
            partnerLamp.caption = "等你回"
            partnerLamp.moodLabel = ""
            partnerLamp.hasUnreadHalo = false
            coTimeMinutes = 47
        case .soloOnline:
            selfLamp.isOnline = true
            partnerLamp.isOnline = false
            partnerLamp.hasUnreadHalo = false
        case .partnerOnly:
            selfLamp.isOnline = false
            partnerLamp.isOnline = true
            partnerLamp.hasUnreadHalo = false
        case .idle:
            selfLamp.isOnline = false
            partnerLamp.isOnline = false
            partnerLamp.hasUnreadHalo = false
        case .unreadSignal:
            selfLamp.isOnline = true
            partnerLamp.isOnline = true
            partnerLamp.hasUnreadHalo = true
        }
        refreshLiveActivity()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        if phase == .background {
            refreshLiveActivity(forceStart: true)
        }
        if phase == .active, isPaired, !usePrototypeOverrides {
            Task { await pushLocalPresence() }
        }
    }

    func refreshLiveActivity(forceStart: Bool = false) {
        guard isPaired else {
            LiveActivityManager.shared.endImmediately()
            return
        }
        guard forceStart || LiveActivityManager.shared.isRunning else { return }
        LiveActivityManager.shared.sync(
            partnerOnline: partnerLamp.isOnline,
            selfOnline: selfLamp.isOnline,
            coTimeMinutes: coTimeMinutes,
            partnerCaption: partnerLamp.caption
        )
    }

    func startLiveActivityDemo() {
        guard isPaired else { return }
        refreshLiveActivity(forceStart: true)
    }

    func endLiveActivityDemo() {
        LiveActivityManager.shared.endImmediately()
    }

    func tapPartnerLamp() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        flashPartner = true
        showToast("已发送短叩")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.flashPartner = false }

        guard isPaired, !usePrototypeOverrides else { return }
        Task {
            do {
                try await pairSync.sendKnock(short: true)
                appendSignalEntry(pattern: "· · ·")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    func longPressPartnerLamp() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        flashPartner = true
        showToast("已发送长叩")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { self.flashPartner = false }

        guard isPaired, !usePrototypeOverrides else { return }
        Task {
            do {
                try await pairSync.sendKnock(short: false)
                appendSignalEntry(pattern: "· — ·")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    func tapSelfLamp() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        flashSelf = true
        withAnimation(.easeInOut(duration: 0.3)) {
            selfLamp.breathPeriod = 1.2
        }
        showToast("心跳")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.flashSelf = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.selfLamp.breathPeriod = 3.0 }
        }

        guard isPaired, !usePrototypeOverrides else { return }
        Task { await pushLocalPresence() }
    }

    func extinguishSelfLamp() {
        withAnimation(.easeOut(duration: 1.5)) {
            selfLamp.isOnline = false
        }
        showToast("灯已熄灭")
        refreshLiveActivity()

        guard isPaired, !usePrototypeOverrides else { return }
        Task { await pushLocalPresence() }
    }

    private func resumeCloudSync() {
        pairSync.startPolling { [weak self] snapshot in
            self?.applySnapshot(snapshot, notifyKnock: true)
        }
    }

    private func startWaitingForPartner() {
        pairSync.startPolling { [weak self] snapshot in
            guard let self else { return }
            self.inviteCode = snapshot.inviteCode
            if snapshot.partnerJoined {
                self.applySnapshot(snapshot, notifyKnock: false)
                Task { await self.pushLocalPresence() }
            }
        }
    }

    private func applySnapshot(_ snapshot: PairSessionSnapshot, notifyKnock: Bool) {
        guard !usePrototypeOverrides else { return }
        guard snapshot.partnerJoined || pairSync.savedRole == .guest else { return }

        partnerLamp.isOnline = snapshot.partnerOnline
        partnerLamp.caption = snapshot.partnerCaption
        partnerLamp.moodLabel = snapshot.partnerMood

        screen = deriveScreen(
            selfOnline: selfLamp.isOnline,
            partnerOnline: snapshot.partnerOnline
        )

        if selfLamp.isOnline && snapshot.partnerOnline, let since = snapshot.coPresenceSince {
            coTimeMinutes = max(0, Int(Date().timeIntervalSince(since) / 60))
        } else if screen != .coPresence {
            coTimeMinutes = 0
        }

        if screen == .coPresence {
            lastAppliedCoPresenceMinutes = coTimeMinutes
        } else if lastAppliedCoPresenceMinutes > 0 {
            lastCoPresenceLabel = "上次同在  刚刚  ·  \(lastAppliedCoPresenceMinutes)m"
            lastAppliedCoPresenceMinutes = 0
        }

        if notifyKnock {
            handleIncomingKnock(from: snapshot)
        }

        refreshLiveActivity()
    }

    private func deriveScreen(selfOnline: Bool, partnerOnline: Bool) -> AppScreen {
        switch (selfOnline, partnerOnline) {
        case (true, true): return .coPresence
        case (true, false): return .soloOnline
        case (false, true): return .partnerOnly
        case (false, false): return .idle
        }
    }

    private func handleIncomingKnock(from snapshot: PairSessionSnapshot) {
        let lastSeen = pairSync.lastSeenKnockSerial()
        guard snapshot.knockSerial > lastSeen, !snapshot.knockFromSelf else { return }

        pairSync.markKnockSeen(snapshot.knockSerial)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        partnerLamp.hasUnreadHalo = true

        let pattern = snapshot.knockPattern == "long" ? "· — ·" : "· · ·"
        appendSignalEntry(pattern: pattern, incoming: true)
        showToast("收到叩击")
    }

    private func pushLocalPresence() async {
        do {
            try await pairSync.pushPresence(
                selfOnline: selfLamp.isOnline,
                caption: selfLamp.caption,
                mood: selfLamp.moodLabel,
                partnerOnline: partnerLamp.isOnline
            )
        } catch {
            showToast(error.localizedDescription)
        }
    }

    private func appendSignalEntry(pattern: String, incoming: Bool = false) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let entry = SignalEntry(
            time: incoming ? "刚刚" : formatter.string(from: Date()),
            pattern: pattern,
            dictionaryLabel: nil
        )
        syncedSignalEntries.insert(entry, at: 0)
        if syncedSignalEntries.count > 30 {
            syncedSignalEntries = Array(syncedSignalEntries.prefix(30))
        }
    }

    private func showToast(_ message: String) {
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if self.toast == message { self.toast = nil }
        }
    }
}

enum RecordsTab: String, CaseIterable {
    case coTime = "共时"
    case signal = "信号"
}
