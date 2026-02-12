//
//  EditorView.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel: IdeaViewModel
    @State private var isShowingFileImporter = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(idea: Idea? = nil) {
        _viewModel = StateObject(wrappedValue: IdeaViewModel(idea: idea))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("例: 週末に作るアプリ案", text: $viewModel.title)
                }

                Section("メモ") {
                    TextEditor(text: $viewModel.memo)
                        .frame(minHeight: 180)
                }

                Section("タグ") {
                    TextField("例: SwiftUI, 収益化, AI", text: $viewModel.tagsText)
                        .textInputAutocapitalization(.never)
                    Text("カンマ区切りで入力してください")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("添付ファイル") {
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Label("写真を追加", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("ファイルを追加", systemImage: "paperclip")
                    }

                    if viewModel.attachments.isEmpty {
                        Text("写真、PDF、その他ファイルを添付できます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.attachments) { attachment in
                            AttachmentDraftRowView(
                                attachment: attachment,
                                onRemove: {
                                    viewModel.removeAttachment(id: attachment.id)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle(viewModel.title.isEmpty ? "新規メモ" : "メモ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveIdea()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("保存エラー", isPresented: Binding(get: {
                viewModel.errorMessage != nil
            }, set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true,
                onCompletion: importFiles
            )
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task {
                    await importPhotos(from: newItems)
                }
            }
        }
    }

    private func saveIdea() {
        let dataService = DataService(context: modelContext)
        let isSuccess = viewModel.save(using: dataService)

        if isSuccess {
            dismiss()
        }
    }

    @MainActor
    private func importPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        defer { selectedPhotoItems = [] }

        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    continue
                }

                let contentType = item.supportedContentTypes.first ?? .image
                let fileExtension = contentType.preferredFilenameExtension ?? "jpg"
                let fileName = "photo-\(UUID().uuidString).\(fileExtension)"

                viewModel.addAttachment(
                    fileName: fileName,
                    contentTypeIdentifier: contentType.identifier,
                    data: data
                )
            } catch {
                viewModel.errorMessage = "写真の読み込みに失敗しました。"
            }
        }
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    let data = try loadFileData(from: url)
                    let fileName = url.lastPathComponent.isEmpty
                        ? "file-\(UUID().uuidString)"
                        : url.lastPathComponent
                    let contentType = UTType(filenameExtension: url.pathExtension) ?? .data

                    viewModel.addAttachment(
                        fileName: fileName,
                        contentTypeIdentifier: contentType.identifier,
                        data: data
                    )
                } catch {
                    viewModel.errorMessage = "ファイルの読み込みに失敗しました。"
                }
            }
        case .failure:
            viewModel.errorMessage = "ファイル選択に失敗しました。"
        }
    }

    private func loadFileData(from url: URL) throws -> Data {
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if needsSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try Data(contentsOf: url)
    }
}

#Preview {
    EditorView()
        .modelContainer(for: [Idea.self, IdeaAttachment.self], inMemory: true)
}

private struct AttachmentDraftRowView: View {
    let attachment: AttachmentDraft
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AttachmentThumbnailView(data: attachment.data, isImage: attachment.isImage, isPDF: attachment.isPDF)

            VStack(alignment: .leading, spacing: 4) {
                Text(attachment.fileName)
                    .font(.subheadline)
                    .lineLimit(2)

                Text(attachment.formattedFileSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("添付を削除")
        }
        .padding(.vertical, 4)
    }
}

private struct AttachmentThumbnailView: View {
    let data: Data
    let isImage: Bool
    let isPDF: Bool

    var body: some View {
        Group {
            if isImage, let image = previewImage(from: data) {
                image
                    .resizable()
                    .scaledToFill()
            } else if isPDF {
                Image(systemName: "doc.richtext")
                    .font(.title3)
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "doc")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private func previewImage(from data: Data) -> Image? {
#if canImport(UIKit)
    if let image = UIImage(data: data) {
        return Image(uiImage: image)
    }
#elseif canImport(AppKit)
    if let image = NSImage(data: data) {
        return Image(nsImage: image)
    }
#endif
    return nil
}
