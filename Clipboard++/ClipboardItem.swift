//
//  ClipboardItem.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import Foundation
import SwiftData

/// A single entry in the clipboard history, representing either a text snippet or an image.
///
/// `ClipboardItem` is the core data model persisted by SwiftData. Each time the system
/// clipboard changes, a new item is inserted into the store. Items can be pinned to keep
/// them at the top of the list indefinitely and are otherwise pruned once the history
/// exceeds 50 unpinned entries.
@Model
final class ClipboardItem {
    /// A stable unique identifier for this item.
    var id: UUID

    /// The raw text content. Empty string for image items.
    var content: String

    /// PNG-encoded image data. `nil` for text items.
    /// Images are capped at 10 MB before being stored.
    var imageData: Data?

    /// The storage type discriminator. Either `"text"` or `"image"`.
    ///
    /// Stored as a raw `String` rather than an enum to avoid SwiftData
    /// serialisation issues with custom `Codable` types.
    var itemType: String

    /// The date and time when this item was captured from the clipboard.
    var timestamp: Date

    /// Whether the item has been pinned by the user.
    ///
    /// Pinned items always appear at the top of the list and are excluded
    /// from the automatic 50-item pruning limit.
    var isPinned: Bool

    /// Creates a text clipboard item.
    /// - Parameter content: The raw string copied to the clipboard.
    init(content: String) {
        id = UUID()
        self.content = content
        imageData = nil
        itemType = "text"
        timestamp = Date()
        isPinned = false
    }

    /// Creates an image clipboard item.
    /// - Parameter imageData: PNG-encoded bytes of the copied image.
    init(imageData: Data) {
        id = UUID()
        content = ""
        self.imageData = imageData
        itemType = "image"
        timestamp = Date()
        isPinned = false
    }

    /// `true` when this item holds image data rather than text.
    var isImage: Bool { itemType == "image" }

    /// A short display string suitable for showing in the list row.
    ///
    /// For text items this is the first 120 characters of the trimmed content.
    /// For image items this returns the literal string `"Image"`.
    var preview: String {
        isImage ? "Image" : String(content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
    }

    /// A human-readable relative time string describing when the item was captured.
    ///
    /// Examples: `"Just now"`, `"5m ago"`, `"3h ago"`, `"Yesterday"`, `"4d ago"`.
    var relativeTimestamp: String {
        let s = Date().timeIntervalSince(timestamp)
        switch s {
        case ..<10:    return "Just now"
        case ..<60:    return "\(Int(s))s ago"
        case ..<3600:  return "\(Int(s / 60))m ago"
        case ..<86400: return "\(Int(s / 3600))h ago"
        default:
            let d = Int(s / 86400)
            return d == 1 ? "Yesterday" : "\(d)d ago"
        }
    }
}
