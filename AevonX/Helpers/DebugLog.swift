import Foundation

/// Debug-only logging — compiles to zero code in Release builds.
@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}
