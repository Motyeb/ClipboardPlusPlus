//
//  ClipboardItemRow.swift
//  Clipboard++
//
//  Created by Thomas Sheppard on 10/04/2026.
//

import SwiftUI
import AppKit

/// A single row in the clipboard history list.
///
/// The row displays either an image thumbnail (for image items) or a two-line text
/// preview (for text items), along with a relative timestamp.
///
/// On hover, two action buttons animate in from the trailing edge:
/// - **Pin / Unpin** — moves the item to or from the Pinned section.
/// - **Delete** — removes the item from history immediately.
///
/// Tapping anywhere on the row copies the item's content back to the system clipboard
/// and closes the menu bar panel.
struct ClipboardItemRow: View {
    /// The clipboard history entry this row represents.
    let item: ClipboardItem

    @Environment(ClipboardManager.self) private var manager

    /// Tracks whether the cursor is currently over this row, used to show action buttons.
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            itemContent
            if isHovered { actionButtons }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        )
        .padding(.horizontal, 6)
        .contentShape(Rectangle()) // ensures the full row area is tappable
        .onHover { isHovered = $0 }
        .onTapGesture {
            manager.copyItem(item)
            // Close the MenuBarExtra panel. The panel is the key window while open,
            // so closing it dismisses the floating window without hiding the status icon.
            NSApp.keyWindow?.close()
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    // MARK: - Subviews

    /// Renders a thumbnail + label for images, or a text preview for text items.
    @ViewBuilder
    private var itemContent: some View {
        if item.isImage, let data = item.imageData, let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 3) {
                Text("Image")
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.relativeTimestamp)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.relativeTimestamp)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// The pin and delete buttons that appear on hover, with a fade+scale transition.
    private var actionButtons: some View {
        HStack(spacing: 6) {
            actionButton(
                icon: item.isPinned ? "pin.slash.fill" : "pin.fill",
                color: item.isPinned ? .orange : .secondary
            ) {
                manager.togglePin(item)
            }
            actionButton(icon: "trash", color: .red) {
                manager.deleteItem(item)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }

    /// A small icon button used for the pin and delete actions.
    /// - Parameters:
    ///   - icon: The SF Symbol name.
    ///   - color: The foreground tint applied to the icon.
    ///   - action: The closure called when the button is tapped.
    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
