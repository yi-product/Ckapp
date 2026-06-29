//
//  AcueTheme.swift
//  Acue
//

import SwiftUI

enum AcueTheme {
    static let background = Color.black

    static let amberCore = Color(red: 1.0, green: 0.70, blue: 0.28)
    static let amberGlow = Color(red: 1.0, green: 0.55, blue: 0.0)

    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.40)
    static let textTertiary = Color.white.opacity(0.24)

    static let lampSize: CGFloat = 88
    static let lampGlowRadius: CGFloat = 36

    static func lampGradient(warmth: Double, brightness: Double, shaded: Bool) -> RadialGradient {
        let core = warmth > 0.6 ? amberCore : Color(red: 1.0, green: 0.78, blue: 0.45)
        let outer = warmth > 0.6 ? amberGlow : Color(red: 1.0, green: 0.65, blue: 0.15)
        let opacity = (shaded ? 0.35 : 1.0) * brightness

        return RadialGradient(
            colors: [
                core.opacity(opacity),
                outer.opacity(opacity * 0.55),
                Color.clear
            ],
            center: .center,
            startRadius: 2,
            endRadius: lampSize * 0.85
        )
    }
}

struct AcueCaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .ultraLight, design: .default))
            .foregroundStyle(AcueTheme.textSecondary)
            .multilineTextAlignment(.center)
    }
}

struct AcueMetricStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .ultraLight, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(AcueTheme.textSecondary)
    }
}

extension View {
    func acueCaption() -> some View { modifier(AcueCaptionStyle()) }
    func acueMetric() -> some View { modifier(AcueMetricStyle()) }
}
