//
//  SettingsView.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import SwiftUI
import ServiceManagement

/// The macOS Settings window for Clipboard++.
///
/// Opened via Cmd+, or the gear icon in the clipboard panel footer.
/// Settings are persisted through `AppSettings` (which writes to `UserDefaults`),
/// except for Launch at Login which reads and writes `SMAppService.mainApp` directly
/// since the system state is the canonical source of truth.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    /// Mirrors `SMAppService.mainApp.status`. Kept as local `@State` rather than in
    /// `AppSettings` to avoid split-brain with System Settings.app.
    @State private var launchAtLogin = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        if enabled {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }

                Picker("History Limit", selection: $settings.historyLimit) {
                    Text("25 items").tag(25)
                    Text("50 items").tag(50)
                    Text("100 items").tag(100)
                    Text("200 items").tag(200)
                }
            }

            Section("Privacy") {
                Toggle("Pause Monitoring", isOn: $settings.pauseMonitoring)
            }

            Section("Behavior") {
                Toggle("Sound on Copy", isOn: $settings.soundOnCopy)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
        .onAppear {
            // Always read the live system state so this reflects changes the user
            // may have made directly in System Settings → General → Login Items.
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
