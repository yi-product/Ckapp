//
//  PairSession.swift
//  Acue
//

import CloudKit
import Foundation

enum PairRole: String, Codable {
    case host
    case guest
}

enum PairSyncError: LocalizedError {
    case iCloudUnavailable
    case inviteNotFound
    case inviteAlreadyUsed
    case notPaired
    case cloudError(String)

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "请登录 iCloud；跨网络配对还需付费开发者账号（非 Personal Team）"
        case .inviteNotFound:
            return "邀请码不存在或已失效"
        case .inviteAlreadyUsed:
            return "该邀请码已被使用"
        case .notPaired:
            return "尚未配对"
        case .cloudError(let message):
            return message
        }
    }
}

struct PairSessionSnapshot {
    let recordID: CKRecord.ID
    let inviteCode: String
    let role: PairRole
    let partnerJoined: Bool
    let selfOnline: Bool
    let partnerOnline: Bool
    let selfCaption: String
    let partnerCaption: String
    let selfMood: String
    let partnerMood: String
    let coPresenceSince: Date?
    let knockSerial: Int64
    let knockPattern: String
    let knockFromSelf: Bool

    var coTimeMinutes: Int {
        guard let coPresenceSince, selfOnline, partnerOnline else { return 0 }
        return max(0, Int(Date().timeIntervalSince(coPresenceSince) / 60))
    }

    var derivedScreen: AppScreen {
        guard partnerJoined else { return .unpaired }
        switch (selfOnline, partnerOnline) {
        case (true, true): return .coPresence
        case (true, false): return .soloOnline
        case (false, true): return .partnerOnly
        case (false, false): return .idle
        }
    }
}

enum PairRecordKey {
    static let recordType = "PairSession"
    static let inviteCode = "inviteCode"
    static let hostDeviceID = "hostDeviceID"
    static let guestDeviceID = "guestDeviceID"
    static let hostOnline = "hostOnline"
    static let guestOnline = "guestOnline"
    static let hostCaption = "hostCaption"
    static let guestCaption = "guestCaption"
    static let hostMood = "hostMood"
    static let guestMood = "guestMood"
    static let coPresenceSince = "coPresenceSince"
    static let knockSerial = "knockSerial"
    static let knockPattern = "knockPattern"
    static let knockFromHost = "knockFromHost"
}

extension PairSessionSnapshot {
    init(record: CKRecord, role: PairRole, deviceID: String) {
        let hostOnline = (record[PairRecordKey.hostOnline] as? Int64 ?? 0) == 1
        let guestOnline = (record[PairRecordKey.guestOnline] as? Int64 ?? 0) == 1
        let hostCaption = record[PairRecordKey.hostCaption] as? String ?? ""
        let guestCaption = record[PairRecordKey.guestCaption] as? String ?? ""
        let hostMood = record[PairRecordKey.hostMood] as? String ?? ""
        let guestMood = record[PairRecordKey.guestMood] as? String ?? ""
        let guestDeviceID = record[PairRecordKey.guestDeviceID] as? String ?? ""
        let knockSerial = record[PairRecordKey.knockSerial] as? Int64 ?? 0
        let knockPattern = record[PairRecordKey.knockPattern] as? String ?? ""
        let knockFromHost = (record[PairRecordKey.knockFromHost] as? Int64 ?? 0) == 1
        let inviteCode = record[PairRecordKey.inviteCode] as? String ?? ""

        let partnerJoined = !guestDeviceID.isEmpty
        let isHost = role == .host

        self.init(
            recordID: record.recordID,
            inviteCode: inviteCode,
            role: role,
            partnerJoined: partnerJoined,
            selfOnline: isHost ? hostOnline : guestOnline,
            partnerOnline: isHost ? guestOnline : hostOnline,
            selfCaption: isHost ? hostCaption : guestCaption,
            partnerCaption: isHost ? guestCaption : hostCaption,
            selfMood: isHost ? hostMood : guestMood,
            partnerMood: isHost ? guestMood : hostMood,
            coPresenceSince: record[PairRecordKey.coPresenceSince] as? Date,
            knockSerial: knockSerial,
            knockPattern: knockPattern,
            knockFromSelf: isHost ? knockFromHost : !knockFromHost
        )
    }
}
