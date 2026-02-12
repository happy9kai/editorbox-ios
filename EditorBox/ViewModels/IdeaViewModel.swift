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
    struct SaveResult {
        let memoId: String
        let charCount: Int
    }

    @Published var title: String
    @Published var memo: String
    @Published var tagsText: String
    @Published var attachments: [AttachmentDraft]
    @Published var errorMessage: String?

    private let editingIdea: Idea?

    init(idea: Idea? = nil) {
        self.editingIdea = idea
        self.title = idea?.title ?? ""
        self.memo = idea?.memo ?? ""
        self.tagsText = idea?.tags.joined(separator: ", ") ?? ""
        self.attachments = idea?.attachments
            .sorted(by: { $0.createdAt < $1.createdAt })
            .map(AttachmentDraft.init(from:))
            ?? []
    }

    /// 画面入力を保存（新規 or 更新）
    func save(using dataService: DataService) -> SaveResult? {
        let parsedTags = parseTags(from: tagsText)

        do {
            let savedIdea: Idea
            if let editingIdea {
                try dataService.updateIdea(
                    editingIdea,
                    title: title,
                    memo: memo,
                    tags: parsedTags,
                    attachments: attachments
                )
                savedIdea = editingIdea
            } else {
                savedIdea = try dataService.createIdea(
                    title: title,
                    memo: memo,
                    tags: parsedTags,
                    attachments: attachments
                )
            }
            errorMessage = nil
            return SaveResult(memoId: savedIdea.id.uuidString, charCount: memo.count)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func addAttachment(fileName: String, contentTypeIdentifier: String, data: Data) {
        guard !data.isEmpty else { return }
        attachments.append(
            AttachmentDraft(
                fileName: fileName,
                contentTypeIdentifier: contentTypeIdentifier,
                data: data
            )
        )
    }

    func removeAttachment(id: UUID) {
        attachments.removeAll { $0.id == id }
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
