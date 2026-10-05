//
//  EphemeralDecryptionService.swift
//  AevonXCore
//
//  Implements ephemeral decryption with immediate memory wiping
//  Credentials are decrypted only when needed and wiped immediately after use
//

import Foundation
import LocalAuthentication

/// Errors that can occur during ephemeral decryption operations
public enum EphemeralDecryptionError: Error {
    case biometricAuthFailed
    case decryptionFailed
    case invalidPayload
    case operationFailed
}

/// Secure string container that wipes memory on deallocation
public final class SecureString {
    private var buffer: [UInt8]
    
    public var value: String? {
        guard !buffer.isEmpty else { return nil }
        return String(bytes: buffer, encoding: .utf8)
    }
    
    public init(_ string: String) {
        buffer = Array(string.utf8)
    }
    
    public init?(data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        buffer = Array(string.utf8)
    }
    
    /// Wipes the string data from memory
    public func wipe() {
        // Overwrite with random data before zeroing
        for i in buffer.indices {
            buffer[i] = UInt8.random(in: 0...255)
        }
        // Zero out
        for i in buffer.indices {
            buffer[i] = 0
        }
        buffer.removeAll(keepingCapacity: false)
    }
    
    deinit {
        wipe()
    }
}

/// Secure credentials container that wipes all data on deallocation
public final class SecureCredentials {
    private var _username: SecureString?
    private var _password: SecureString?
    private var _privateKey: SecureString?
    private var _passphrase: SecureString?
    
    public var username: String? { _username?.value }
    public var password: String? { _password?.value }
    public var privateKey: String? { _privateKey?.value }
    public var passphrase: String? { _passphrase?.value }
    
    public init(
        username: String? = nil,
        password: String? = nil,
        privateKey: String? = nil,
        passphrase: String? = nil
    ) {
        if let username = username {
            self._username = SecureString(username)
        }
        if let password = password {
            self._password = SecureString(password)
        }
        if let privateKey = privateKey {
            self._privateKey = SecureString(privateKey)
        }
        if let passphrase = passphrase {
            self._passphrase = SecureString(passphrase)
        }
    }
    
    /// Wipes all credential data from memory
    public func wipe() {
        _username?.wipe()
        _password?.wipe()
        _privateKey?.wipe()
        _passphrase?.wipe()
        
        _username = nil
        _password = nil
        _privateKey = nil
        _passphrase = nil
    }
    
    deinit {
        wipe()
    }
}

/// Service for biometric authentication
public actor BiometricAuthService {
    
    public static let shared = BiometricAuthService()
    
    private let context = LAContext()
    
    private init() {}
    
    /// Checks if biometric authentication is available
    /// - Returns: Tuple containing availability status and error if any
    public func canAuthenticate() -> (available: Bool, error: LAError?) {
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return (available, error as? LAError)
    }
    
    /// Authenticates the user using biometrics
    /// - Parameter reason: The reason for authentication (displayed to user)
    /// - Throws: EphemeralDecryptionError if authentication fails
    public func authenticate(reason: String = "Access your server credentials") async throws {
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            guard success else {
                throw EphemeralDecryptionError.biometricAuthFailed
            }
        } catch {
            throw EphemeralDecryptionError.biometricAuthFailed
        }
    }
}

/// Service that performs ephemeral decryption - credentials are wiped immediately after use
public actor EphemeralDecryptionService {
    
    public static let shared = EphemeralDecryptionService()
    
    private init() {}
    
    /// Executes an operation with decrypted credentials, then immediately wipes them
    /// - Parameters:
    ///   - payload: The encrypted server payload
    ///   - operation: The operation to perform with decrypted credentials
    /// - Returns: The result of the operation
    /// - Throws: EphemeralDecryptionError if decryption or operation fails
    public func withDecryptedCredentials<T>(
        from payload: EncryptedServerPayload,
        operation: (SecureCredentials) async throws -> T
    ) async throws -> T {
        
        // 1. Biometric authentication required
        try await BiometricAuthService.shared.authenticate()
        
        // 2. Decrypt payload
        let plaintext = try await ServerEncryptionService.shared.decrypt(payload: payload)
        
        // 3. Parse credentials
        guard let json = try JSONSerialization.jsonObject(with: plaintext) as? [String: Any] else {
            throw EphemeralDecryptionError.invalidPayload
        }
        
        // Extract authentication details
        let authDict = json["authentication"] as? [String: Any]
        let connectionDict = json["connection_details"] as? [String: Any]
        
        let credentials = SecureCredentials(
            username: connectionDict?["username"] as? String,
            password: authDict?["password"] as? String,
            privateKey: authDict?["private_key"] as? String,
            passphrase: authDict?["key_passphrase"] as? String
        )
        
        // 4. Execute operation
        do {
            let result = try await operation(credentials)
            // 5. IMMEDIATE WIPE - critical security step
            credentials.wipe()
            return result
        } catch {
            // Ensure credentials are wiped even if operation fails
            credentials.wipe()
            throw error
        }
    }
    
    /// Decrypts server payload to extract connection details
    /// - Parameter payload: The encrypted server payload
    /// - Returns: Dictionary containing decrypted server details
    /// - Throws: EphemeralDecryptionError if decryption fails
    public func decryptServerDetails(from payload: EncryptedServerPayload) async throws -> [String: Any] {
        let plaintext = try await ServerEncryptionService.shared.decrypt(payload: payload)
        
        guard let json = try JSONSerialization.jsonObject(with: plaintext) as? [String: Any] else {
            throw EphemeralDecryptionError.invalidPayload
        }
        
        return json
    }
}
