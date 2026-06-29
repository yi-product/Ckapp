//
//  PairingView.swift
//  Acue
//

import SwiftUI

struct PairingView: View {
    @ObservedObject var store: PrototypeStore
    @State private var inputCode = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            GlowLampView(
                state: LampState(isOnline: true, caption: "", moodLabel: ""),
                isSelf: true
            )

            Spacer().frame(height: 48)

            VStack(spacing: 20) {
                Text("邀请 ta 加入")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(AcueTheme.textSecondary)

                if store.isPairingBusy {
                    ProgressView()
                        .tint(AcueTheme.amberCore)
                } else if store.inviteCode.isEmpty {
                    Text("正在生成邀请码…")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(AcueTheme.textTertiary)
                } else {
                    Text(store.inviteCode)
                        .font(.system(size: 28, weight: .ultraLight, design: .monospaced))
                        .foregroundStyle(AcueTheme.textPrimary)
                        .kerning(6)
                }

                if !store.iCloudReady {
                    Text("请在本机登录 iCloud，以便跨网络配对")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(AcueTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    showToastCopy()
                } label: {
                    Label("复制邀请码", systemImage: "doc.on.doc")
                        .font(.system(size: 15, weight: .regular))
                }
                .buttonStyle(.bordered)
                .tint(AcueTheme.amberCore)
                .disabled(store.inviteCode.isEmpty)

                HStack {
                    Rectangle().fill(AcueTheme.textTertiary).frame(height: 0.5)
                    Text("或")
                        .acueCaption()
                    Rectangle().fill(AcueTheme.textTertiary).frame(height: 0.5)
                }
                .padding(.vertical, 8)

                TextField("输入对方的码", text: $inputCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .font(.system(size: 17, weight: .light, design: .monospaced))
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    }

                Button(store.isPairingBusy ? "连接中…" : "连接") {
                    Task { await store.joinPair(with: inputCode) }
                }
                .font(.system(size: 17, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AcueTheme.amberCore.opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(Color.black.opacity(0.85))
                .disabled(inputCode.count < 4 || store.isPairingBusy)
                .opacity(inputCode.count < 4 || store.isPairingBusy ? 0.45 : 1)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .task {
            await store.prepareInviteIfNeeded()
        }
    }

    private func showToastCopy() {
        guard !store.inviteCode.isEmpty else { return }
        UIPasteboard.general.string = store.inviteCode
        store.toast = "已复制"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { store.toast = nil }
    }
}
