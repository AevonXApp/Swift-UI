//
//  APIConfiguration.swift
//  AevonXCoreBridge
//
//  Configuration management for API endpoints — bridge copy.
//

import Foundation

// MARK: - API Configuration

public struct APIConfiguration {
    
    public var baseURL: String
    public var apiVersion: String
    public var useHTTPS: Bool
    public var timeoutInterval: TimeInterval
    
    public init(
        baseURL: String,
        apiVersion: String = "v1",
        useHTTPS: Bool = true,
        timeoutInterval: TimeInterval = 30.0
    ) {
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.useHTTPS = useHTTPS
        self.timeoutInterval = timeoutInterval
    }
    
    public var fullBaseURL: String {
        let protocolString = useHTTPS ? "https" : "http"
        return "\(protocolString)://\(baseURL)/api/\(apiVersion)"
    }
    
    public static func make(
        host: String,
        port: Int? = nil,
        apiVersion: String = "v1",
        useHTTPS: Bool = true
    ) -> APIConfiguration {
        var baseURL = host
        if let port = port {
            baseURL = "\(host):\(port)"
        }
        return APIConfiguration(
            baseURL: baseURL,
            apiVersion: apiVersion,
            useHTTPS: useHTTPS
        )
    }
}

public enum APIEnvironment {
    case development
    case staging
    case production
    case custom(APIConfiguration)
    
    public var configuration: APIConfiguration {
        switch self {
        case .development:
            return APIConfiguration.developmentConfiguration()
        case .staging:
            return APIConfiguration.stagingConfiguration()
        case .production:
            return APIConfiguration.productionConfiguration()
        case .custom(let config):
            return config
        }
    }
    
    public static var current: APIEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

extension APIConfiguration {
    
    public static func developmentConfiguration() -> APIConfiguration {
        #if targetEnvironment(simulator)
        let machineIP = APIConfiguration.detectMachineIP()
        return APIConfiguration.make(host: machineIP, port: 8000, useHTTPS: false)
        #else
        // Use production API for testing on real device/Mac
        return APIConfiguration.make(host: "aevonx.app", useHTTPS: true)
        #endif
    }
    
    public static func stagingConfiguration() -> APIConfiguration {
        return APIConfiguration.make(host: "aevonx.app", useHTTPS: true)
    }
    
    public static func productionConfiguration() -> APIConfiguration {
        return APIConfiguration.make(host: "aevonx.app", useHTTPS: true)
    }
    
    private static func detectMachineIP() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "localhost" }
        defer { freeifaddrs(ifaddr) }
        
        var pointer = ifaddr
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            guard let interface = pointer?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                }
            }
        }
        return address ?? "localhost"
    }
}

// MARK: - Configuration Manager

public final class ConfigurationManager {
    
    public static let shared = ConfigurationManager()
    
    public var currentEnvironment: APIEnvironment {
        didSet {}
    }
    
    public var currentConfiguration: APIConfiguration {
        return currentEnvironment.configuration
    }
    
    private init() {
        self.currentEnvironment = APIEnvironment.current
    }
    
    public func setEnvironment(_ environment: APIEnvironment) {
        currentEnvironment = environment
    }
    
    public func setCustomBaseURL(_ baseURL: String, port: Int? = nil, useHTTPS: Bool = true) {
        let config = APIConfiguration.make(host: baseURL, port: port, useHTTPS: useHTTPS)
        currentEnvironment = .custom(config)
    }
    
    public func resetToDefault() {
        currentEnvironment = APIEnvironment.current
    }
}

// MARK: - App URLs

public enum AppURLs {
    public static var base: String {
        return "https://aevonx.app"
    }

    public static var website: URL     { URL(string: base)! }
    public static var docs: URL        { URL(string: "https://docs.aevonx.app")! }
    public static var pricing: URL     { URL(string: "\(base)/pricing")! }
    public static var subscription: URL { URL(string: "\(base)/pricing")! }
    public static var dashboardSubscription: URL { URL(string: "\(base)/dashboard/subscription")! }
    public static var github: URL      { URL(string: "https://github.com/AevonXApp")! }
    public static var twitter: URL     { URL(string: "https://x.com/AevonXApp")! }
    public static var reddit: URL      { URL(string: "\(base)/social/reddit")! }
    public static var changelog: URL   { URL(string: "\(base)/changelog")! }
    public static var privacy: URL     { URL(string: "\(base)/privacy")! }
    public static var terms: URL       { URL(string: "\(base)/terms")! }
    public static var license: URL     { URL(string: "\(base)/license")! }
    public static var contact: URL     { URL(string: "\(base)/contact")! }
}

// MARK: - Build Configuration

public enum BuildConfiguration {
    public static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    public static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    public static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    public static var platform: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(tvOS)
        return "tvOS"
        #else
        return "Unknown"
        #endif
    }
}

// BiometricAuthService moved to Security/EphemeralDecryptionService.swift
