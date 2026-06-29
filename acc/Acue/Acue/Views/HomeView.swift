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

                HStack(alignment: .top, spacing: 48) {
                    lampColumn(state: store.selfLamp, flash: store.flashSelf, isSelf: true) {
                        store.tapSelfLamp()
                    } onLongPress: {
                        store.extinguishSelfLamp()
                    }

                    lampColumn(state: store.partnerLamp, flash: store.flashPartner, isSelf: false) {
                        store.tapPartnerLamp()
                    } onLongPress: {
                        store.longPressPartnerLamp()
                    }
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
                            .font(.system(size: 22, weight: .ultraLight))
                        Text("共时 / 信号")
                            .font(.system(size: 12, weight: .ultraLight))
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
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 48)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.25), value: store.toast)
            }
        }
    }

    @ViewBuilder
    private func lampColumn(
        state: LampState,
        flash: Bool,
        isSelf: Bool,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) -> some View {
        GlowLampView(state: state, flash: flash, isSelf: isSelf)
            .contentShape(Circle().size(width: 120, height: 120))
            .onTapGesture(perform: onTap)
            .onLongPressGesture(minimumDuration: isSelf ? 1.8 : 0.55, perform: onLongPress)
    }
}
