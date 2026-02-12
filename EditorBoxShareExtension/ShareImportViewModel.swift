//
//  ShareImportViewModel.swift
//  EditorBoxShareExtension
//
//  Created by Codex on 2026/02/12.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class ShareImportViewModel: ObservableObject {
    enum Phase: Equatable {
        case loading
        case ready
        case saving
        case failed(String)
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var importedText: String = ""

    var previewText: String {
        importedText
            .split(separator: "\n", omittingEmptySubsequences: false)
            .prefix(6)
            .map(String.init)
            .joined(separator: "\n")
    }

    var canSave: Bool {
        guard !isBusy else { return false }
        return !importedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isBusy: Bool {
        switch phase {
        case .loading, .saving:
            return true
        case .ready, .failed:
            return false
        }
    }

    private let extensionContext: NSExtensionContext
    private var hasLoaded = false

    init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        Task {
            await loadIncomingText()
        }
    }

    func cancel() {
        let error = NSError(
            domain: NSCocoaErrorDomain,
            code: NSUserCancelledError,
            userInfo: [NSLocalizedDescriptionKey: "ユーザーが共有をキャンセルしました。"]
        )
        extensionContext.cancelRequest(withError: error)
    }

    func save() {
        guard canSave else { return }
        phase = .saving

        Task {
            do {
                try persistImportedText()
                extensionContext.completeRequest(returningItems: nil)
            } catch {
                phase = .failed("保存に失敗しました。もう一度お試しください。")
            }
        }
    }

    private func loadIncomingText() async {
        if let text = await extractTextFromInputItems() {
            let normalized = normalize(text: text)
            guard !normalized.isEmpty else {
                phase = .failed("本文テキストが空です。")
                return
            }
            importedText = normalized
            phase = .ready
        } else {
            phase = .failed("共有データから本文テキストを取得できませんでした。")
        }
    }

    private func extractTextFromInputItems() async -> String? {
        let items = extensionContext.inputItems.compactMap { $0 as? NSExtensionItem }

        for item in items {
            let providers = item.attachments ?? []

            for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                if let text = await provider.loadPlainText() {
                    return text
                }
            }

            for provider in providers where provider.canLoadObject(ofClass: NSString.self) {
                if let text = await provider.loadTextObject() {
                    return text
                }
            }
        }

        return nil
    }

    private func persistImportedText() throws {
        let normalized = normalize(text: importedText)
        guard !normalized.isEmpty else {
            throw ShareImportError.emptyText
        }

        let container = try AppGroupStore.makeModelContainer()
        let context = ModelContext(container)
        let now = Date()

        let (title, body) = splitTitleAndBody(from: normalized)
        let newIdea = Idea(
            title: title,
            memo: body,
            createdAt: now,
            updatedAt: now
        )
        context.insert(newIdea)

        let progress = try loadOrCreateProgress(context: context)
        progress.notesImportedCount += 1
        progress.xp += 1
        progress.totalSaves += 1
        progress.totalChars += normalized.count
        progress.lastSavedDate = now
        progress.lastSavedMemoId = newIdea.id.uuidString
        progress.lastSavedMemoAt = now

        try context.save()
    }

    private func loadOrCreateProgress(context: ModelContext) throws -> PlayerProgress {
        var descriptor = FetchDescriptor<PlayerProgress>()
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let newProgress = PlayerProgress()
        context.insert(newProgress)
        return newProgress
    }

    private func splitTitleAndBody(from text: String) -> (title: String, body: String) {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: .newlines)

        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = firstLine.isEmpty ? "共有メモ" : String(firstLine.prefix(80))
        let body = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        return (title, body)
    }

    private func normalize(text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum ShareImportError: Error {
    case emptyText
}

private extension NSItemProvider {
    func loadPlainText() async -> String? {
        await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    continuation.resume(returning: text)
                    return
                }

                if
                    let data = item as? Data,
                    let text = String(data: data, encoding: .utf8)
                {
                    continuation.resume(returning: text)
                    return
                }

                if
                    let url = item as? URL,
                    let text = try? String(contentsOf: url, encoding: .utf8)
                {
                    continuation.resume(returning: text)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    func loadTextObject() async -> String? {
        await withCheckedContinuation { continuation in
            loadObject(ofClass: NSString.self) { object, _ in
                if let nsString = object as? NSString {
                    continuation.resume(returning: nsString as String)
                } else if let string = object as? String {
                    continuation.resume(returning: string)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
