//
//  DailyRewardSheetView.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI

struct DailyRewardSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var gameStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.yellow)

                VStack(spacing: 8) {
                    Text("デイリーボーナス")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("今日は \(gameStore.dailyRewardAmount) コイン受け取れます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    gameStore.claimDailyReward()
                    dismiss()
                } label: {
                    Text("受け取る")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("あとで") {
                    gameStore.dismissDailyRewardSheet()
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .navigationTitle("ボーナス")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DailyRewardSheetView()
        .environment(GameStore())
}
