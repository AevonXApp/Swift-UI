//
//  AXBlockActions.swift
//  AevonX
//
//  Block-level actions: copy, bookmark, collapse, re-run, context menu.
//

import SwiftUI
import AppKit

// MARK: - Block Action

enum AXBlockAction: Identifiable {
    case copyCommand
    case copyOutput
    case copyAll
    case searchInBlock
    case bookmark
    case collapse
    case rerun
    case editAndRerun
    case clearBlock

    var id: String {
        switch self {
        case .copyCommand: return "copy-cmd"
        case .copyOutput: return "copy-out"
        case .copyAll: return "copy-all"
        case .searchInBlock: return "search"
        case .bookmark: return "bookmark"
        case .collapse: return "collapse"
        case .rerun: return "rerun"
        case .editAndRerun: return "edit-rerun"
        case .clearBlock: return "clear"
        }
    }

    var label: String {
        switch self {
        case .copyCommand: return L10n.Terminal.copyCommand
        case .copyOutput: return L10n.Terminal.copyOutput
        case .copyAll: return L10n.Terminal.copyAll
        case .searchInBlock: return L10n.Terminal.searchInBlock
        case .bookmark: return L10n.Terminal.bookmark
        case .collapse: return L10n.Terminal.collapse
        case .rerun: return L10n.Terminal.rerun
        case .editAndRerun: return L10n.Terminal.editAndRerun
        case .clearBlock: return L10n.Terminal.clearBlock
        }
    }

    var icon: String {
        switch self {
        case .copyCommand: return "doc.on.clipboard"
        case .copyOutput: return "doc.plaintext"
        case .copyAll: return "doc.on.doc"
        case .searchInBlock: return "magnifyingglass"
        case .bookmark: return "bookmark"
        case .collapse: return "chevron.down"
        case .rerun: return "arrow.clockwise"
        case .editAndRerun: return "pencil"
        case .clearBlock: return "trash"
        }
    }
}

// MARK: - Clipboard Helpers

enum AXTerminalClipboard {

    static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    static func copyCommand(from block: AXTerminalBlock) {
        copyToClipboard(block.command)
    }

    static func copyOutput(from block: AXTerminalBlock) {
        copyToClipboard(block.plainOutput)
    }

    static func copyAll(from block: AXTerminalBlock) {
        let full = "$ \(block.command)\n\(block.plainOutput)"
        copyToClipboard(full)
    }
}
