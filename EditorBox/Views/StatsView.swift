//
//  StatsView.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI

struct StatsView: View {
    @Environment(GameStore.self) private var gameStore

    var body: some View {
        NavigationStack {
            List {
                if gameStore.isSubscriber {
                    statRow(title: "レベル", value: "Lv \(gameStore.level)")
                    statRow(title: "現在XP", value: "\(gameStore.xp)")
                    statRow(title: "コイン", value: "\(gameStore.coins)")
                    statRow(title: "連続日数", value: "\(gameStore.streakDays)日")
                    statRow(title: "総保存回数", value: "\(gameStore.totalSaves)")
                    statRow(title: "総文字数", value: "\(gameStore.totalChars)")
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("詳細統計はPremium限定です")
                                .font(.headline)
                            Text("サブスク登録で、保存回数・文字数・成長推移を確認できます。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StatsView()
        .environment(GameStore())
}
