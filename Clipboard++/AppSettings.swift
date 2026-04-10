//
//  AppSettings.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import Foundation
import Observation

/// Shared user-configurable settings for Clipboard++.
///
/// `AppSettings` is an `@Observable` class that persists its values to `UserDefaults`.
/// It is constructed once in `Clipboard__App.init()` and injected into both the view
/// hierarchy (via `.environment`) and `ClipboardManager` (via its initialiser), giving
/// both the UI and the manager a single typed source of truth.
///
/// Note: `@Observable` and `@AppStorage` cannot coexist on the same stored property
/// because both require ownership of the property's backing storage. The `didSet`
/// pattern used here is the correct workaround — mutations happen on the main thread
/// (SwiftUI bindings), so no synchronisation is needed.
@Observable
final class AppSettings {

    /// The maximum number of unpinned clipboard items to retain.
    ///
    /// When a new item is inserted and this limit is exceeded, the oldest unpinned
    /// items are deleted automatically. Pinned items are never pruned.
    var historyLimit: Int {
        didSet { UserDefaults.standard.set(historyLimit, forKey: "historyLimit") }
    }

    /// When `true`, the clipboard monitor stops capturing new items.
    ///
    /// The polling timer continues to run so that monitoring resumes instantly
    /// when this is toggled back to `false`.
    var pauseMonitoring: Bool {
        didSet { UserDefaults.standard.set(pauseMonitoring, forKey: "pauseMonitoring") }
    }

    /// When `true`, the system alert sound plays each time an item is pasted from history.
    var soundOnCopy: Bool {
        didSet { UserDefaults.standard.set(soundOnCopy, forKey: "soundOnCopy") }
    }

    init() {
        let d = UserDefaults.standard
        // Guard against a previously stored value that is no longer a valid option.
        let stored = d.object(forKey: "historyLimit") as? Int ?? 50
        self.historyLimit    = [25, 50, 100, 200].contains(stored) ? stored : 50
        self.pauseMonitoring = d.bool(forKey: "pauseMonitoring")
        self.soundOnCopy     = d.bool(forKey: "soundOnCopy")
    }
}
