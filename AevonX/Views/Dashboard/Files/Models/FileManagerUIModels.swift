//
//  FileManagerUIModels.swift
//  AevonX
//
//  UI-specific models and enums for the file manager
//  These are local to the Files module, not shared with Core
//

import SwiftUI

// MARK: - File Manager UI Models

/// Breadcrumb path component for navigation display
struct PathComponent: Identifiable {
    let id = UUID()
    let name: String
    let path: String
}
