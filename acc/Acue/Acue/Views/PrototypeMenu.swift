//
//  PrototypeMenu.swift
//  Acue — 原型调试：切换界面态
//

import SwiftUI

struct PrototypeMenu: View {
    @ObservedObject var store: PrototypeStore

    var body: some View {
        Menu {
            Section("配对") {
                Button("解除配对", role: .destructive) {
                    store.unpair()
                }
            }
            Section("Live Activity") {
                Button("启动灵动岛 / 锁屏") {
                    store.startLiveActivityDemo()
                }
                Button("结束 Live Activity") {
                    store.endLiveActivityDemo()
                }
            }
            Section("界面态（本地预览）") {
                Toggle("启用本地预览", isOn: $store.usePrototypeOverrides)
                if store.usePrototypeOverrides {
                    ForEach(AppScreen.allCases) { screen in
                        Button {
                            if screen == .unpaired {
                                store.applyScreen(.unpaired)
                            } else {
                                store.applyScreen(screen)
                            }
                        } label: {
                            if store.screen == screen {
                                Label(screen.title, systemImage: "checkmark")
                            } else {
                                Text(screen.title)
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(AcueTheme.textTertiary)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("原型状态切换")
    }
}
