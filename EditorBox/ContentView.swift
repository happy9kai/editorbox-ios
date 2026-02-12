//
//  ContentView.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environment(GameStore())
        .environment(PurchaseService())
        .environment(ThemeStore())
        .modelContainer(for: [Idea.self, IdeaAttachment.self, PlayerProgress.self, OwnedItem.self], inMemory: true)
}
