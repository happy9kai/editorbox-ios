//
//  ThemeStore.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import Foundation
import Observation
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppThemeID: String, CaseIterable, Identifiable {
    case `default` = "default"
    case sunset = "sunset"
    case premiumMidnight = "premium_midnight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .sunset:
            return "Sunset"
        case .premiumMidnight:
            return "Premium Midnight"
        }
    }

    var requiresSubscription: Bool {
        self == .premiumMidnight
    }

    var coinPrice: Int? {
        switch self {
        case .sunset:
            return 30
        default:
            return nil
        }
    }
}

struct AppThemePalette {
    let id: AppThemeID
    let backgroundFallback: LinearGradient
    let usesSunsetImage: Bool
    let backgroundOverlayOpacity: Double
    let cardBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let positive: Color

    static func palette(for id: AppThemeID) -> AppThemePalette {
        switch id {
        case .default:
            return AppThemePalette(
                id: .default,
                backgroundFallback: LinearGradient(
                    colors: [Color.white, Color(red: 0.95, green: 0.97, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                usesSunsetImage: false,
                backgroundOverlayOpacity: 0,
                cardBackground: Color.white.opacity(0.9),
                primaryText: .primary,
                secondaryText: .secondary,
                accent: .blue,
                positive: .green
            )
        case .sunset:
            return AppThemePalette(
                id: .sunset,
                backgroundFallback: LinearGradient(
                    colors: [
                        Color(red: 0.33, green: 0.45, blue: 0.79),
                        Color(red: 0.66, green: 0.25, blue: 0.8),
                        Color(red: 0.78, green: 0.57, blue: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                usesSunsetImage: true,
                backgroundOverlayOpacity: 0.18,
                cardBackground: Color.white.opacity(0.22),
                primaryText: .white,
                secondaryText: Color.white.opacity(0.85),
                accent: Color(red: 0.93, green: 0.84, blue: 1.0),
                positive: Color(red: 0.72, green: 0.95, blue: 0.72)
            )
        case .premiumMidnight:
            return AppThemePalette(
                id: .premiumMidnight,
                backgroundFallback: LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.26, blue: 0.48),
                        Color(red: 0.38, green: 0.22, blue: 0.52),
                        Color(red: 0.3, green: 0.35, blue: 0.58)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                usesSunsetImage: true,
                backgroundOverlayOpacity: 0.25,
                cardBackground: Color.black.opacity(0.35),
                primaryText: .white,
                secondaryText: Color.white.opacity(0.82),
                accent: Color(red: 0.72, green: 0.9, blue: 1.0),
                positive: Color(red: 0.62, green: 0.92, blue: 0.72)
            )
        }
    }
}

@MainActor
@Observable
final class ThemeStore {
    private(set) var currentThemeID: AppThemeID = .default
    private(set) var ownedThemeIDs: Set<String> = [AppThemeID.default.rawValue]

    @ObservationIgnored private var modelContext: ModelContext?

    var currentTheme: AppThemePalette {
        AppThemePalette.palette(for: currentThemeID)
    }

    func configure(modelContext: ModelContext, isSubscriber: Bool) {
        self.modelContext = modelContext
        ensureDefaultThemeExists()
        reloadThemeState(isSubscriber: isSubscriber)
    }

    func refreshSubscriptionState(isSubscriber: Bool) {
        reloadThemeState(isSubscriber: isSubscriber)
    }

    func isOwned(themeId: String) -> Bool {
        guard let themeID = AppThemeID(rawValue: themeId) else { return false }
        if themeID == .default { return true }
        return ownedThemeIDs.contains(themeId)
    }

    func isEquipped(themeId: String) -> Bool {
        currentThemeID.rawValue == themeId
    }

    @discardableResult
    func purchaseTheme(themeId: String, price: Int, gameStore: GameStore) -> Bool {
        guard let themeID = AppThemeID(rawValue: themeId) else { return false }
        guard !themeID.requiresSubscription else { return false }

        if isOwned(themeId: themeId) {
            return apply(themeId: themeId, isSubscriber: gameStore.isSubscriber)
        }

        guard gameStore.spendCoins(price) else { return false }
        let purchasedItem = upsertThemeItem(id: themeId)
        purchasedItem.owned = true
        if purchasedItem.obtainedAt == nil {
            purchasedItem.obtainedAt = .now
        }
        saveContext()
        reloadThemeState(isSubscriber: gameStore.isSubscriber)
        return apply(themeId: themeId, isSubscriber: gameStore.isSubscriber)
    }

    @discardableResult
    func apply(themeId: String, isSubscriber: Bool) -> Bool {
        guard let themeID = AppThemeID(rawValue: themeId) else { return false }

        if themeID.requiresSubscription && !isSubscriber {
            return false
        }

        if themeID != .default && !isOwned(themeId: themeId) && !themeID.requiresSubscription {
            return false
        }

        guard modelContext != nil else { return false }

        let items = fetchThemeItems()
        for item in items {
            item.equipped = false
        }

        let target = upsertThemeItem(id: themeId)
        target.owned = true
        target.equipped = true

        if target.obtainedAt == nil {
            target.obtainedAt = .now
        }

        saveContext()
        reloadThemeState(isSubscriber: isSubscriber)
        return true
    }

    private func ensureDefaultThemeExists() {
        guard modelContext != nil else { return }

        let items = fetchThemeItems()
        if let defaultItem = items.first(where: { $0.id == AppThemeID.default.rawValue }) {
            defaultItem.owned = true
            if !items.contains(where: { $0.equipped }) {
                defaultItem.equipped = true
            }
        } else {
            let defaultItem = OwnedItem(
                itemId: AppThemeID.default.rawValue,
                type: "theme",
                isOwned: true,
                isEquipped: true,
                obtainedAt: .now
            )
            modelContext?.insert(defaultItem)
        }

        saveContext()
    }

    private func reloadThemeState(isSubscriber: Bool) {
        guard modelContext != nil else { return }

        var items = fetchThemeItems()

        if isSubscriber {
            let premium = upsertThemeItem(id: AppThemeID.premiumMidnight.rawValue)
            premium.owned = true
            if premium.obtainedAt == nil {
                premium.obtainedAt = .now
            }
        } else if let premium = items.first(where: { $0.id == AppThemeID.premiumMidnight.rawValue }) {
            premium.owned = false
            if premium.equipped {
                premium.equipped = false
            }
        }

        items = fetchThemeItems()

        if !items.contains(where: { $0.id == AppThemeID.default.rawValue }) {
            let defaultItem = OwnedItem(
                itemId: AppThemeID.default.rawValue,
                type: "theme",
                isOwned: true,
                isEquipped: true,
                obtainedAt: .now
            )
            modelContext?.insert(defaultItem)
            items = fetchThemeItems()
        }

        let validEquipped = items.first {
            $0.equipped
            && $0.owned
            && (AppThemeID(rawValue: $0.id) != .premiumMidnight || isSubscriber)
        }

        if validEquipped == nil {
            for item in items {
                item.equipped = false
            }
            let fallback = upsertThemeItem(id: AppThemeID.default.rawValue)
            fallback.owned = true
            fallback.equipped = true
        }

        saveContext()
        let latestItems = fetchThemeItems()

        ownedThemeIDs = Set(latestItems.filter(\.owned).map(\.id))
        ownedThemeIDs.insert(AppThemeID.default.rawValue)

        currentThemeID = latestItems
            .first(where: { $0.equipped })
            .flatMap { AppThemeID(rawValue: $0.id) }
            ?? .default
    }

    private func upsertThemeItem(id: String) -> OwnedItem {
        if let existing = fetchThemeItems().first(where: { $0.id == id }) {
            return existing
        }

        let newItem = OwnedItem(
            itemId: id,
            type: "theme",
            isOwned: false,
            isEquipped: false,
            obtainedAt: nil
        )
        modelContext?.insert(newItem)
        return newItem
    }

    private func fetchThemeItems() -> [OwnedItem] {
        guard let modelContext else { return [] }

        var descriptor = FetchDescriptor<OwnedItem>(
            predicate: #Predicate { $0.type == "theme" }
        )
        descriptor.fetchLimit = 200

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            // テーマ保存失敗時は次回操作で再試行する。
        }
    }
}

struct ThemedBackgroundView: View {
    let theme: AppThemePalette

    var body: some View {
        Group {
            if theme.usesSunsetImage, hasThemeImageAsset {
                Image("ThemeSunsetBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                theme.backgroundFallback
                    .ignoresSafeArea()
            }
        }
        .overlay(Color.black.opacity(theme.backgroundOverlayOpacity).ignoresSafeArea())
    }

    private var hasThemeImageAsset: Bool {
#if canImport(UIKit)
        UIImage(named: "ThemeSunsetBackground") != nil
#elseif canImport(AppKit)
        NSImage(named: NSImage.Name("ThemeSunsetBackground")) != nil
#else
        false
#endif
    }
}
