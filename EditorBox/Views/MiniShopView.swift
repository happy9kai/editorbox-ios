//
//  MiniShopView.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI
import SwiftData

struct MiniShopView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GameStore.self) private var gameStore
    @Environment(ThemeStore.self) private var themeStore

    @State private var message: String?
    @State private var isShowingStats = false
    @State private var hasConfiguredThemeStore = false

    private let themes: [AppThemeID] = [.default, .sunset, .premiumMidnight]

    private var theme: AppThemePalette {
        themeStore.currentTheme
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackgroundView(theme: theme)

                List {
                    Section("テーマ") {
                        ForEach(themes) { themeID in
                            themeRow(themeID)
                                .listRowBackground(theme.cardBackground)
                        }
                    }

                    Section("Premium") {
                        Button("詳細統計を見る") {
                            isShowingStats = true
                        }
                    }
                    .listRowBackground(theme.cardBackground)

                    if let message {
                        Section {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(theme.secondaryText)
                        }
                        .listRowBackground(theme.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("ショップ")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.accent)
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $isShowingStats) {
            StatsView()
        }
        .task {
            if !hasConfiguredThemeStore {
                hasConfiguredThemeStore = true
                themeStore.configure(modelContext: modelContext, isSubscriber: gameStore.isSubscriber)
            }
        }
    }

    @ViewBuilder
    private func themeRow(_ themeID: AppThemeID) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(themeID.displayName)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.primaryText)

                Text(themeSubtitle(themeID))
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()

            Button(themeButtonLabel(themeID)) {
                onTapTheme(themeID)
            }
            .buttonStyle(.borderedProminent)
            .disabled(themeStore.isEquipped(themeId: themeID.rawValue))
        }
        .padding(.vertical, 2)
    }

    private func themeSubtitle(_ themeID: AppThemeID) -> String {
        if themeStore.isEquipped(themeId: themeID.rawValue) {
            return "装備中"
        }

        if themeID.requiresSubscription && !gameStore.isSubscriber {
            return "Premium限定"
        }

        if themeStore.isOwned(themeId: themeID.rawValue) || themeID == .default {
            return "購入済み"
        }

        if let price = themeID.coinPrice {
            return "\(price) Coin"
        }

        return ""
    }

    private func themeButtonLabel(_ themeID: AppThemeID) -> String {
        if themeStore.isEquipped(themeId: themeID.rawValue) {
            return "装備中"
        }

        if themeID.requiresSubscription && !gameStore.isSubscriber {
            return "Premiumを見る"
        }

        if let price = themeID.coinPrice, !themeStore.isOwned(themeId: themeID.rawValue) {
            return "\(price) Coinで購入"
        }

        return "装備"
    }

    private func onTapTheme(_ themeID: AppThemeID) {
        if themeID.requiresSubscription && !gameStore.isSubscriber {
            gameStore.presentPremiumThemePaywall()
            message = "Premium登録で限定テーマを装備できます。"
            return
        }

        if let price = themeID.coinPrice, !themeStore.isOwned(themeId: themeID.rawValue) {
            let purchased = themeStore.purchaseTheme(themeId: themeID.rawValue, price: price, gameStore: gameStore)
            message = purchased ? "\(themeID.displayName) を購入して装備しました。" : "コイン不足です。"
            return
        }

        let applied = themeStore.apply(themeId: themeID.rawValue, isSubscriber: gameStore.isSubscriber)
        if applied {
            message = "\(themeID.displayName) を装備しました。"
        }
    }
}

#Preview {
    MiniShopView()
        .environment(GameStore())
        .environment(ThemeStore())
        .modelContainer(for: [PlayerProgress.self, OwnedItem.self], inMemory: true)
}
