//
//  IdeaViewModel.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import Foundation
import Combine

@MainActor
final class IdeaViewModel: ObservableObject {
    @Published var title: String
    @Published var memo: String
    @Published var tagsText: String
    @Published var errorMessage: String?

    private let editingIdea: Idea?

    init(idea: Idea? = nil) {
        self.editingIdea = idea
        self.title = idea?.title ?? ""
        self.memo = idea?.memo ?? ""
        self.tagsText = idea?.tags.joined(separator: ", ") ?? ""
    }

    /// 画面入力を保存（新規 or 更新）
    func save(using dataService: DataService) -> Bool {
        let parsedTags = parseTags(from: tagsText)

        do {
            if let editingIdea {
                try dataService.updateIdea(editingIdea, title: title, memo: memo, tags: parsedTags)
            } else {
                try dataService.createIdea(title: title, memo: memo, tags: parsedTags)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func parseTags(from input: String) -> [String] {
        // カンマ区切りのタグを正規化し、重複を除去
        let rawTags = input
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var uniqueTags: [String] = []
        for tag in rawTags {
            if !uniqueTags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                uniqueTags.append(tag)
            }
        }

        return uniqueTags
    }
}
