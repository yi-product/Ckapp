//
//  AcueLiveActivityWidget.swift
//  AcueLiveActivity
//

import ActivityKit
import SwiftUI
import WidgetKit

struct AcueLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AcueActivityAttributes.self) { context in
            AcueLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(spacing: 4) {
                        LampGlyph(isOn: context.state.selfOnline, size: 24)
                        Text("你")
                            .font(.system(size: 10, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 4) {
                        LampGlyph(isOn: context.state.partnerOnline, size: 24)
                        Text("Ta")
                            .font(.system(size: 10, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.selfOnline && context.state.partnerOnline {
                        Text("共时 \(context.state.coTimeMinutes) 分钟")
                            .font(.system(size: 13, weight: .ultraLight, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        Text(context.state.partnerOnline ? "对方在线" : "对方离开")
                            .font(.system(size: 12, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            } compactLeading: {
                Color.clear.frame(width: 0, height: 0)
            } compactTrailing: {
                PartnerPresenceDot(isOn: context.state.partnerOnline, size: 9)
            } minimal: {
                PartnerPresenceDot(isOn: context.state.partnerOnline, size: 8)
            }
        }
    }
}
