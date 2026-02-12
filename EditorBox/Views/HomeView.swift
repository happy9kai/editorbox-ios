//
//  HomeView.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Idea.updatedAt, order: .reverse)]) private var ideas: [Idea]

    @State private var searchText = ""
    @State private var isShowingEditor = false
    @State private var alertMessage: String?

    private var filteredIdeas: [Idea] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            return ideas
        }

        return ideas.filter { idea in
            idea.title.localizedCaseInsensitiveContains(keyword)
            || idea.memo.localizedCaseInsensitiveContains(keyword)
            || idea.tags.contains(where: { $0.localizedCaseInsensitiveContains(keyword) })
            || idea.attachments.contains(where: { $0.fileName.localizedCaseInsensitiveContains(keyword) })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredIdeas.isEmpty {
                    ContentUnavailableView(
                        "メモがありません",
                        systemImage: "square.and.pencil",
                        description: Text("右上の + ボタンからメモを追加できます。")
                    )
                } else {
                    List(filteredIdeas) { idea in
                        NavigationLink {
                            DetailView(idea: idea)
                        } label: {
                            IdeaRowView(idea: idea)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteIdea(idea)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("EditorBox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEditor = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "タイトル・メモ・タグで検索")
            .sheet(isPresented: $isShowingEditor) {
                EditorView()
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
    }

    private func deleteIdea(_ idea: Idea) {
        do {
            try DataService(context: modelContext).deleteIdea(idea)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

private struct IdeaRowView: View {
    let idea: Idea

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(idea.title)
                .font(.headline)
                .lineLimit(1)

            if !idea.memo.isEmpty {
                Text(idea.memo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Text(idea.updatedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !idea.tags.isEmpty {
                    Text(idea.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }

                if !idea.attachments.isEmpty {
                    Label("\(idea.attachments.count)", systemImage: "paperclip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Idea.self, IdeaAttachment.self], inMemory: true)
}
