//
//  PluginAPIService.swift
//  AevonXCoreBridge
//
//  Bridge adapter for Plugin marketplace API.
//  Matches AevonXCore.PluginAPIService.shared API.
//  Uses Go Core CGo exports for data operations + native URLSession for downloads.
//

import Foundation
import AevonXCoreLib

// MARK: - Plugin API Error

public enum PluginAPIError: Error, LocalizedError {
    case noAuthToken
    case invalidResponse
    case pluginNotFound
    case networkError(Error)
    case decodingError(Error)
    case downloadExpired
    case downloadUsed
    
    public var errorDescription: String? {
        switch self {
        case .noAuthToken: return "No authentication token available"
        case .invalidResponse: return "Invalid response from server"
        case .pluginNotFound: return "Plugin not found or not published"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Failed to decode response: \(e.localizedDescription)"
        case .downloadExpired: return "The download link has expired. Please try again."
        case .downloadUsed: return "This download link has already been used."
        }
    }
}

// MARK: - Plugin API Service


public actor PluginAPIService {
    
    public static let shared = PluginAPIService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Categories
    
    public func fetchCategories() async throws -> [PluginCategory] {
        let json = await callGo {
            let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let token = await AuthService.shared.getToken() ?? ""
            return baseURL.withMutableCString { b in token.withMutableCString { t in PluginFetchCategories(b, t) } }
        }
        guard let data = extractData(json) else { throw PluginAPIError.invalidResponse }
        return (try? JSONDecoder().decode([PluginCategory].self, from: data)) ?? []
    }
    
    // MARK: - Fetch Plugins
    
    public func fetchPlugins(page: Int = 1, search: String? = nil, pricing: String? = nil, category: String? = nil) async throws -> PaginatedPlugins {
        let json = await callGo {
            let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let token = await AuthService.shared.getToken() ?? ""
            let cat = category ?? ""
            let srch = search ?? ""
            return baseURL.withMutableCString { b in token.withMutableCString { t in cat.withMutableCString { c in srch.withMutableCString { s in
                PluginFetchList(b, t, Int32(page), c, s)
            } } } }
        }
        guard let data = extractData(json) else { throw PluginAPIError.invalidResponse }
        return try JSONDecoder().decode(PaginatedPlugins.self, from: data)
    }
    
    // MARK: - Fetch Plugin Detail
    
    public func fetchPlugin(id: String) async throws -> Plugin {
        let json = await callGo {
            let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let token = await AuthService.shared.getToken() ?? ""
            return baseURL.withMutableCString { b in token.withMutableCString { t in id.withMutableCString { i in PluginFetchDetail(b, t, i) } } }
        }
        guard let data = extractData(json) else { throw PluginAPIError.pluginNotFound }
        return try JSONDecoder().decode(Plugin.self, from: data)
    }
    
    // MARK: - Get Download Info
    
    public func getDownloadInfo(id: String, versionId: String? = nil, serverId: String? = nil) async throws -> PluginDownloadInfo {
        let json = await callGo {
            let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let token = await AuthService.shared.getToken() ?? ""
            let vid = versionId ?? ""
            return baseURL.withMutableCString { b in token.withMutableCString { t in id.withMutableCString { i in vid.withMutableCString { v in "".withMutableCString { e in
                PluginFetchDownloadInfo(b, t, i, v, e)
            } } } } }
        }
        guard let data = extractData(json) else { throw PluginAPIError.invalidResponse }
        return try JSONDecoder().decode(PluginDownloadInfo.self, from: data)
    }
    
    // MARK: - Download Plugin File
    
    public func downloadPluginFile(url: URL) async throws -> URL {
        let (localURL, response) = try await session.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PluginAPIError.invalidResponse
        }
        
        if httpResponse.statusCode == 410 {
            let finalURL = httpResponse.url ?? url
            if finalURL.absoluteString.contains("already") {
                throw PluginAPIError.downloadUsed
            }
            throw PluginAPIError.downloadExpired
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PluginAPIError.invalidResponse
        }
        
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let destinationURL = cacheDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        try fileManager.moveItem(at: localURL, to: destinationURL)
        
        return destinationURL
    }
    
    // MARK: - Helpers
    
    private func callGo(_ work: @escaping @Sendable () async -> UnsafeMutablePointer<CChar>?) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    let result = await work()
                    defer { if let r = result { CoreFreeString(r) } }
                    let json = result.map { String(cString: $0) } ?? ""
                    continuation.resume(returning: json)
                }
            }
        }
    }
    
    private func extractData(_ json: String) -> Data? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = obj["data"],
              !(inner is NSNull) else { return nil }
        return try? JSONSerialization.data(withJSONObject: inner)
    }
}
