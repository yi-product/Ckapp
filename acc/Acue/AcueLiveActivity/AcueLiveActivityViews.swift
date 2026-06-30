//
//  AcueLiveActivityViews.swift
//  AcueLiveActivity
//

import SwiftUI
import WidgetKit

enum LiveActivityColors {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let ink = Color(red: 0.12, green: 0.28, blue: 0.55)
    static let pencil = Color(red: 0.72, green: 0.70, blue: 0.66)
}

struct SymbolGlyph: View {
    let isOn: Bool
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            if isOn {
                Circle()
                    .stroke(LiveActivityColors.ink, lineWidth: 1.8)
                    .frame(width: size, height: size)
                Circle()
                    .fill(LiveActivityColors.ink)
                    .frame(width: size * 0.14, height: size * 0.14)
            } else {
                Circle()
                    .stroke(
                        LiveActivityColors.pencil.opacity(0.6),
                        style: StrokeStyle(lineWidth: 1.2, dash: [3, 4])
                    )
                    .frame(width: size * 0.82, height: size * 0.82)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PartnerPresenceDot: View {
    let isOn: Bool
    var size: CGFloat = 10

    var body: some View {
        SymbolGlyph(isOn: isOn, size: size + 8)
    }
}

struct AcueLockScreenView: View {
    let context: ActivityViewContext<AcueActivityAttributes>

    private var connection: String? {
        guard context.state.selfOnline, context.state.partnerOnline else { return nil }
        if context.state.coTimeMinutes >= 30 { return "—" }
        if context.state.coTimeMinutes >= 10 { return "_" }
        return "·"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                SymbolGlyph(isOn: context.state.selfOnline)
                Text(connection ?? " ")
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundStyle(LiveActivityColors.ink.opacity(connection == nil ? 0 : 0.65))
                    .frame(width: 14)
                SymbolGlyph(isOn: context.state.partnerOnline)
            }

            if context.state.selfOnline && context.state.partnerOnline {
                Text("共时 \(context.state.coTimeMinutes) 分钟")
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(LiveActivityColors.ink.opacity(0.5))
            } else {
                Text(context.state.partnerOnline ? "对方在" : "留空位")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundStyle(LiveActivityColors.ink.opacity(0.42))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .activityBackgroundTint(LiveActivityColors.paper.opacity(0.95))
    }
}
