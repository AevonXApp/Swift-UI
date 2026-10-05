//
//  ServerModels.swift
//  AevonXCoreBridge
//
//  Models for server management and encrypted data
//

import Foundation

/// Server identity information (stored encrypted)
public struct ServerIdentity: Codable {
    public var name: String
    public var iconName: String
    public var customColor: String?
    public var tags: [String]
    
    public init(
        name: String,
        iconName: String = "server.rack",
        customColor: String? = nil,
        tags: [String] = []
    ) {
        self.name = name
        self.iconName = iconName
        self.customColor = customColor
        self.tags = tags
    }
}

/// Server connection details (stored encrypted)
public struct ServerConnectionDetails: Codable {
    public var host: String
    public var port: Int
    public var username: String
    
    public init(
        host: String,
        port: Int = 22,
        username: String
    ) {
        self.host = host
        self.port = port
        self.username = username
    }
}

/// Authentication method for SSH (stored encrypted)
public enum AuthenticationType: String, Codable {
    case password = "password"
    case privateKey = "private_key"
}

/// Server authentication details (stored encrypted)
public struct ServerAuthentication: Codable {
    public var authType: AuthenticationType
    public var password: String?
    public var privateKey: String?
    public var keyPassphrase: String?
    
    public init(
        authType: AuthenticationType,
        password: String? = nil,
        privateKey: String? = nil,
        keyPassphrase: String? = nil
    ) {
        self.authType = authType
        self.password = password
        self.privateKey = privateKey
        self.keyPassphrase = keyPassphrase
    }
}

/// Host key pinning information (stored encrypted)
public struct HostKeyPinning: Codable {
    public var algorithm: String
    public var fingerprint: String
    public var trustedSince: Date
    public var lastVerified: Date
    
    public init(
        algorithm: String,
        fingerprint: String,
        trustedSince: Date = Date(),
        lastVerified: Date = Date()
    ) {
        self.algorithm = algorithm
        self.fingerprint = fingerprint
        self.trustedSince = trustedSince
        self.lastVerified = lastVerified
    }
}

/// Server metadata (stored encrypted)
public struct ServerMetadata: Codable {
    public var osType: String?
    public var osVersion: String?
    public var location: String?
    public var notes: String?
    
    public init(
        osType: String? = nil,
        osVersion: String? = nil,
        location: String? = nil,
        notes: String? = nil
    ) {
        self.osType = osType
        self.osVersion = osVersion
        self.location = location
        self.notes = notes
    }
}

/// Complete server data structure (stored encrypted on server)
public struct EncryptedServerData: Codable {
    public var serverIdentity: ServerIdentity
    public var connectionDetails: ServerConnectionDetails
    public var authentication: ServerAuthentication
    public var hostKeyPinning: HostKeyPinning?
    public var metadata: ServerMetadata
    
    enum CodingKeys: String, CodingKey {
        case serverIdentity = "server_identity"
        case connectionDetails = "connection_details"
        case authentication
        case hostKeyPinning = "host_key_pinning"
        case metadata
    }
    
    public init(
        serverIdentity: ServerIdentity,
        connectionDetails: ServerConnectionDetails,
        authentication: ServerAuthentication,
        hostKeyPinning: HostKeyPinning? = nil,
        metadata: ServerMetadata = ServerMetadata()
    ) {
        self.serverIdentity = serverIdentity
        self.connectionDetails = connectionDetails
        self.authentication = authentication
        self.hostKeyPinning = hostKeyPinning
        self.metadata = metadata
    }
}

/// View model for server display (decrypted in memory only)
public struct ServerViewModel: Identifiable {
    public let id: String
    public let name: String
    public let host: String
    public let port: Int
    public let username: String
    public let iconName: String
    public let customColor: String?
    public let tags: [String]
    public let osType: String?
    public let location: String?
    public let createdAt: Date
    public let isAccessible: Bool
    public let accessLevel: ServerAccessLevel
    
