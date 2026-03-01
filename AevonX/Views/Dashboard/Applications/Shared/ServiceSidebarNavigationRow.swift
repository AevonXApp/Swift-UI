//
//  ServiceSidebarNavigationRow.swift
//  AevonX
//
//  Protocol that sidebar sections must conform to.
//  Used by UnifiedServiceSidebar and database/service detail views.
//

import SwiftUI

// MARK: - Section Protocol

/// Protocol that sidebar sections must conform to
protocol SidebarSection: Identifiable, CaseIterable {
    var displayName: String { get }
    var icon: String { get }
}
