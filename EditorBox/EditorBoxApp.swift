//
//  EditorBoxApp.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import SwiftUI
import SwiftData

@main
struct EditorBoxApp: App {
    @State private var gameStore = GameStore()

    /// アプリ全体で共有する SwiftData コンテナ
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([Idea.self, IdeaAttachment.self, PlayerProgress.self, OwnedItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
        }
        .modelContainer(sharedModelContainer)
    }
}
