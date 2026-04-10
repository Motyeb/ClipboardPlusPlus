//
//  ClipboardManager.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import AppKit
import SwiftData
import Observation

/// The central controller for clipboard history.
///
/// `ClipboardManager` polls `NSPasteboard.general` every 0.5 seconds, detects changes
/// via `changeCount`, and persists new items using SwiftData. It is injected into the
/// SwiftUI environment at the app level so all views share a single source of truth.
///
/// The in-memory `items` array is always kept sorted with pinned entries first,
/// then unpinned entries in reverse-chronological order. The unpinned history is
/// capped at the value configured in `AppSettings.historyLimit`; older items are
/// automatically deleted.
@Observable
final class ClipboardManager {
    private var modelContext: ModelContext
    private let settings: AppSettings
    private var timer: Timer?

    /// The last observed `NSPasteboard.changeCount`. Used to detect new clipboard content
    /// and to prevent re-capturing items that were written by the app itself.
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    /// The current clipboard history, sorted pinned-first then newest-first.
    ///
    /// Views that read this property are automatically re-rendered when it changes,
    /// thanks to the `@Observable` macro.
    var items: [ClipboardItem] = []

    /// Creates a manager and begins monitoring the clipboard.
    /// - Parameters:
    ///   - modelContext: The SwiftData context used for persistence.
    ///     Pass `ModelContainer.mainContext` from the app entry point.
    ///   - settings: The shared app settings. The manager reads `pauseMonitoring`,
    ///     `historyLimit`, and `soundOnCopy` at call time rather than subscribing to
    ///     changes, so no extra wiring is needed.
    init(modelContext: ModelContext, settings: AppSettings) {
        self.modelContext = modelContext
        self.settings = settings
        loadItems()
        startPolling()
    }

    deinit { timer?.invalidate() }

    // MARK: - Polling

    /// Schedules a repeating timer on the `.common` RunLoop mode.
    ///
    /// `.common` is critical here — the default `.default` mode pauses timers while
    /// the user is interacting with menus or scrolling, which would cause clipboard
    /// changes made while the panel is open to be missed.
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// Checks whether the pasteboard has changed and inserts a new item if so.
    ///
    /// Image content is checked before text because most screenshot operations write
    /// both an image and an associated filename string to the pasteboard — prioritising
    /// the image type gives a more accurate capture.
    ///
    /// Monitoring can be paused via `AppSettings.pauseMonitoring`; the timer keeps
    /// running so that capturing resumes immediately when the toggle is turned off.
    private func checkPasteboard() {
        guard !settings.pauseMonitoring else { return }

        let current = NSPasteboard.general.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        let pb = NSPasteboard.general

        // Check for image content first (screenshots, photos, etc.)
        if let image = NSImage(pasteboard: pb),
           let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            guard png.count < 10 * 1024 * 1024 else { return } // skip images >10 MB
            // Avoid storing an identical image twice in a row
            if let top = items.first(where: { !$0.isPinned }), top.isImage, top.imageData == png { return }
            insert(ClipboardItem(imageData: png))
            return
        }

        // Fall back to plain text
        guard let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Avoid storing identical text twice in a row
        if let top = items.first(where: { !$0.isPinned && !$0.isImage }), top.content == text { return }

        insert(ClipboardItem(content: text))
    }

    /// Persists a new item, updates the in-memory array, and enforces the history limit.
    private func insert(_ item: ClipboardItem) {
        modelContext.insert(item)
        items.insert(item, at: pinnedCount)
        pruneHistory()
        try? modelContext.save()
    }

    /// The number of currently pinned items. Used as the insertion index so that new
    /// unpinned items appear immediately after all pinned items.
    private var pinnedCount: Int { items.filter(\.isPinned).count }

    /// Removes the oldest unpinned items if the history exceeds the configured limit.
    private func pruneHistory() {
        let limit = settings.historyLimit
        let unpinned = items.filter { !$0.isPinned }
        guard unpinned.count > limit else { return }
        let toRemove = Array(unpinned.suffix(unpinned.count - limit))
        let ids = Set(toRemove.map(\.persistentModelID))
        toRemove.forEach { modelContext.delete($0) }
        items.removeAll { ids.contains($0.persistentModelID) }
    }

    // MARK: - Actions

    /// Fetches all items from SwiftData and re-sorts them into `items`.
    ///
    /// Called on startup and after any operation that changes sort order (e.g. pin/unpin).
    /// Also enforces the current history limit so that reducing the limit in settings
    /// takes effect on the next app launch without requiring a clipboard event.
    func loadItems() {
        let descriptor = FetchDescriptor<ClipboardItem>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        items = fetched.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.timestamp > $1.timestamp
        }
        pruneHistory()
    }

    /// Writes the item's content back to the system clipboard.
    ///
    /// After writing, `lastChangeCount` is updated to the new pasteboard change count
    /// so that the next poll does not re-capture the value the app just wrote.
    /// - Parameter item: The clipboard item to copy.
    func copyItem(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        if item.isImage, let data = item.imageData, let image = NSImage(data: data) {
            NSPasteboard.general.writeObjects([image])
        } else {
            NSPasteboard.general.setString(item.content, forType: .string)
        }
        lastChangeCount = NSPasteboard.general.changeCount
        if settings.soundOnCopy { NSSound.beep() }
    }

    /// Toggles the pinned state of an item and reloads the sorted list.
    /// - Parameter item: The item to pin or unpin.
    func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
        try? modelContext.save()
        loadItems()
    }

    /// Deletes a single item from both the store and the in-memory array.
    /// - Parameter item: The item to delete.
    func deleteItem(_ item: ClipboardItem) {
        modelContext.delete(item)
        items.removeAll { $0.persistentModelID == item.persistentModelID }
        try? modelContext.save()
    }

    /// Deletes all clipboard history items from both the store and the in-memory array.
    func deleteAll() {
        items.forEach { modelContext.delete($0) }
        items = []
        try? modelContext.save()
    }
}
