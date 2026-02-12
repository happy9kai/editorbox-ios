//
//  GameProgress.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import Foundation
import SwiftData

@Model
final class PlayerProgress {
    var level: Int
    var xp: Int
    var coins: Int
    var streakDays: Int
    var lastSavedDate: Date
    var lastRewardDate: Date
    var totalChars: Int
    var totalSaves: Int
    var isSubscriber: Bool
    var lastSavedMemoId: String?
    var lastSavedMemoAt: Date?

    init(
        level: Int = 1,
        xp: Int = 0,
        coins: Int = 0,
        streakDays: Int = 0,
        lastSavedDate: Date = .distantPast,
        lastRewardDate: Date = .distantPast,
        totalChars: Int = 0,
        totalSaves: Int = 0,
        isSubscriber: Bool = false,
        lastSavedMemoId: String? = nil,
        lastSavedMemoAt: Date? = nil
    ) {
        self.level = level
        self.xp = xp
        self.coins = coins
        self.streakDays = streakDays
        self.lastSavedDate = lastSavedDate
        self.lastRewardDate = lastRewardDate
        self.totalChars = totalChars
        self.totalSaves = totalSaves
        self.isSubscriber = isSubscriber
        self.lastSavedMemoId = lastSavedMemoId
        self.lastSavedMemoAt = lastSavedMemoAt
    }
}

@Model
final class OwnedItem {
    @Attribute(.unique) var id: String
    var type: String
    var owned: Bool
    var equipped: Bool
    var obtainedAt: Date?

    init(
        itemId: String,
        type: String,
        isOwned: Bool = false,
        isEquipped: Bool = false,
        obtainedAt: Date? = nil
    ) {
        self.id = itemId
        self.type = type
        self.owned = isOwned
        self.equipped = isEquipped
        self.obtainedAt = obtainedAt
    }

    var itemId: String {
        get { id }
        set { id = newValue }
    }

    var isOwned: Bool {
        get { owned }
        set { owned = newValue }
    }

    var isEquipped: Bool {
        get { equipped }
        set { equipped = newValue }
    }
}
