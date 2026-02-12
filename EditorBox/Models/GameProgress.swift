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

    init(
        level: Int = 1,
        xp: Int = 0,
        coins: Int = 0,
        streakDays: Int = 0,
        lastSavedDate: Date = .distantPast,
        lastRewardDate: Date = .distantPast,
        totalChars: Int = 0,
        totalSaves: Int = 0,
        isSubscriber: Bool = false
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
    }
}

@Model
final class OwnedItem {
    @Attribute(.unique) var id: String
    var type: String
    var owned: Bool
    var equipped: Bool

    init(id: String, type: String, owned: Bool = false, equipped: Bool = false) {
        self.id = id
        self.type = type
        self.owned = owned
        self.equipped = equipped
    }
}
