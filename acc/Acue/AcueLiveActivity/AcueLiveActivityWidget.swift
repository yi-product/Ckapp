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
                        SymbolGlyph(isOn: context.state.selfOnline, size: 20)
                        Text("你")
                            .font(.system(size: 9, weight: .light, design: .monospaced))
                            .foregroundStyle(LiveActivityColors.ink.opacity(0.5))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 4) {
                        SymbolGlyph(isOn: context.state.partnerOnline, size: 20)
                        Text("Ta")
                            .font(.system(size: 9, weight: .light, design: .monospaced))
                            .foregroundStyle(LiveActivityColors.ink.opacity(0.5))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.selfOnline && context.state.partnerOnline {
                        Text("共时 \(context.state.coTimeMinutes) 分钟")
                            .font(.system(size: 12, weight: .light, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(LiveActivityColors.ink.opacity(0.55))
                    } else {
                        Text(context.state.partnerOnline ? "对方在" : "留空位")
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                            .foregroundStyle(LiveActivityColors.ink.opacity(0.45))
                    }
                }
            } compactLeading: {
                Color.clear.frame(width: 0, height: 0)
            } compactTrailing: {
                PartnerPresenceDot(isOn: context.state.partnerOnline, size: 6)
            } minimal: {
                PartnerPresenceDot(isOn: context.state.partnerOnline, size: 5)
            }
        }
    }
}
