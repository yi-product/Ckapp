//
//  SymbolViews.swift
//  Acue
//

import SwiftUI

struct SymbolEndpointView: View {
    let state: LampState
    var flash: Bool = false
    var placeholder: Bool = false
    var size: CGFloat = AcueTheme.symbolSize

    @State private var breathing = false

    var body: some View {
        ZStack {
            if placeholder || !state.isOnline {
                Circle()
                    .stroke(
                        AcueTheme.pencil.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 5])
                    )
                    .frame(width: size * 0.82, height: size * 0.82)
            } else {
                Circle()
                    .stroke(AcueTheme.ink.opacity(inkOpacity), lineWidth: AcueTheme.symbolStroke)
                    .background {
                        Circle()
                            .fill(AcueTheme.moodTint(warmth: state.warmth))
                            .padding(4)
                    }
                    .frame(width: size, height: size)
                    .scaleEffect(breathing ? 1.03 : 0.97)
                    .opacity(flash ? 1 : (breathing ? 0.95 : 0.82))

                Circle()
                    .fill(AcueTheme.ink.opacity(flash ? 1 : 0.9))
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(y: -size * 0.02)
            }

            if state.hasUnreadHalo, state.isOnline {
                Circle()
                    .stroke(AcueTheme.ink.opacity(0.2), lineWidth: 1)
                    .frame(width: size + 14, height: size + 14)
                    .scaleEffect(breathing ? 1.05 : 0.95)
            }
        }
        .frame(width: size + 16, height: size + 16)
        .animation(.easeInOut(duration: flash ? 0.12 : state.breathPeriod).repeatCount(flash ? 1 : .max, autoreverses: true), value: flash)
        .onAppear { breathing = state.isOnline && !placeholder }
        .onChange(of: state.isOnline) { online in
            breathing = online && !placeholder
        }
    }

    private var inkOpacity: Double {
        let base = state.brightness * (state.shaded ? 0.5 : 1)
        return max(0.35, min(1, base))
    }
}

struct ConnectionGlyphView: View {
    let glyph: String?

    var body: some View {
        Text(glyph ?? " ")
            .font(.system(size: 22, weight: .light, design: .monospaced))
            .foregroundStyle(AcueTheme.ink.opacity(glyph == nil ? 0 : 0.75))
            .frame(width: 24)
            .accessibilityHidden(glyph == nil)
    }
}

struct PresenceCanvasView: View {
    let selfState: LampState
    let partnerState: LampState
    var flashSelf: Bool = false
    var flashPartner: Bool = false
    var coTimeMinutes: Int = 0
    var showLabels: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: AcueTheme.symbolGap) {
                SymbolEndpointView(
                    state: selfState,
                    flash: flashSelf,
                    placeholder: false
                )

                ConnectionGlyphView(
                    glyph: AcueTheme.connectionGlyph(
                        selfOnline: selfState.isOnline,
                        partnerOnline: partnerState.isOnline,
                        coTimeMinutes: coTimeMinutes
                    )
                )

                SymbolEndpointView(
                    state: partnerState,
                    flash: flashPartner,
                    placeholder: !partnerState.isOnline
                )
            }

            if showLabels {
                HStack(spacing: AcueTheme.symbolGap + 24) {
                    captionColumn(for: selfState, isSelf: true)
                    Spacer().frame(width: 24)
                    captionColumn(for: partnerState, isSelf: false)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    @ViewBuilder
    private func captionColumn(for state: LampState, isSelf: Bool) -> some View {
        VStack(spacing: 4) {
            if !state.moodLabel.isEmpty, state.isOnline {
                Text("「\(state.moodLabel)」")
                    .acueCaption()
            }
            if !state.caption.isEmpty {
                Text("「\(state.caption)」")
                    .acueCaption()
                    .opacity(state.isOnline ? 1 : 0.45)
            } else if !state.isOnline, !isSelf {
                Text("last together.")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundStyle(AcueTheme.textTertiary)
            }
        }
        .frame(width: 100)
        .frame(minHeight: 32)
    }
}
