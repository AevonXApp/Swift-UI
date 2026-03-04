//
//  LayoutConstants.swift
//  AevonX
//
//  Centralized layout constants for consistent sizing across views.
//  Replaces hardcoded numeric values to improve maintainability (L6).
//

import SwiftUI

// MARK: - Layout Constants

/// Centralized layout constants for consistent sizing across the app.
///
/// Use these constants instead of hardcoded numeric values in `.frame()`.
/// This makes it easy to adjust sizes globally and ensures consistency.
///
/// **Usage**:
/// ```swift
/// .frame(width: LayoutConstants.sidebarWidth)
/// .frame(width: LayoutConstants.TableColumn.standard)
/// ```
public enum LayoutConstants {
    
    // MARK: - Sidebar & Navigation
    
    /// Default sidebar width for dashboard views
    public static let sidebarWidth: CGFloat = 280
    
    /// Collapsed sidebar icon column width
    public static let sidebarCollapsedWidth: CGFloat = 60
    
    // MARK: - Table Column Widths
    
    /// Column widths for table layouts
    public enum TableColumn {
        /// Narrow column (icon, status indicator)
        public static let narrow: CGFloat = 50
        
        /// Status column (status badges)
        public static let status: CGFloat = 60
        
        /// Small label column
        public static let smallLabel: CGFloat = 70
        
        /// Medium column (names, types)
        public static let medium: CGFloat = 100
        
        /// Standard column (most text columns)
        public static let standard: CGFloat = 120
        
        /// Wide column (names, paths, descriptions)
        public static let wide: CGFloat = 150
        
        /// Full name column
        public static let fullName: CGFloat = 200
        
        /// Action buttons column
        public static let actions: CGFloat = 80
    }
    
    // MARK: - Icon Sizes
    
    /// Standard icon sizes
    public enum IconSize {
        /// Tiny icon (status indicators)
        public static let tiny: CGFloat = 8
        
        /// Small icon (inline with text)
        public static let small: CGFloat = 16
        
        /// Navigation icon
        public static let navigation: CGFloat = 24
        
        /// Button icon
        public static let button: CGFloat = 28
        
        /// Feature icon
        public static let feature: CGFloat = 32
        
        /// Large icon (empty states, headers)
        public static let large: CGFloat = 40
        
        /// Extra large icon (hero sections)
        public static let extraLarge: CGFloat = 56
    }
    
    // MARK: - Dialog & Sheet Sizes
    
    /// Standard dialog/sheet dimensions
    public enum Dialog {
        /// Small dialog
        public static let small = CGSize(width: 400, height: 300)
        
        /// Medium dialog
        public static let medium = CGSize(width: 500, height: 400)
        
        /// Large dialog
        public static let large = CGSize(width: 600, height: 500)
        
        /// Plugin marketplace preview
        public static let marketplace = CGSize(width: 800, height: 600)
    }
    
    // MARK: - Input & Controls
    
    /// Input field widths
    public enum Input {
        /// Short input (port numbers, codes)
        public static let short: CGFloat = 80
        
        /// Medium input (names, labels)
        public static let medium: CGFloat = 200
        
        /// Long input (paths, URLs)
        public static let long: CGFloat = 300
    }
}