    public init(
        id: String,
        name: String,
        host: String,
        port: Int,
        username: String,
        iconName: String = "server.rack",
        customColor: String? = nil,
        tags: [String] = [],
        osType: String? = nil,
        location: String? = nil,
        createdAt: Date,
        isAccessible: Bool,
        accessLevel: ServerAccessLevel
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.iconName = iconName
        self.customColor = customColor
        self.tags = tags
        self.osType = osType
        self.location = location
        self.createdAt = createdAt
        self.isAccessible = isAccessible
        self.accessLevel = accessLevel
    }
}

/// Request to add a new server
public struct AddServerRequest {
    public let name: String
    public let host: String
    public let port: Int
    public let username: String
    public let authType: AuthenticationType
    public let password: String?
    public let privateKey: String?
    public let keyPassphrase: String?
    public let tags: [String]
    public let notes: String?
    public let iconName: String
    public let customColor: String?
    
    public init(
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authType: AuthenticationType,
        password: String? = nil,
        privateKey: String? = nil,
        keyPassphrase: String? = nil,
        tags: [String] = [],
        notes: String? = nil,
        iconName: String = "server.rack",
        customColor: String? = nil
    ) {
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authType = authType
        self.password = password
        self.privateKey = privateKey
        self.keyPassphrase = keyPassphrase
        self.tags = tags
        self.notes = notes
        self.iconName = iconName
        self.customColor = customColor
    }
    
    /// Converts to EncryptedServerData for encryption
    public func toEncryptedServerData() -> EncryptedServerData {
        let identity = ServerIdentity(
            name: name,
            iconName: iconName,
            customColor: customColor,
            tags: tags
        )
        
        let connection = ServerConnectionDetails(
            host: host,
            port: port,
            username: username
        )
        
        let auth = ServerAuthentication(
            authType: authType,
            password: password,
            privateKey: privateKey,
            keyPassphrase: keyPassphrase
        )
        
        let metadata = ServerMetadata(
            notes: notes
        )
        
        return EncryptedServerData(
            serverIdentity: identity,
            connectionDetails: connection,
            authentication: auth,
            metadata: metadata
        )
    }
}

// MARK: - Server Icon Options

public enum ServerIcon: String, CaseIterable, Identifiable {
    case serverRack = "server.rack"
    case desktopComputer = "desktopcomputer"
    case laptopComputer = "laptopcomputer"
    case cloud = "cloud"
    case globe = "globe"
    case database = "cylinder.split.1x2"
    case box = "shippingbox.fill"
    case cpu = "cpu"
    case terminal = "terminal"
    case gear = "gearshape.fill"
    case shield = "shield.fill"
    case building = "building.2.fill"
    case house = "house.fill"
    case network = "network"
    case wifi = "wifi"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .serverRack: return "Server Rack"
        case .desktopComputer: return "Desktop"
        case .laptopComputer: return "Laptop"
        case .cloud: return "Cloud"
        case .globe: return "Globe"
        case .database: return "Database"
        case .box: return "Box"
        case .cpu: return "CPU"
        case .terminal: return "Terminal"
        case .gear: return "Gear"
        case .shield: return "Shield"
        case .building: return "Building"
        case .house: return "House"
        case .network: return "Network"
        case .wifi: return "WiFi"
        }
    }
}

// MARK: - Server Color Options

public enum ServerColor: String, CaseIterable, Identifiable {
    case blue = "#007AFF"
    case green = "#34C759"
    case orange = "#FF9500"
    case purple = "#AF52DE"
    case red = "#FF3B30"
    case teal = "#5AC8FA"
    case yellow = "#FFCC00"
    case pink = "#FF2D55"
    case indigo = "#5856D6"
    case cyan = "#00C7BE"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .red: return "Red"
        case .teal: return "Teal"
        case .yellow: return "Yellow"
        case .pink: return "Pink"
        case .indigo: return "Indigo"
        case .cyan: return "Cyan"
        }
    }
}

