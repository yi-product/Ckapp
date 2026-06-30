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

            Text("Acue")
                .acueHandTitle()
                .padding(.bottom, 8)

            Text("invite someone in")
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .foregroundStyle(AcueTheme.textTertiary)
                .padding(.bottom, 40)

            SymbolEndpointView(
                state: LampState(isOnline: true, caption: "", moodLabel: ""),
                size: 64
            )

            Spacer().frame(height: 48)

            VStack(spacing: 20) {
                Text("邀请 ta 加入")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundStyle(AcueTheme.textSecondary)

                if store.isPairingBusy {
                    ProgressView()
                        .tint(AcueTheme.ink)
                } else if store.inviteCode.isEmpty {
                    Text("正在生成邀请码…")
                        .font(.system(size: 14, weight: .light, design: .monospaced))
                        .foregroundStyle(AcueTheme.textTertiary)
                } else {
                    Text(store.inviteCode)
                        .font(.system(size: 26, weight: .light, design: .monospaced))
                        .foregroundStyle(AcueTheme.textPrimary)
                        .kerning(6)
                }

                if !store.iCloudReady {
                    Text("请在本机登录 iCloud，以便跨网络配对")
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundStyle(AcueTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    showToastCopy()
                } label: {
                    Label("复制邀请码", systemImage: "doc.on.doc")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                }
                .buttonStyle(.bordered)
                .tint(AcueTheme.ink)
                .disabled(store.inviteCode.isEmpty)

                HStack {
                    Rectangle().fill(AcueTheme.pencil.opacity(0.4)).frame(height: 0.5)
                    Text("或")
                        .acueCaption()
                    Rectangle().fill(AcueTheme.pencil.opacity(0.4)).frame(height: 0.5)
                }
                .padding(.vertical, 8)

                TextField("输入对方的码", text: $inputCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundStyle(AcueTheme.ink)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AcueTheme.paperShadow.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AcueTheme.ink.opacity(0.08), lineWidth: 1)
                            )
                    }

                Button(store.isPairingBusy ? "连接中…" : "连接") {
                    Task { await store.joinPair(with: inputCode) }
                }
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AcueTheme.ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(AcueTheme.paper)
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
