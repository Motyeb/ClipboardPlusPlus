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
/// `ClipboardManager` and `AppSettings`, and presents the app as a `MenuBarExtra` —
/// a panel that appears when the user clicks the clipboard icon in the macOS menu bar.
///
/// A `Settings` scene is also included, which adds Cmd+, support and a standard
/// macOS Settings window accessible from the app menu or the gear icon in the panel.
///
/// Using `MenuBarExtra` as the sole visible scene means macOS automatically suppresses
/// the Dock icon; no `LSUIElement` plist key is required.
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

    /// The shared user settings, injected into both the view hierarchy and the manager.
    @State private var settings: AppSettings

    init() {
        let schema = Schema([ClipboardItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let c = try! ModelContainer(for: schema, configurations: [config])
        container = c
        let s = AppSettings()
        _settings = State(initialValue: s)
        _manager = State(initialValue: ClipboardManager(modelContext: c.mainContext, settings: s))
    }

    var body: some Scene {
        /// The `.window` style renders the content as a floating panel rather than a
        /// native pull-down menu, giving full SwiftUI layout control over the UI.
        MenuBarExtra("Clipboard++", systemImage: "doc.on.clipboard") {
            ContentView()
                .environment(manager)
                .environment(settings)
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)

        /// Standard macOS Settings window. Accessible via Cmd+, or the gear icon
        /// in the panel footer. `openSettings` environment action handles the rest.
        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}
