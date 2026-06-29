//
//  AcueActivityAttributes.swift
//  AcueLiveActivity
//
//  Keep in sync with Acue/Models/AcueActivityAttributes.swift
//

import ActivityKit
import Foundation

struct AcueActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var partnerOnline: Bool
        var selfOnline: Bool
        var coTimeMinutes: Int
        var partnerCaption: String
    }

    var pairName: String
}
