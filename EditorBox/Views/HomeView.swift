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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(GameStore.self) private var gameStore
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(ThemeStore.self) private var themeStore
    @Query(sort: [SortDescriptor(\Idea.updatedAt, order: .reverse)]) private var ideas: [Idea]

    @State private var searchText = ""
    @State private var isShowingEditor = false
    @State private var isShowingShop = false
    @State private var alertMessage: String?
    @State private var hasInitializedStores = false
    @State private var refreshToken = UUID()

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

    private var theme: AppThemePalette {
        themeStore.currentTheme
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackgroundView(theme: theme)

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
                            .listRowBackground(theme.cardBackground)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteIdea(idea)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
                .id(refreshToken)
            }
            .navigationTitle("EditorBox")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingShop = true
                    } label: {
                        Label("ショップ", systemImage: "bag")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEditor = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .tint(theme.accent)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "タイトル・メモ・タグで検索")
            .sheet(isPresented: $isShowingEditor) {
                EditorView()
            }
            .sheet(isPresented: $isShowingShop) {
                MiniShopView()
            }
            .sheet(isPresented: Binding(
                get: { gameStore.shouldShowDailyRewardSheet },
                set: { isPresented in
                    if !isPresented {
                        gameStore.dismissDailyRewardSheet()
                    }
                }
            )) {
                DailyRewardSheetView()
            }
            .sheet(isPresented: Binding(
                get: { gameStore.shouldShowPaywallSheet },
                set: { isPresented in
                    if !isPresented {
                        gameStore.dismissPaywall()
                    }
                }
            )) {
                PremiumPaywallView()
            }
            .task {
                if !hasInitializedStores {
                    hasInitializedStores = true
                    gameStore.configure(modelContext: modelContext)
                    purchaseService.start()
                    let isPremium = await purchaseService.refreshEntitlementStatus()
                    gameStore.setSubscriberStatus(isPremium)
                    themeStore.configure(modelContext: modelContext, isSubscriber: isPremium)
                    gameStore.checkDailyReward()
                }
            }
            .onChange(of: gameStore.isSubscriber) { _, isSubscriber in
                themeStore.refreshSubscriptionState(isSubscriber: isSubscriber)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                refreshToken = UUID()
                gameStore.configure(modelContext: modelContext)
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
    @Environment(ThemeStore.self) private var themeStore

    let idea: Idea

    private var theme: AppThemePalette {
        themeStore.currentTheme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(idea.title)
                .font(.headline)
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)

            if !idea.memo.isEmpty {
                Text(idea.memo)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Text(idea.updatedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)

                if !idea.tags.isEmpty {
                    Text(idea.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(theme.accent)
                        .lineLimit(1)
                }

                if !idea.attachments.isEmpty {
                    Label("\(idea.attachments.count)", systemImage: "paperclip")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environment(GameStore())
        .environment(PurchaseService())
        .environment(ThemeStore())
        .modelContainer(for: [Idea.self, IdeaAttachment.self, PlayerProgress.self, OwnedItem.self], inMemory: true)
}
