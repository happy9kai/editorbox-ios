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
        .modelContainer(for: [Idea.self, IdeaAttachment.self, PlayerProgress.self, OwnedItem.self], inMemory: true)
}
