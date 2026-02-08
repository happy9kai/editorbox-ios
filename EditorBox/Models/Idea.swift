//
//  Idea.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import Foundation
import SwiftData

@Model
final class Idea {
    @Attribute(.unique) var id: UUID
    var title: String
    var memo: String
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        memo: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
    }

    /// 編集時に必要な値をまとめて更新
    func update(title: String, memo: String, tags: [String]) {
        self.title = title
        self.memo = memo
        self.tags = tags
        self.updatedAt = .now
    }
}
