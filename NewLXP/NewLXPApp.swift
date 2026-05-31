//
//  NewLXPApp.swift
//  NewLXP
//
//  Created by keet on 25.11.2025.
//

import SwiftUI

@main
struct NewLXPApp: App {
    @State private var store = AppStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task { await store.bootstrap() }
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.isAuthenticated {
                ContentView()
            } else {
                LoginView(store: store)
            }
        }
        .animation(.snappy, value: store.isAuthenticated)
    }
}
