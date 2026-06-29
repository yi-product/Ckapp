//
//  AcueLiveActivityViews.swift
//  AcueLiveActivity
//

import SwiftUI
import WidgetKit

enum LiveActivityColors {
    static let amber = Color(red: 1.0, green: 0.70, blue: 0.28)
    static let dim = Color.white.opacity(0.25)
}

struct PartnerPresenceDot: View {
    let isOn: Bool
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(isOn ? LiveActivityColors.amber : LiveActivityColors.dim)
            .frame(width: size, height: size)
            .shadow(color: isOn ? LiveActivityColors.amber.opacity(0.8) : .clear, radius: 4)
    }
}

struct LampGlyph: View {
    let isOn: Bool
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            if isOn {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [LiveActivityColors.amber, LiveActivityColors.amber.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 1,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size, height: size)
                    .blur(radius: 4)
            } else {
                Circle()
                    .stroke(LiveActivityColors.dim, lineWidth: 1)
                    .frame(width: size * 0.72, height: size * 0.72)
            }
        }
        .frame(width: size, height: size)
    }
}

struct AcueLockScreenView: View {
    let context: ActivityViewContext<AcueActivityAttributes>

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 6) {
                LampGlyph(isOn: context.state.selfOnline)
                Text("你")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.45))
            }

            if context.state.selfOnline && context.state.partnerOnline {
                Text("共时 \(context.state.coTimeMinutes) 分钟")
                    .font(.system(size: 14, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                Text(context.state.partnerOnline ? "对方在" : "对方离开")
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.45))
            }

            VStack(spacing: 6) {
                LampGlyph(isOn: context.state.partnerOnline)
                Text("Ta")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .activityBackgroundTint(.black.opacity(0.85))
    }
}
