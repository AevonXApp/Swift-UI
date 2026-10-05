//
//  InventoryBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for the Go-side hardware-inventory and service-count parsers.
//  Replaces inline SSH-output parsing that previously lived in
//  AevonX/ViewModels/ServerConnectionViewModel.swift and
//  AevonX/ViewModels/ServerDatabasesViewModel.swift.
//

import Foundation
import AevonXCoreLib

// MARK: - Models (mirror the Go structs)

public struct HardwareInventory: Codable, Sendable {
    public let ramTotalMB: Int
    public let ramUsedMB: Int
    public let ramAvailableMB: Int
    public let ramBuffCacheMB: Int
    public let diskTotalGB: Double
    public let diskUsedGB: Double
    public let cpuCores: Int
    public let cpuModel: String
    public let netRxGB: Double
    public let netTxGB: Double
    public let osPrettyName: String
    public let swapTotalMB: Int
    public let swapUsedMB: Int
}

public struct ServiceCounts: Codable, Sendable {
    public let websites: Int
    public let databases: Int
    public let applications: Int
}

public struct DatabaseInfoCore: Codable, Sendable {
    public let name: String
    public let type: String      // "mysql" | "postgresql" | "redis"
    public let version: String?
    public let status: String
    public let size: Double?

    enum CodingKeys: String, CodingKey {
        case name, type, version, status, size
    }
}

// MARK: - Bridge

public final class InventoryBridge: @unchecked Sendable {

    public static let shared = InventoryBridge()
    private init() {}

    /// Marker the SSH command must use to delimit sections in batch output.
    /// Read from Go so the contract lives in one place.
    public lazy var sectionMarker: String = {
        guard let cStr = InventorySectionMarker() else { return "~~AX~~" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }()

    /// Parse the 7-section hardware batch (RAM, disk, cores, model, net, OS, swap).
    public func parseHardware(_ output: String) -> HardwareInventory? {
        let json = withCArgs { c in extractRaw(InventoryParseHardware(c.str(output))) }
        return decode(HardwareInventory.self, from: json)
    }

    /// Parse the 3-section "what's running" batch (websites, databases, apps).
    public func parseServiceCounts(_ output: String) -> ServiceCounts? {
        let json = withCArgs { c in extractRaw(InventoryParseServiceCounts(c.str(output))) }
        return decode(ServiceCounts.self, from: json)
    }

    /// Parse `mysql -e "SHOW DATABASES;"` output, with system schemas stripped.
    public func parseMySQLDatabases(_ output: String) -> [DatabaseInfoCore] {
        let json = withCArgs { c in extractRaw(DBParseMySQLList(c.str(output))) }
        return decode([DatabaseInfoCore].self, from: json) ?? []
    }

    /// Parse `psql -l` output, with template/system DBs stripped.
    public func parsePostgreSQLDatabases(_ output: String) -> [DatabaseInfoCore] {
        let json = withCArgs { c in extractRaw(DBParsePostgreSQLList(c.str(output))) }
        return decode([DatabaseInfoCore].self, from: json) ?? []
    }

    /// Parse `redis-cli INFO` output. Returns nil if the output isn't Redis.
    public func parseRedisInfo(_ output: String) -> DatabaseInfoCore? {
        let json = withCArgs { c in extractRaw(DBParseRedisInfo(c.str(output))) }
        if json == "null" || json.isEmpty { return nil }
        return decode(DatabaseInfoCore.self, from: json)
    }

    /// Server-side check: is `name` a system schema for `engine`?
    public func isSystemDatabase(engine: String, name: String) -> Bool {
        let json = withCArgs { c in extractRaw(DBIsSystemDatabase(c.str(engine), c.str(name))) }
        struct Wrapper: Decodable { let data: Inner; struct Inner: Decodable { let is_system: Bool } }
        return decode(Wrapper.self, from: json)?.data.is_system ?? false
    }

    // MARK: - Helpers

    private func extractRaw(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { free(cStr) }
        return String(cString: cStr)
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
