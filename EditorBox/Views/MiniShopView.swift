//
//  MiniShopView.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI

struct MiniShopView: View {
    @Environment(GameStore.self) private var gameStore
    @State private var message: String?

    private let themePrice = 30

    var body: some View {
        NavigationStack {
            List {
                Section("テーマ") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sunset Theme")
                                .fontWeight(.semibold)
                            Text("暖色系の限定テーマ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            unlockTheme()
                        } label: {
                            Text("\(themePrice) Coin")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let message {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("ショップ")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func unlockTheme() {
        if gameStore.spendCoins(themePrice) {
            message = "テーマを解放しました。"
        } else {
            message = "コイン不足です。"
        }
    }
}

#Preview {
    MiniShopView()
        .environment(GameStore())
}
