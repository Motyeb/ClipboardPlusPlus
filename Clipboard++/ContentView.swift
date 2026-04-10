//
//  ContentView.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import SwiftUI

/// The root view of the menu bar panel.
///
/// `ContentView` composes the full panel UI:
/// - A live search bar that filters history by text content
/// - A segmented tab picker to switch between all items and pinned items only
/// - A scrollable, sectioned list of ``ClipboardItemRow`` entries
/// - A footer showing the total item count and a "Clear All" button
///
/// The view reads `ClipboardManager` from the SwiftUI environment and derives
/// `filtered`, `pinnedItems`, and `recentItems` as computed properties so the
/// list stays in sync with any changes the manager publishes.
struct ContentView: View {
    @Environment(ClipboardManager.self) private var manager

    /// The current text entered in the search field.
    @State private var searchText = ""

    /// Which tab is selected: all items or pinned items only.
    @State private var selectedTab: Tab = .all

    /// Tabs available in the segmented picker.
    enum Tab { case all, pinned }

    /// Items from the manager that match the current tab selection and search query.
    ///
    /// Image items always pass the search filter since they have no searchable text.
    var filtered: [ClipboardItem] {
        let source = selectedTab == .pinned ? manager.items.filter(\.isPinned) : manager.items
        guard !searchText.isEmpty else { return source }
        return source.filter { $0.isImage || $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    /// The subset of `filtered` that are pinned.
    var pinnedItems: [ClipboardItem] { filtered.filter(\.isPinned) }

    /// The subset of `filtered` that are not pinned.
    var recentItems: [ClipboardItem] { filtered.filter { !$0.isPinned } }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            tabPicker
            Divider()

            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        if selectedTab == .all {
                            if !pinnedItems.isEmpty {
                                Section {
                                    ForEach(pinnedItems) { item in
                                        ClipboardItemRow(item: item)
                                    }
                                } header: {
                                    sectionHeader("Pinned", icon: "pin.fill")
                                }
                            }
                            if !recentItems.isEmpty {
                                Section {
                                    ForEach(recentItems) { item in
                                        ClipboardItemRow(item: item)
                                    }
                                } header: {
                                    if !pinnedItems.isEmpty {
                                        sectionHeader("Recent", icon: "clock")
                                    }
                                }
                            }
                        } else {
                            ForEach(filtered) { item in
                                ClipboardItemRow(item: item)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()
            footer
        }
        .frame(width: 340, height: 480)
        .background(.regularMaterial)
    }

    // MARK: - Subviews

    /// A search field with a leading magnifying-glass icon and a clear button.
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search clipboard...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// A segmented control for switching between the All and Pinned tabs.
    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            Text("All").tag(Tab.all)
            Text("Pinned").tag(Tab.pinned)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    /// A sticky section header with an SF Symbol icon and an uppercased title.
    ///
    /// Rendered using `.regularMaterial` so it remains legible as rows scroll beneath it.
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(title.uppercased()).font(.caption2).fontWeight(.semibold)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.regularMaterial)
    }

    /// A centred placeholder shown when there are no items matching the current filter.
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(searchText.isEmpty ? "Nothing copied yet" : "No results")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    /// A toolbar at the bottom of the panel showing the item count and a "Clear All" button.
    private var footer: some View {
        HStack {
            Text("\(manager.items.count) item\(manager.items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Clear All") { manager.deleteAll() }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(manager.items.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
