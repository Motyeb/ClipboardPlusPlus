//
//  AppDelegate.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import AppKit
import SwiftUI
import SwiftData

/// The application delegate that manages the status item, floating panel, and context menu.
///
/// Because `MenuBarExtra(.window)` does not expose the underlying `NSStatusItem`,
/// right-click behaviour cannot be configured in pure SwiftUI. `AppDelegate` replaces
/// the `MenuBarExtra` scene with a custom `NSStatusItem` + borderless `NSPanel`,
/// giving full control over both left-click (toggle panel) and right-click (context menu).
///
/// `AppSettings` is initialised as a stored property so it exists before
/// `applicationDidFinishLaunching` runs, allowing the SwiftUI `Settings` scene in
/// `Clipboard__App` to access `appDelegate.settings` at body-computation time.
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Shared State

    /// Accessible from SwiftUI views without going through `NSApp.delegate`, which
    /// may return a SwiftUI wrapper rather than this class when using
    /// `@NSApplicationDelegateAdaptor`.
    static weak var shared: AppDelegate?

    /// User-configurable settings. Non-optional; initialised at declaration time.
    let settings = AppSettings()

    private var container: ModelContainer!
    private var manager: ClipboardManager!

    // MARK: - UI

    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var settingsWindow: NSWindow?
    private var clickOutsideMonitor: Any?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Suppress Dock icon — equivalent to setting LSUIElement = YES in Info.plist.
        // Must be called before any windows are shown.
        NSApp.setActivationPolicy(.accessory)

        // SwiftData persistence stack
        let schema = Schema([ClipboardItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: [config])
        manager = ClipboardManager(modelContext: container.mainContext, settings: settings)

        setupPanel()
        setupStatusItem()
    }

    // MARK: - Panel

    /// Builds the borderless floating panel that hosts the SwiftUI content view.
    ///
    /// The panel uses `.nonactivatingPanel` so it never steals key-window status from
    /// other apps. Level is `.popUpMenu` so it appears above normal application windows.
    private func setupPanel() {
        let hostingView = NSHostingView(rootView:
            ContentView()
                .environment(manager)
                .environment(settings)
                .modelContainer(container)
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 340, height: 480)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 480),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.level = .popUpMenu
        panel.hasShadow = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
    }

    /// Positions the panel directly below the status item button and shows it.
    func showPanel() {
        if let button = statusItem.button,
           let buttonWindow = button.window {
            let buttonFrame = buttonWindow.convertToScreen(button.frame)
            let panelWidth: CGFloat = 340
            let panelHeight: CGFloat = 480

            var x = buttonFrame.midX - panelWidth / 2
            let y = buttonFrame.minY - panelHeight - 4   // 4 pt gap below the menu bar

            // Clamp horizontally so the panel stays fully on-screen.
            if let screen = NSScreen.main {
                x = min(x, screen.visibleFrame.maxX - panelWidth)
                x = max(x, screen.visibleFrame.minX)
            }
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        installClickOutsideMonitor()
    }

    /// Hides the panel and tears down the global click monitor.
    func closePanel() {
        panel.orderOut(nil)
        removeClickOutsideMonitor()
    }

    /// Toggles the panel's visibility.
    private func togglePanel() {
        panel.isVisible ? closePanel() : showPanel()
    }

    // MARK: - Click-outside Monitor

    /// Installs a global event monitor that closes the panel when the user clicks
    /// anywhere outside of it (but not on the status item button itself).
    private func installClickOutsideMonitor() {
        guard clickOutsideMonitor == nil else { return }

        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self, self.panel.isVisible else { return }
            let loc = NSEvent.mouseLocation

            // Ignore clicks on the status item button — statusButtonClicked handles those.
            if let button = self.statusItem.button,
               let win = button.window {
                if win.convertToScreen(button.frame).contains(loc) { return }
            }

            if !self.panel.frame.contains(loc) {
                self.closePanel()
            }
        }
    }

    private func removeClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    // MARK: - Status Item

    /// Creates the menu-bar status item and configures it to respond to both
    /// left-click (toggle panel) and right-click (context menu).
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "Clipboard++"
        )
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.button?.action = #selector(statusButtonClicked(_:))
        statusItem.button?.target = self
    }

    @objc private func statusButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    // MARK: - Context Menu

    /// Displays a native context menu below the status item with Settings and Quit options.
    ///
    /// The recommended approach: temporarily assign the menu to the status item and
    /// call `performClick` to trigger native display. The menu is cleared on the next
    /// runloop tick so that future left-clicks resume calling `statusButtonClicked`.
    private func showContextMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Clipboard++",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { self.statusItem.menu = nil }
    }

    /// Opens the Settings window and closes the content panel.
    ///
    /// `NSApp.sendAction(Selector(("showSettingsWindow:")), ...)` requires the app to be
    /// active, which it is not when the panel is a `.nonactivatingPanel`. Managing the
    /// window directly with `NSHostingController` is more reliable and avoids depending
    /// on SwiftUI's private `showSettingsWindow:` responder-chain action.
    @objc func openSettings() {
        closePanel()

        if settingsWindow == nil {
            let controller = NSHostingController(
                rootView: SettingsView().environment(settings)
            )
            let window = NSWindow(contentViewController: controller)
            window.title = "Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
