# Clipboard++

A lightweight macOS menu bar app that keeps a searchable history of everything you copy, with support for pinning snippets and images.

## Features

- **Clipboard history** — automatically captures text and images as you copy, keeping the last 50 entries
- **Image support** — screenshots and copied images are stored as thumbnails and can be re-copied with a single click
- **Live search** — filter your history instantly as you type
- **Pinned snippets** — pin any item to keep it at the top of the list permanently, outside the 50-item limit
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
| Copy an item | Click any row — content is copied and the panel closes |
| Pin an item | Hover over a row and click the pin icon |
| Delete an item | Hover over a row and click the trash icon |
| Search | Type in the search bar at the top of the panel |
| Filter pinned | Select the **Pinned** tab |
| Clear all history | Click **Clear All** in the footer |

## Project Structure

```
Clipboard++/
├── Clipboard__App.swift      — App entry point, MenuBarExtra scene, SwiftData setup
├── ClipboardItem.swift       — SwiftData model (text + image items, pin state, timestamps)
├── ClipboardManager.swift    — NSPasteboard polling, history management, persistence
├── ContentView.swift         — Main panel UI (search, tabs, sectioned list, footer)
└── ClipboardItemRow.swift    — Individual row with thumbnail/preview and hover actions
```

## Architecture

- **SwiftUI + SwiftData** — declarative UI and persistence, no third-party dependencies
- **`@Observable`** — fine-grained reactivity; only views that read `items` re-render on change
- **NSPasteboard polling** — checks `changeCount` every 0.5 s on the `.common` RunLoop mode so the timer keeps firing while the panel is open
- **App Sandbox enabled** — `NSPasteboard.general` access requires no special entitlements

## License

MIT
