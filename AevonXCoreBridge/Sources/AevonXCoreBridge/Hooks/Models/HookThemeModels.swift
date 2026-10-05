//
//  HookThemeModels.swift
//  AevonXCoreBridge
//
//  Plugin theming system — allows each plugin to define its own visual identity.
//  This ensures plugins look unique and don't share the same generic style.
//
//  Usage in hook.json or _manifest.json:
//  {
//      "theme": {
//          "accent_color": "purple",
//          "style": "neon",
//          "density": "compact",
//          "header_style": "hero"
//      }
//  }
//

import Foundation

// MARK: - Theme Definition

/// Theme configuration for a plugin — allows per-plugin visual identity.
/// Can be defined at manifest level (applies to all hooks) or layout level (per-page).
public struct HookTheme: Codable, Sendable {
    /// Primary accent color — supports named colors, hex (#FF5722), and gradients ("gradient:blue,purple")
    public let accentColor: String?

    /// Card/component style
    public let style: HookThemeStyle?

    /// Corner radius for cards — "sm" (6pt), "md" (10pt), "lg" (14pt), "xl" (20pt)
    public let cardRadius: String?

    /// Content density — affects spacing between elements
    public let density: HookThemeDensity?

    /// Header rendering style
    public let headerStyle: HookHeaderStyle?

    /// Border treatment for cards and components
    public let borderStyle: HookBorderStyle?

    /// Animation style for interactive elements
    public let animationStyle: HookAnimationStyle?

    /// Color scheme overrides
    public let colorScheme: HookColorScheme?

    enum CodingKeys: String, CodingKey {
        case style, density
        case accentColor    = "accent_color"
        case cardRadius     = "card_radius"
        case headerStyle    = "header_style"
        case borderStyle    = "border_style"
        case animationStyle = "animation_style"
        case colorScheme    = "color_scheme"
    }
}

// MARK: - Theme Style

/// Visual style for card/component backgrounds
public enum HookThemeStyle: String, Codable, Sendable {
    case glassmorphic = "glassmorphic"   // Default — blurred translucent background
    case solid        = "solid"          // Opaque solid background
    case outlined     = "outlined"       // Transparent with border
    case gradient     = "gradient"       // Gradient background
    case neon         = "neon"           // Dark background with glowing accent borders
    case minimal      = "minimal"        // Ultra-clean, almost no decoration
    case elevated     = "elevated"       // Subtle shadow and elevation
}

// MARK: - Content Density

/// Controls spacing between UI elements
public enum HookThemeDensity: String, Codable, Sendable {
    case compact  = "compact"    // Tight spacing — maximizes content
    case normal   = "normal"     // Default spacing
    case spacious = "spacious"   // Large spacing — focus/readability
}

// MARK: - Header Style

/// How the plugin header is rendered
public enum HookHeaderStyle: String, Codable, Sendable {
    case banner   = "banner"     // Full-width hero banner with gradient
    case compact  = "compact"    // Single-line compact header
    case minimal  = "minimal"    // Just the title, no decoration
    case hero     = "hero"       // Large hero with icon and description
}

// MARK: - Border Style

/// Border treatment for cards
public enum HookBorderStyle: String, Codable, Sendable {
    case none    = "none"        // No border
    case subtle  = "subtle"      // Thin, low-opacity border
    case accent  = "accent"      // Colored border using accent color
    case glow    = "glow"        // Accent-colored glow effect
}

// MARK: - Animation Style

/// Animation intensity for interactive elements
public enum HookAnimationStyle: String, Codable, Sendable {
    case none    = "none"        // No animations
    case subtle  = "subtle"      // Minimal micro-interactions
    case dynamic = "dynamic"     // Full animations and transitions
}

// MARK: - Color Scheme

/// Per-plugin color overrides — allows complete control over the plugin's palette
public struct HookColorScheme: Codable, Sendable {
    public let primary: String?      // Primary action color
    public let secondary: String?    // Secondary action color
    public let success: String?      // Success states
    public let warning: String?      // Warning states
    public let danger: String?       // Danger/error states
    public let info: String?         // Informational states
    public let surface: String?      // Card/component surface color
    public let text: String?         // Primary text color
    public let textSecondary: String? // Secondary text color

    enum CodingKeys: String, CodingKey {
        case primary, secondary, success, warning, danger, info, surface, text
        case textSecondary = "text_secondary"
    }
}
