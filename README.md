# Clipboard++

A lightweight macOS menu bar app that keeps a searchable history of everything you copy, with support for pinning snippets, image previews, and configurable settings.

## Features

- **Clipboard history** — automatically captures text and images as you copy, keeping up to 200 entries (configurable)
- **Image previews** — screenshots and copied images are displayed as full-width card previews so you can see exactly what you copied
- **Live search** — filter your history instantly as you type
- **Pinned snippets** — pin any item to keep it at the top of the list permanently, outside the history limit
- **Settings** — configure launch at login, history limit, pause monitoring, and sound on copy
- **Clean design** — frosted glass panel that follows your system appearance (light and dark mode)
- **Lightweight** — lives entirely in the menu bar with no Dock icon

## Requirements

- macOS 26.4 or later
- Xcode 26.4 or later (to build from source)

## Installation

Clone the repo and open the Xcode project:

```bash
git clone https://github.com/Motyeb/ClipboardPlusPlus.git
cd ClipboardPlusPlus
open Clipboard++.xcodeproj
```

Build and run with **Cmd+R**. The app will appear as a clipboard icon in your menu bar.

## Usage

| Action | How |
|--------|-----|
| Open panel | Click the clipboard icon in the menu bar |
| Close panel | Click the icon again, or click anywhere outside the panel |
| Copy an item | Click any row — content is copied and the panel closes |
| Pin an item | Hover over a row and click the pin icon |
| Delete an item | Hover over a row and click the trash icon |
| Search | Type in the search bar at the top of the panel |
| Filter pinned | Select the **Pinned** tab |
| Clear all history | Click **Clear All** in the footer |
| Open settings | Click the gear icon in the footer, or right-click the menu bar icon |
| Quit | Click **Quit** in the footer, or right-click the menu bar icon → Quit |

### Right-click menu

Right-clicking the menu bar icon shows a context menu with:
- **Settings...** — opens the settings window
- **Quit Clipboard++** — exits the app

## Settings

| Setting | Description |
|---------|-------------|
| Launch at Login | Start Clipboard++ automatically when you log in |
| History Limit | Maximum number of unpinned items to retain (25, 50, 100, or 200) |
| Pause Monitoring | Temporarily stop capturing new clipboard content |
| Sound on Copy | Play a sound when pasting an item from history |

## Project Structure

```
Clipboard++/
├── Clipboard__App.swift      — App entry point, @NSApplicationDelegateAdaptor wiring
├── AppDelegate.swift         — NSStatusItem, NSPanel, right-click context menu, window management
├── AppSettings.swift         — User settings, persisted to UserDefaults
├── ClipboardItem.swift       — SwiftData model (text + image items, pin state, timestamps)
├── ClipboardManager.swift    — NSPasteboard polling, history management, persistence
├── ContentView.swift         — Main panel UI (search, tabs, sectioned list, footer)
├── ClipboardItemRow.swift    — Individual row with image card preview or text preview
└── SettingsView.swift        — Settings window (launch at login, history limit, etc.)
```

## Architecture

- **SwiftUI + SwiftData** — declarative UI and persistence, no third-party dependencies
- **`@Observable`** — fine-grained reactivity; only views that read `items` re-render on change
- **NSStatusItem + NSPanel** — custom AppKit status item gives full control over left-click (toggle panel) and right-click (context menu); borderless `.nonactivatingPanel` hosts the SwiftUI content view without stealing focus from other apps
- **NSPasteboard polling** — checks `changeCount` every 0.5 s on the `.common` RunLoop mode so the timer keeps firing while the panel is open
- **`SMAppService`** — modern launch-at-login API (macOS 13+), no helper bundle required
- **App Sandbox enabled** — `NSPasteboard.general` access requires no special entitlements

## License

MIT
