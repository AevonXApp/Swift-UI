import Foundation
import IOKit
import CryptoKit

/// Utility for retrieving and hashing the Mac's hardware UUID
public actor DeviceIdentifier {
    
    public static let shared = DeviceIdentifier()
    
    private var cachedDeviceID: String?
    
    private init() {}
    
    /// Retrieves the IOPlatformUUID (Hardware UUID) and returns it as a hashed string
    /// - Returns: A SHA-256 hashed version of the device UUID for privacy
    public func getDeviceID() -> String? {
        // Return cached value if available
        if let cached = cachedDeviceID {
            return cached
        }
        
        // Get the IOPlatformUUID from the system
        guard let uuid = getIOPlatformUUID() else {
            return nil
        }
        
        // Hash the UUID for privacy and security
        let hashedID = hashDeviceUUID(uuid)
        cachedDeviceID = hashedID
        
        return hashedID
    }
    
    /// Retrieves the raw IOPlatformUUID from the system
    private func getIOPlatformUUID() -> String? {
        // Get the platform expert service
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        guard platformExpert != 0 else {
            return nil
        }
        
        defer {
            IOObjectRelease(platformExpert)
        }
        
        // Get the UUID property
        guard let uuidProperty = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            return nil
        }
        
        let uuid = uuidProperty.takeRetainedValue() as? String
        return uuid
    }
    
    /// Hashes the device UUID using SHA-256 for privacy
    private func hashDeviceUUID(_ uuid: String) -> String {
        let data = Data(uuid.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Clears the cached device ID (useful for testing)
    public func clearCache() {
        cachedDeviceID = nil
    }
}

// MARK: - Synchronous Wrapper

public extension DeviceIdentifier {
    /// Synchronous version for use in non-async contexts.
    /// Uses IOKit directly (no actor hop) to avoid semaphore + Task deadlock.
    /// - Returns: The hashed device ID or nil if unavailable
    nonisolated func getDeviceIDSync() -> String? {
        // IOKit calls are safe from any thread — no actor isolation needed
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        guard platformExpert != 0 else {
            return nil
        }
        
        defer {
            IOObjectRelease(platformExpert)
        }
        
        guard let uuidProperty = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            return nil
        }
        
        guard let uuid = uuidProperty.takeRetainedValue() as? String else {
            return nil
        }
        
        // Hash with SHA-256
        let data = Data(uuid.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
