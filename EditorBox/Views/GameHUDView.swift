//
//  GameHUDView.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI

struct GameHUDView: View {
    @Environment(ThemeStore.self) private var themeStore

    let level: Int
    let coins: Int
    let characterSymbolName: String
    let showsLevelUpBanner: Bool

    private var theme: AppThemePalette {
        themeStore.currentTheme
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if showsLevelUpBanner {
                Text("LEVEL UP")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.positive.opacity(0.92), in: Capsule())
                    .foregroundStyle(.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 8) {
                Image(systemName: characterSymbolName)
                    .font(.headline)
                    .foregroundStyle(theme.accent)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Lv \(level)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.primaryText)

                    Text("\(coins) Coin")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(theme.cardBackground, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.primaryText.opacity(0.15), lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.25), value: showsLevelUpBanner)
    }
}

#Preview {
    GameHUDView(
        level: 4,
        coins: 132,
        characterSymbolName: "person.crop.circle.badge.plus",
        showsLevelUpBanner: true
    )
    .environment(ThemeStore())
}
