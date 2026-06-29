//
//  GlowLampView.swift
//  Acue
//

import SwiftUI

struct GlowLampView: View {
    let state: LampState
    var flash: Bool = false
    var isSelf: Bool = false

    @State private var breathing = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                if state.hasUnreadHalo {
                    Circle()
                        .stroke(AcueTheme.amberCore.opacity(0.25), lineWidth: 1)
                        .frame(width: AcueTheme.lampSize + 22, height: AcueTheme.lampSize + 22)
                        .scaleEffect(breathing ? 1.04 : 0.96)
                        .opacity(breathing ? 0.7 : 0.35)
                        .animation(
                            .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                            value: breathing
                        )
                }

                if state.isOnline {
                    Circle()
                        .fill(AcueTheme.lampGradient(
                            warmth: state.warmth,
                            brightness: state.brightness,
                            shaded: state.shaded
                        ))
                        .frame(width: AcueTheme.lampSize, height: AcueTheme.lampSize)
                        .blur(radius: AcueTheme.lampGlowRadius * (state.shaded ? 0.6 : 1))
                        .scaleEffect(breathing ? 1.06 : 0.94)
                        .opacity(flash ? 1 : (breathing ? 0.95 : 0.75))
                        .animation(
                            .easeInOut(duration: state.breathPeriod).repeatForever(autoreverses: true),
                            value: breathing
                        )
                        .overlay {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(flash ? 0.35 : 0.12), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: AcueTheme.lampSize * 0.35
                                    )
                                )
                                .frame(width: AcueTheme.lampSize * 0.5, height: AcueTheme.lampSize * 0.5)
                        }
                } else {
                    Circle()
                        .stroke(AcueTheme.textTertiary, lineWidth: 1)
                        .frame(width: AcueTheme.lampSize * 0.72, height: AcueTheme.lampSize * 0.72)
                        .opacity(0.5)
                }
            }
            .frame(height: AcueTheme.lampSize + 28)

            VStack(spacing: 4) {
                if !state.moodLabel.isEmpty, state.isOnline {
                    Text("「\(state.moodLabel)」")
                        .acueCaption()
                }
                if !state.caption.isEmpty {
                    Text("「\(state.caption)」")
                        .acueCaption()
                        .opacity(state.isOnline ? 1 : 0.45)
                }
            }
            .frame(minHeight: 36)
        }
        .onAppear { breathing = state.isOnline }
        .onChange(of: state.isOnline) { online in
            breathing = online
        }
        .accessibilityLabel(isSelf ? "你的灯" : "对方的灯")
        .accessibilityValue(state.isOnline ? "在线" : "离线")
    }
}
