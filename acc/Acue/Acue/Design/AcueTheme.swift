//
//  AcueTheme.swift
//  Acue
//

import SwiftUI

enum AcueTheme {
    // Paper + ink (§15.1)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let paperShadow = Color(red: 0.92, green: 0.88, blue: 0.80)

    static let ink = Color(red: 0.12, green: 0.28, blue: 0.55)
    static let inkFaded = ink.opacity(0.35)
    static let pencil = Color(red: 0.72, green: 0.70, blue: 0.66)

    static let accent = ink
    static let background = paper

    static let textPrimary = ink
    static let textSecondary = ink.opacity(0.55)
    static let textTertiary = pencil.opacity(0.85)

    static let symbolSize: CGFloat = 52
    static let symbolStroke: CGFloat = 2.2
    static let symbolGap: CGFloat = 28

    static func moodTint(warmth: Double) -> Color {
        if warmth > 0.65 {
            return Color(red: 0.85, green: 0.45, blue: 0.38).opacity(0.55)
        }
        if warmth < 0.35 {
            return Color(red: 0.35, green: 0.52, blue: 0.72).opacity(0.45)
        }
        return .clear
    }

    static func connectionGlyph(selfOnline: Bool, partnerOnline: Bool, coTimeMinutes: Int) -> String? {
        guard selfOnline && partnerOnline else { return nil }
        if coTimeMinutes >= 30 { return "—" }
        if coTimeMinutes >= 10 { return "_" }
        return "·"
    }
}

struct PaperBackground: View {
    var body: some View {
        ZStack {
            AcueTheme.paper
            LinearGradient(
                colors: [
                    AcueTheme.paperShadow.opacity(0.15),
                    .clear,
                    AcueTheme.paperShadow.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct AcueCaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .light, design: .monospaced))
            .foregroundStyle(AcueTheme.textSecondary)
            .multilineTextAlignment(.center)
    }
}

struct AcueMetricStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .light, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(AcueTheme.textSecondary)
    }
}

struct AcueHandTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 34, weight: .thin, design: .rounded))
            .foregroundStyle(AcueTheme.ink)
    }
}

extension View {
    func acueCaption() -> some View { modifier(AcueCaptionStyle()) }
    func acueMetric() -> some View { modifier(AcueMetricStyle()) }
    func acueHandTitle() -> some View { modifier(AcueHandTitleStyle()) }
}
