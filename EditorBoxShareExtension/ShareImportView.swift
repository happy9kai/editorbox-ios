//
//  ShareImportView.swift
//  EditorBoxShareExtension
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI

struct ShareImportView: View {
    @StateObject private var viewModel: ShareImportViewModel

    init(viewModel: ShareImportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                switch viewModel.phase {
                case .loading:
                    busyState(title: "読み込み中...")
                case .saving:
                    busyState(title: "保存中...")
                case .ready:
                    previewSection
                case .failed(let message):
                    failedSection(message: message)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("メモに取り込む")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        viewModel.cancel()
                    }
                    .disabled(viewModel.isBusy)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        viewModel.save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("プレビュー")
                .font(.headline)

            ScrollView {
                Text(viewModel.previewText.isEmpty ? "（本文なし）" : viewModel.previewText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 260)
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            Text("先頭数行を表示しています。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func busyState(title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressView()
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 32)
    }

    private func failedSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("エラー")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("閉じる") {
                viewModel.cancel()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
