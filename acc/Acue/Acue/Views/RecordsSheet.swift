//
//  RecordsSheet.swift
//  Acue
//

import SwiftUI

struct RecordsSheet: View {
    @ObservedObject var store: PrototypeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("记录", selection: $store.recordsTab) {
                    ForEach(RecordsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)

                List {
                    if store.recordsTab == .coTime {
                        Section {
                            HStack {
                                Text("本周")
                                    .font(.system(size: 14, weight: .light, design: .monospaced))
                                    .foregroundStyle(AcueTheme.textSecondary)
                                Spacer()
                                Text("3h 12m")
                                    .acueMetric()
                            }
                        }

                        Section {
                            ForEach(store.coTimeEntries) { entry in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(entry.label)
                                        .font(.system(size: 14, weight: .light, design: .monospaced))
                                        .foregroundStyle(AcueTheme.textSecondary)
                                    Spacer()
                                    Text(entry.duration)
                                        .acueMetric()
                                }
                                .listRowBackground(AcueTheme.paperShadow.opacity(0.2))
                            }
                        }
                    } else {
                        Section {
                            ForEach(store.signalEntries) { entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(entry.time)
                                            .font(.system(size: 13, weight: .light, design: .monospaced))
                                            .foregroundStyle(AcueTheme.textTertiary)
                                        Spacer()
                                        Text(entry.pattern)
                                            .font(.system(size: 15, weight: .light, design: .monospaced))
                                            .foregroundStyle(AcueTheme.textSecondary)
                                    }
                                    if let label = entry.dictionaryLabel {
                                        Text(label)
                                            .font(.system(size: 14, weight: .light))
                                            .foregroundStyle(AcueTheme.textPrimary.opacity(0.7))
                                    }
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(AcueTheme.paperShadow.opacity(0.2))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .background(PaperBackground())
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(AcueTheme.ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AcueTheme.paper)
    }
}
