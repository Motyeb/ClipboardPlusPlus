# Clipboard++

A macOS menu bar clipboard manager built with SwiftUI and SwiftData.

## GitHub Repository

https://github.com/Motyeb/ClipboardPlusPlus

## Project Structure

- `Clipboard++/AppDelegate.swift` — NSStatusItem, NSPanel management, lifecycle
- `Clipboard++/ContentView.swift` — Main panel UI (search, tabs, list)
- `Clipboard++/ClipboardManager.swift` — NSPasteboard polling and SwiftData persistence
- `Clipboard++/ClipboardItem.swift` — SwiftData model
- `Clipboard++/ClipboardItemRow.swift` — Row UI with preview and action buttons
- `Clipboard++/AppSettings.swift` — UserDefaults-backed settings
- `Clipboard++/SettingsView.swift` — Settings panel UI

## Notes

- The Xcode project lives inside `Clipboard++/Clipboard++.xcodeproj`; the Swift sources are in `Clipboard++/Clipboard++/` (nested). Git tracks the outer `Clipboard++/` copies — apply changes to both when editing.
- The panel uses `KeyablePanel` (NSPanel subclass with `canBecomeKey = true`) + `makeKeyAndOrderFront` so the search TextField receives keyboard input while keeping `.nonactivatingPanel` behaviour.
