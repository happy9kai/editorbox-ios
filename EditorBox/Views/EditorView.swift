//
//  EditorView.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import SwiftUI
import SwiftData

struct EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel: IdeaViewModel

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
        }
    }

    private func saveIdea() {
        let dataService = DataService(context: modelContext)
        let isSuccess = viewModel.save(using: dataService)

        if isSuccess {
            dismiss()
        }
    }
}

#Preview {
    EditorView()
        .modelContainer(for: Idea.self, inMemory: true)
}
