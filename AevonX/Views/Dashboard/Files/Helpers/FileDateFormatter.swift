//
//  FileDateFormatter.swift
//  AevonX
//
//  Relative date formatting for file modification dates
//

import Foundation

// MARK: - File Date Formatter

/// Format a date as a relative string (e.g., "2h ago", "3d ago")
func formatFileDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}
