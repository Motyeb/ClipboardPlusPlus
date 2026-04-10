//
//  Clipboard__App.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import SwiftUI
import SwiftData

/// The application entry point.
///
/// `Clipboard__App` configures the SwiftData persistence stack, creates the shared
/// `ClipboardManager`, and presents the app as a `MenuBarExtra` — a panel that appears
/// when the user clicks the clipboard icon in the macOS menu bar.
///
/// Using `MenuBarExtra` as the sole scene means macOS automatically suppresses the
/// Dock icon; no `LSUIElement` plist key is required.
@main
struct Clipboard__App: App {
    /// The SwiftData container that owns the on-disk SQLite store.
    ///
    /// Constructed eagerly in `init()` so that `mainContext` is available before any
    /// view is rendered. The store is located in the app's sandboxed
    /// `~/Library/Application Support/` directory.
    private let container: ModelContainer

    /// The shared clipboard monitor, injected into the view hierarchy via the environment.
    @State private var manager: ClipboardManager

    init() {
        let schema = Schema([ClipboardItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let c = try! ModelContainer(for: schema, configurations: [config])
        container = c
        _manager = State(initialValue: ClipboardManager(modelContext: c.mainContext))
    }

    var body: some Scene {
        /// The `.window` style renders the content as a floating panel rather than a
        /// native pull-down menu, giving full SwiftUI layout control over the UI.
        MenuBarExtra("Clipboard++", systemImage: "doc.on.clipboard") {
            ContentView()
                .environment(manager)
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
    }
}
