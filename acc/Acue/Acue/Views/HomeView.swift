//
//  HomeView.swift
//  Acue
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var store: PrototypeStore

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                Text("Acue")
                    .acueHandTitle()
                    .padding(.bottom, 36)

                ZStack {
                    PresenceCanvasView(
                        selfState: store.selfLamp,
                        partnerState: store.partnerLamp,
                        flashSelf: store.flashSelf,
                        flashPartner: store.flashPartner,
                        coTimeMinutes: store.coTimeMinutes
                    )

                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { store.tapSelfLamp() }
                            .onLongPressGesture(minimumDuration: 1.8) {
                                store.extinguishSelfLamp()
                            }

                        Color.clear.frame(width: 52)

                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { store.tapPartnerLamp() }
                            .onLongPressGesture(minimumDuration: 0.55) {
                                store.longPressPartnerLamp()
                            }
                    }
                    .frame(width: 220, height: 120)
                }

                Spacer().frame(height: 40)

                if let metric = store.bottomMetric {
                    Text(metric)
                        .acueMetric()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer().frame(height: 28)

                Button {
                    store.showRecords = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 20, weight: .ultraLight))
                        Text("共时 / 信号")
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                    }
                    .foregroundStyle(AcueTheme.textTertiary)
                }
                .buttonStyle(.plain)

                Spacer()
                Spacer().frame(height: 24)
            }

            if let toast = store.toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(AcueTheme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AcueTheme.paperShadow.opacity(0.35), in: Capsule())
                        .overlay(Capsule().stroke(AcueTheme.ink.opacity(0.12), lineWidth: 1))
                        .padding(.bottom, 48)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.25), value: store.toast)
            }
        }
    }
}
