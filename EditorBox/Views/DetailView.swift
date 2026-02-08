//
//  DetailView.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let idea: Idea

    @State private var isShowingEditor = false
    @State private var isShowingDeleteConfirm = false
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(idea.title)
                    .font(.title2)
                    .fontWeight(.bold)

                if !idea.tags.isEmpty {
                    TagSectionView(tags: idea.tags)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("メモ")
                        .font(.headline)

                    Text(idea.memo.isEmpty ? "（メモは未入力です）" : idea.memo)
                        .font(.body)
                        .foregroundStyle(idea.memo.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("作成日")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(idea.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))

                    Text("更新日")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Text(idea.updatedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirm = true
                } label: {
                    Label("このメモを削除", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 12)
            }
            .padding()
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    isShowingEditor = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            EditorView(idea: idea)
        }
        .confirmationDialog("このメモを削除しますか？", isPresented: $isShowingDeleteConfirm, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                deleteIdea()
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("エラー", isPresented: Binding(get: {
            alertMessage != nil
        }, set: { newValue in
            if !newValue {
                alertMessage = nil
            }
        })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func deleteIdea() {
        do {
            try DataService(context: modelContext).deleteIdea(idea)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

private struct TagSectionView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タグ")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.14), in: Capsule())
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Idea.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let idea = Idea(
        title: "プレビュー用メモ",
        memo: "ここに詳細メモが表示されます。",
        tags: ["SwiftUI", "SwiftData"]
    )
    container.mainContext.insert(idea)

    return NavigationStack {
        DetailView(idea: idea)
    }
    .modelContainer(container)
}
