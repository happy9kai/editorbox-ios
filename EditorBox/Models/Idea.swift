//
//  Idea.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/08.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

@Model
final class Idea {
    @Attribute(.unique) var id: UUID
    var title: String
    var memo: String
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    @Relationship(deleteRule: .cascade) var attachments: [IdeaAttachment]

    init(
        id: UUID = UUID(),
        title: String,
        memo: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        tags: [String] = [],
        attachments: [IdeaAttachment] = []
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.attachments = attachments
    }

    /// 編集時に必要な値をまとめて更新
    func update(title: String, memo: String, tags: [String], attachments: [IdeaAttachment]) {
        self.title = title
        self.memo = memo
        self.tags = tags
        self.attachments = attachments
        self.updatedAt = .now
    }
}

@Model
final class IdeaAttachment {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var contentTypeIdentifier: String
    @Attribute(.externalStorage) var data: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        contentTypeIdentifier: String,
        data: Data,
        createdAt: Date = .now
    ) {
        self.id = id
        self.fileName = fileName
        self.contentTypeIdentifier = contentTypeIdentifier
        self.data = data
        self.createdAt = createdAt
    }

    var contentType: UTType? {
        UTType(contentTypeIdentifier)
    }

    var isImage: Bool {
        contentType?.conforms(to: .image) == true
    }

    var isPDF: Bool {
        contentType?.conforms(to: .pdf) == true
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }
}
