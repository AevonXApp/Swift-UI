//
//  BridgeHelpers.swift
//  AevonXCoreBridge
//
//  Shared helpers for CGo bridge wrappers.
//  Prevents strdup memory leaks by managing C string lifecycles.
//

import Foundation

/// Manages strdup allocations and frees them when the scope exits.
/// Usage:
/// ```
/// let c = CArgs()
/// let result = extract(GoFunc(c.str(arg1), c.str(arg2)))
/// // All strdup'd pointers freed automatically when `c` goes out of scope
/// ```
@usableFromInline
final class CArgs {
    @usableFromInline var ptrs: [UnsafeMutablePointer<CChar>] = []

    @usableFromInline
    init() {}

    /// Duplicates a Swift string into C memory, tracking it for automatic cleanup.
    @inlinable
    func str(_ s: String) -> UnsafeMutablePointer<CChar>? {
        guard let p = strdup(s) else { return nil }
        ptrs.append(p)
        return p
    }

    deinit {
        for p in ptrs { free(p) }
    }
}

/// Calls a closure with a mutable C string pointer.
/// Go's CGo exports declare `char*` (mutable) instead of `const char*`,
/// so `withCString` (which provides `UnsafePointer`) causes type errors.
extension String {
    @inlinable
    func withMutableCString<R>(_ body: (UnsafeMutablePointer<CChar>) throws -> R) rethrows -> R {
        try withCString { ptr in
            try body(UnsafeMutablePointer(mutating: ptr))
        }
    }
}

/// Executes a closure with a CArgs scope, ensuring all strdup'd strings are freed.
/// Use this when ARC lifetime is uncertain (e.g., closures, async).
@inlinable
func withCArgs<T>(_ body: (CArgs) -> T) -> T {
    let c = CArgs()
    let result = body(c)
    withExtendedLifetime(c) {}
    return result
}

/// Throwing overload of withCArgs for bridge methods that parse JSON responses.
@inlinable
func withCArgs<T>(_ body: (CArgs) throws -> T) throws -> T {
    let c = CArgs()
    let result = try body(c)
    withExtendedLifetime(c) {}
    return result
}
