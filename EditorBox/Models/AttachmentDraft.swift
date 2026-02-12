//
//  AttachmentDraft.swift
//  EditorBox
//
//  Created by Kei Tanaka on 2026/02/12.
//

import Foundation
import UniformTypeIdentifiers

struct AttachmentDraft: Identifiable {
    let id: UUID
    var fileName: String
    var contentTypeIdentifier: String
    var data: Data
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

    init(from attachment: IdeaAttachment) {
        self.id = UUID()
        self.fileName = attachment.fileName
        self.contentTypeIdentifier = attachment.contentTypeIdentifier
        self.data = attachment.data
        self.createdAt = attachment.createdAt
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
