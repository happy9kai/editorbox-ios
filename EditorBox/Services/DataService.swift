//
//  DataService.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import Foundation
import SwiftData

enum DataServiceError: LocalizedError {
    case emptyTitle
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "タイトルを入力してください。"
        case .saveFailed:
            return "保存に失敗しました。もう一度お試しください。"
        }
    }
}

@MainActor
struct DataService {
    let context: ModelContext

    /// 新規アイデアを保存
    @discardableResult
    func createIdea(title: String, memo: String, tags: [String]) throws -> Idea {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            throw DataServiceError.emptyTitle
        }

        let idea = Idea(
            title: normalizedTitle,
            memo: memo,
            tags: tags
        )

        context.insert(idea)

        do {
            try context.save()
            return idea
        } catch {
            throw DataServiceError.saveFailed
        }
    }

    /// 既存アイデアを更新
    func updateIdea(_ idea: Idea, title: String, memo: String, tags: [String]) throws {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            throw DataServiceError.emptyTitle
        }

        idea.update(title: normalizedTitle, memo: memo, tags: tags)

        do {
            try context.save()
        } catch {
            throw DataServiceError.saveFailed
        }
    }

    /// アイデアを削除
    func deleteIdea(_ idea: Idea) throws {
        context.delete(idea)

        do {
            try context.save()
        } catch {
            throw DataServiceError.saveFailed
        }
    }
}
