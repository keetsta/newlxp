//
//  NewLXPApp.swift
//  NewLXP
//
//  Created by keet on 25.11.2025.
//

import SwiftUI

@main
struct NewLXPApp: App {
    @StateObject private var store = AppStore.shared
    @AppStorage("appearance") private var appearance: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(appearance.colorScheme)
                .task { await store.bootstrap() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if store.isAuthenticated {
                    ContentView()
                } else {
                    LoginView(store: store)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.isAuthenticated)

            // Транзиентный баннер для сетевых ошибок поверх контента.
            ErrorBanner()
                .allowsHitTesting(store.lastError != nil)
        }
    }
}
