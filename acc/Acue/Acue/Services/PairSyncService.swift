//
//  PairSyncService.swift
//  Acue
//

import CloudKit
import Foundation

@MainActor
final class PairSyncService {
    static let shared = PairSyncService()

    private let container = CKContainer(identifier: "iCloud.com.ccKu.Acue")
    private let defaults = UserDefaults.standard

    private let deviceIDKey = "acue.deviceID"
    private let pairRecordNameKey = "acue.pairRecordName"
    private let pairRoleKey = "acue.pairRole"
    private let inviteCodeKey = "acue.inviteCode"
    private let lastKnockSerialKey = "acue.lastKnockSerial"

    private var pollTask: Task<Void, Never>?

    private init() {}

    var deviceID: String {
        if let existing = defaults.string(forKey: deviceIDKey) {
            return existing
        }
        let created = UUID().uuidString
        defaults.set(created, forKey: deviceIDKey)
        return created
    }

    var isPairedLocally: Bool {
        defaults.string(forKey: pairRecordNameKey) != nil
    }

    var savedInviteCode: String? {
        defaults.string(forKey: inviteCodeKey)
    }

    var savedRole: PairRole? {
        guard let raw = defaults.string(forKey: pairRoleKey) else { return nil }
        return PairRole(rawValue: raw)
    }

    func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }

    func prepareHostInvite() async throws -> String {
        guard await checkAccountStatus() else { throw PairSyncError.iCloudUnavailable }

        if let code = savedInviteCode,
           let recordName = defaults.string(forKey: pairRecordNameKey),
           savedRole == .host {
            return code
        }

        let code = Self.generateInviteCode()
        let record = CKRecord(recordType: PairRecordKey.recordType)
        record[PairRecordKey.inviteCode] = code as CKRecordValue
        record[PairRecordKey.hostDeviceID] = deviceID as CKRecordValue
        record[PairRecordKey.hostOnline] = 1 as CKRecordValue
        record[PairRecordKey.guestOnline] = 0 as CKRecordValue
        record[PairRecordKey.hostCaption] = "" as CKRecordValue
        record[PairRecordKey.guestCaption] = "" as CKRecordValue
        record[PairRecordKey.hostMood] = "" as CKRecordValue
        record[PairRecordKey.guestMood] = "" as CKRecordValue
        record[PairRecordKey.knockSerial] = 0 as CKRecordValue
        record[PairRecordKey.knockPattern] = "" as CKRecordValue
        record[PairRecordKey.knockFromHost] = 0 as CKRecordValue

        let saved = try await save(record: record)
        persistPair(record: saved, role: .host, inviteCode: code)
        return code
    }

    func join(with code: String) async throws {
        guard await checkAccountStatus() else { throw PairSyncError.iCloudUnavailable }

        let normalized = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 4 else { throw PairSyncError.inviteNotFound }

        let predicate = NSPredicate(format: "%K == %@", PairRecordKey.inviteCode, normalized)
        let query = CKQuery(recordType: PairRecordKey.recordType, predicate: predicate)

        let (matchResults, _) = try await container.publicCloudDatabase.records(
            matching: query,
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: 1
        )

        guard let (_, result) = matchResults.first else {
            throw PairSyncError.inviteNotFound
        }

        let record = try result.get()

        if let guestID = record[PairRecordKey.guestDeviceID] as? String, !guestID.isEmpty {
            if guestID == deviceID {
                persistPair(record: record, role: .guest, inviteCode: normalized)
                return
            }
            throw PairSyncError.inviteAlreadyUsed
        }

        record[PairRecordKey.guestDeviceID] = deviceID as CKRecordValue
        record[PairRecordKey.guestOnline] = 1 as CKRecordValue

        let saved = try await save(record: record)
        persistPair(record: saved, role: .guest, inviteCode: normalized)
    }

    func fetchSnapshot() async throws -> PairSessionSnapshot {
        guard let recordID = localRecordID(), let role = savedRole else {
            throw PairSyncError.notPaired
        }

        let record = try await container.publicCloudDatabase.record(for: recordID)
        return PairSessionSnapshot(record: record, role: role, deviceID: deviceID)
    }

    func pushPresence(
        selfOnline: Bool,
        caption: String,
        mood: String,
        partnerOnline: Bool
    ) async throws {
        guard let recordID = localRecordID(), let role = savedRole else {
            throw PairSyncError.notPaired
        }

        let record = try await container.publicCloudDatabase.record(for: recordID)

        if role == .host {
            record[PairRecordKey.hostOnline] = (selfOnline ? 1 : 0) as CKRecordValue
            record[PairRecordKey.hostCaption] = caption as CKRecordValue
            record[PairRecordKey.hostMood] = mood as CKRecordValue
        } else {
            record[PairRecordKey.guestOnline] = (selfOnline ? 1 : 0) as CKRecordValue
            record[PairRecordKey.guestCaption] = caption as CKRecordValue
            record[PairRecordKey.guestMood] = mood as CKRecordValue
        }

        let bothOnline = selfOnline && partnerOnline
        if bothOnline {
            if record[PairRecordKey.coPresenceSince] == nil {
                record[PairRecordKey.coPresenceSince] = Date() as CKRecordValue
            }
        } else {
            record[PairRecordKey.coPresenceSince] = nil
        }

        _ = try await save(record: record)
    }

    func sendKnock(short: Bool) async throws {
        guard let recordID = localRecordID(), let role = savedRole else {
            throw PairSyncError.notPaired
        }

        let record = try await container.publicCloudDatabase.record(for: recordID)
        let nextSerial = (record[PairRecordKey.knockSerial] as? Int64 ?? 0) + 1
        record[PairRecordKey.knockSerial] = nextSerial as CKRecordValue
        record[PairRecordKey.knockPattern] = (short ? "short" : "long") as CKRecordValue
        record[PairRecordKey.knockFromHost] = (role == .host ? 1 : 0) as CKRecordValue
        _ = try await save(record: record)
    }

    func startPolling(every seconds: TimeInterval = 2, handler: @escaping (PairSessionSnapshot) -> Void) {
        stopPolling()
        pollTask = Task {
            while !Task.isCancelled {
                do {
                    let snapshot = try await fetchSnapshot()
                    handler(snapshot)
                } catch {
                    // Polling failures are non-fatal; next tick retries.
                }
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func unpair() {
        stopPolling()
        defaults.removeObject(forKey: pairRecordNameKey)
        defaults.removeObject(forKey: pairRoleKey)
        defaults.removeObject(forKey: inviteCodeKey)
        defaults.removeObject(forKey: lastKnockSerialKey)
    }

    func lastSeenKnockSerial() -> Int64 {
        Int64(defaults.integer(forKey: lastKnockSerialKey))
    }

    func markKnockSeen(_ serial: Int64) {
        defaults.set(Int(serial), forKey: lastKnockSerialKey)
    }

    private func localRecordID() -> CKRecord.ID? {
        guard let name = defaults.string(forKey: pairRecordNameKey) else { return nil }
        return CKRecord.ID(recordName: name)
    }

    private func persistPair(record: CKRecord, role: PairRole, inviteCode: String) {
        defaults.set(record.recordID.recordName, forKey: pairRecordNameKey)
        defaults.set(role.rawValue, forKey: pairRoleKey)
        defaults.set(inviteCode, forKey: inviteCodeKey)
    }

    private func save(record: CKRecord) async throws -> CKRecord {
        do {
            return try await container.publicCloudDatabase.save(record)
        } catch {
            throw PairSyncError.cloudError(error.localizedDescription)
        }
    }

    private static func generateInviteCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement()! })
    }
}
