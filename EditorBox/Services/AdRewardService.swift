//
//  AdRewardService.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import Foundation

protocol AdRewardService {
    /// MVPはスタブ。将来 AdMob Rewarded に差し替える。
    func showRewardedAdAndGetCoins() async -> Int
}

struct StubAdRewardService: AdRewardService {
    func showRewardedAdAndGetCoins() async -> Int {
        0
    }
}
