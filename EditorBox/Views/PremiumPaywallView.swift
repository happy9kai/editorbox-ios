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
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(ThemeStore.self) private var themeStore

    @State private var actionMessage: String?

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
                    Label("詳細統計", systemImage: "chart.line.uptrend.xyaxis")
                }
                .font(.subheadline)

                HStack {
                    Text("月額")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(purchaseService.premiumPriceText)
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Button {
                    Task {
                        let success = await purchaseService.purchasePremium()
                        if success {
                            gameStore.setSubscriberStatus(true)
                            themeStore.refreshSubscriptionState(isSubscriber: true)
                            gameStore.dismissPaywall()
                            dismiss()
                        } else {
                            actionMessage = purchaseService.errorMessage ?? "購入は完了しませんでした。"
                        }
                    }
                } label: {
                    if purchaseService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("サブスク登録")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(purchaseService.isLoading)

                Button("購入を復元") {
                    Task {
                        let restored = await purchaseService.restorePurchases()
                        gameStore.setSubscriberStatus(restored)
                        themeStore.refreshSubscriptionState(isSubscriber: restored)
                        actionMessage = restored ? "購入を復元しました。" : "有効な購入は見つかりませんでした。"
                    }
                }
                .disabled(purchaseService.isLoading)

                if let actionMessage {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

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
        .task {
            purchaseService.start()
            await purchaseService.loadProductsIfNeeded()
            let isPremium = await purchaseService.refreshEntitlementStatus()
            gameStore.setSubscriberStatus(isPremium)
            themeStore.refreshSubscriptionState(isSubscriber: isPremium)
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    PremiumPaywallView()
        .environment(GameStore())
        .environment(PurchaseService())
        .environment(ThemeStore())
}
