//
//  Clipboard__App.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import SwiftUI

/// The application entry point.
///
/// All clipboard monitoring, SwiftData setup, status-item management, and window
/// lifecycle live in `AppDelegate`. This struct's sole responsibility is to wire
/// up the delegate adaptor.
///
/// The `Settings` scene is replaced by a direct `NSWindow` created in
/// `AppDelegate.openSettings()`, which is more reliable when the app runs as an
/// `.accessory` process (no Dock icon) with a non-activating panel.
@main
struct Clipboard__App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // A Settings scene with no content satisfies SwiftUI's requirement for at
        // least one scene while keeping the app's activation policy as .accessory.
        Settings { EmptyView() }
    }
}
