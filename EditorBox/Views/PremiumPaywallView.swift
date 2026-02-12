//
//  PremiumPaywallView.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var gameStore

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(gameStore.paywallTitle.isEmpty ? "Premium" : gameStore.paywallTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(
                    gameStore.paywallMessage.isEmpty
                    ? "サブスクで成長効率を上げ、広告なしでメモに集中できます。"
                    : gameStore.paywallMessage
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("広告非表示", systemImage: "nosign")
                    Label("コイン獲得2倍", systemImage: "bitcoinsign.circle")
                    Label("限定テーマ", systemImage: "paintpalette")
                }
                .font(.subheadline)

                Button {
                    gameStore.dismissPaywall()
                    dismiss()
                } label: {
                    Text("サブスクを見る（Phase2）")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("閉じる") {
                    gameStore.dismissPaywall()
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    PremiumPaywallView()
        .environment(GameStore())
}
