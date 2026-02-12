//
//  GameStore.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class GameStore {
    private(set) var level: Int = 1
    private(set) var coins: Int = 0
    private(set) var streakDays: Int = 0
    private(set) var characterSymbolName: String = "person.crop.circle.fill"
    private(set) var isSubscriber: Bool = false

    private(set) var canClaimDailyReward: Bool = false
    private(set) var dailyRewardAmount: Int = 10
    private(set) var paywallTitle: String = ""
    private(set) var paywallMessage: String = ""

    var shouldShowLevelUpBanner: Bool = false
    var shouldShowDailyRewardSheet: Bool = false
    var shouldShowPaywallSheet: Bool = false

    @ObservationIgnored private var modelContext: ModelContext?
    @ObservationIgnored private var progressCache: PlayerProgress?
    @ObservationIgnored private var lastRewardedSaveByMemoID: [String: Date] = [:]
    @ObservationIgnored private var hasShownMilestonePaywallThisSession = false

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        guard let progress = loadOrCreateProgress() else { return }
        syncState(from: progress)
    }

    func handleMemoSaved(charCount: Int, memoId: String) {
        guard let progress = loadOrCreateProgress() else { return }

        let now = Date()
        updateStreak(for: progress, at: now)
        progress.totalSaves += 1
        progress.totalChars += max(0, charCount)
        progress.lastSavedDate = now

        if !isRewardThrottled(memoId: memoId, at: now) {
            let gainedXP = calculateXPGain(charCount: charCount)
            let gainedCoins = calculateCoinGain(charCount: charCount) * coinMultiplier(for: progress)

            progress.xp += gainedXP
            progress.coins += gainedCoins

            if applyLevelUps(progress: progress) {
                shouldShowLevelUpBanner = true
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    self?.shouldShowLevelUpBanner = false
                }
            }
        }

        saveAndSync(progress: progress)
        evaluateMilestonePaywallIfNeeded(progress: progress)
    }

    func checkDailyReward() {
        guard let progress = loadOrCreateProgress() else { return }
        let canClaim = !Calendar.current.isDate(progress.lastRewardDate, inSameDayAs: .now)
        canClaimDailyReward = canClaim
        shouldShowDailyRewardSheet = canClaim
    }

    func claimDailyReward() {
        guard canClaimDailyReward, let progress = loadOrCreateProgress() else { return }
        progress.coins += dailyRewardAmount * coinMultiplier(for: progress)
        progress.lastRewardDate = .now
        canClaimDailyReward = false
        shouldShowDailyRewardSheet = false
        saveAndSync(progress: progress)
    }

    func dismissDailyRewardSheet() {
        shouldShowDailyRewardSheet = false
    }

    func dismissPaywall() {
        shouldShowPaywallSheet = false
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard let progress = loadOrCreateProgress() else { return false }
        guard amount > 0 else { return true }

        if progress.coins < amount {
            presentPaywall(
                title: "コイン不足",
                message: "コインが不足しています。サブスクでコイン獲得量を2倍にできます。"
            )
            return false
        }

        progress.coins -= amount
        saveAndSync(progress: progress)
        return true
    }

    private func calculateXPGain(charCount: Int) -> Int {
        let normalized = max(0, charCount)
        return 5 + min(normalized / 40, 25)
    }

    private func calculateCoinGain(charCount: Int) -> Int {
        let normalized = max(0, charCount)
        return 1 + min(normalized / 200, 5)
    }

    private func requiredXP(for level: Int) -> Int {
        50 + (level * 25)
    }

    private func coinMultiplier(for progress: PlayerProgress) -> Int {
        progress.isSubscriber ? 2 : 1
    }

    private func applyLevelUps(progress: PlayerProgress) -> Bool {
        var leveledUp = false
        while progress.xp >= requiredXP(for: progress.level) {
            progress.xp -= requiredXP(for: progress.level)
            progress.level += 1
            leveledUp = true
        }
        return leveledUp
    }

    private func updateStreak(for progress: PlayerProgress, at date: Date) {
        let calendar = Calendar.current
        if calendar.isDate(progress.lastSavedDate, inSameDayAs: date) {
            return
        }

        if
            let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
            calendar.isDate(progress.lastSavedDate, inSameDayAs: yesterday)
        {
            progress.streakDays += 1
        } else {
            progress.streakDays = 1
        }
    }

    private func isRewardThrottled(memoId: String, at date: Date) -> Bool {
        let normalizedMemoID = memoId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedMemoID.isEmpty else { return false }

        if let lastRewardDate = lastRewardedSaveByMemoID[normalizedMemoID] {
            if date.timeIntervalSince(lastRewardDate) < 60 {
                return true
            }
        }

        lastRewardedSaveByMemoID[normalizedMemoID] = date
        return false
    }

    private func evaluateMilestonePaywallIfNeeded(progress: PlayerProgress) {
        guard !progress.isSubscriber, !hasShownMilestonePaywallThisSession else { return }

        if progress.level >= 3 {
            hasShownMilestonePaywallThisSession = true
            presentPaywall(
                title: "レベル3到達",
                message: "サブスクで広告非表示・コイン2倍・限定テーマを解放できます。"
            )
        } else if progress.streakDays >= 3 {
            hasShownMilestonePaywallThisSession = true
            presentPaywall(
                title: "3日連続達成",
                message: "継続の勢いを活かして、サブスク特典で成長効率を上げましょう。"
            )
        }
    }

    private func presentPaywall(title: String, message: String) {
        paywallTitle = title
        paywallMessage = message
        shouldShowPaywallSheet = true
    }

    private func saveAndSync(progress: PlayerProgress) {
        do {
            try modelContext?.save()
        } catch {
            // MVP段階では保存失敗時もクラッシュを避け、次回保存時に再試行する。
        }
        syncState(from: progress)
    }

    private func syncState(from progress: PlayerProgress) {
        level = progress.level
        coins = progress.coins
        streakDays = progress.streakDays
        isSubscriber = progress.isSubscriber
        characterSymbolName = characterSymbol(for: progress.level)
    }

    private func characterSymbol(for level: Int) -> String {
        switch level {
        case ..<3:
            return "person.crop.circle.fill"
        case ..<6:
            return "person.crop.circle.badge.plus"
        default:
            return "person.crop.circle.badge.checkmark"
        }
    }

    private func loadOrCreateProgress() -> PlayerProgress? {
        if let progressCache {
            return progressCache
        }

        guard let modelContext else { return nil }
        var descriptor = FetchDescriptor<PlayerProgress>()
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            progressCache = existing
            return existing
        }

        let newProgress = PlayerProgress()
        modelContext.insert(newProgress)
        do {
            try modelContext.save()
        } catch {
            return nil
        }

        progressCache = newProgress
        return newProgress
    }
}
