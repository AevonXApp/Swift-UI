import Foundation

/// Centralized localization namespace.
/// Each sub-enum maps to a .strings file via `table:` parameter.
///
/// Runtime behavior:
/// - Only the active language's .lproj is loaded
/// - Each .strings file loads lazily on first access
/// - Compiled into binary — zero overhead vs hardcoded strings
///
/// Usage:
///   Text(L10n.Button.cancel)           // → Shared.strings
///   Text(L10n.Error.timeout)           // → Errors.strings
///   Text(L10n.Docker.newContainer)     // → Docker.strings
enum L10n {
    // Sub-namespaces defined in L10n+*.swift extensions
}
