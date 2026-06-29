//
//  ContentView.swift
//  Acue
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = PrototypeStore()

    var body: some View {
        ZStack {
            AcueTheme.background.ignoresSafeArea()

            Group {
                switch store.screen {
                case .unpaired:
                    PairingView(store: store)
                default:
                    HomeView(store: store)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            PrototypeMenu(store: store)
                .padding(.trailing, 8)
                .padding(.top, 4)
        }
        .sheet(isPresented: $store.showRecords) {
            RecordsSheet(store: store)
        }
        .preferredColorScheme(.dark)
        .task {
            await store.bootstrap()
        }
        .onChange(of: scenePhase) { phase in
            store.handleScenePhase(phase)
        }
        .onChange(of: store.selfLamp.isOnline) { _ in
            store.refreshLiveActivity()
        }
        .onChange(of: store.partnerLamp.isOnline) { _ in
            store.refreshLiveActivity()
        }
        .onChange(of: store.coTimeMinutes) { _ in
            store.refreshLiveActivity()
        }
    }
}

#Preview {
    ContentView()
}
