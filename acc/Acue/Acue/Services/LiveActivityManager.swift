//
//  LiveActivityManager.swift
//  Acue
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activity: Activity<AcueActivityAttributes>?

    var isRunning: Bool { activity != nil }

    private init() {}

    func sync(
        partnerOnline: Bool,
        selfOnline: Bool,
        coTimeMinutes: Int,
        partnerCaption: String = ""
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let state = AcueActivityAttributes.ContentState(
            partnerOnline: partnerOnline,
            selfOnline: selfOnline,
            coTimeMinutes: coTimeMinutes,
            partnerCaption: partnerCaption
        )
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity {
            Task {
                await activity.update(content)
            }
        } else {
            let attributes = AcueActivityAttributes(pairName: "Acue")
            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                print("Live Activity start failed: \(error.localizedDescription)")
            }
        }
    }

    func endImmediately() {
        guard let activity else { return }
        Task {
            let finalState = activity.content.state
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.activity = nil
        }
    }
}
