//
//  AppGroupStore.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import Foundation
import SwiftData

enum AppGroupStore {
    static let appGroupIdentifier = "group.jp.imidefworks.EditorBox"
    private static let models: [any PersistentModel.Type] = [
        Idea.self,
        IdeaAttachment.self,
        PlayerProgress.self,
        OwnedItem.self,
    ]

    static var schema: Schema {
        Schema(models)
    }

    static func makeModelConfiguration(inMemory: Bool = false) -> ModelConfiguration {
        guard !inMemory else {
            return ModelConfiguration(
                "EditorBoxShared",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        }

        return ModelConfiguration(
            "EditorBoxShared",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .none
        )
    }

    static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = makeModelConfiguration(inMemory: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
