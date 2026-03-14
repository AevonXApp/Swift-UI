//
//  FavoritesManager.swift
//  AevonX
//
//  Persistent favorites/bookmarks system for file paths
//  Saved per-server in UserDefaults
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Favorite Path

struct FavoritePath: Identifiable, Codable, Hashable {
    let id: String
    let path: String
    let name: String
    let icon: String
    let addedDate: Date
    
    init(path: String, name: String? = nil, icon: String = "star.fill") {
        self.id = UUID().uuidString
        self.path = path
        self.name = name ?? (path as NSString).lastPathComponent
        self.icon = icon
        self.addedDate = Date()
    }
}

// MARK: - Favorites Manager

class FavoritesManager {
    static let shared = FavoritesManager()
    
    private func key(for serverId: String) -> String {
        "fm_favorites_\(serverId)"
    }
    
    func getFavorites(serverId: String) -> [FavoritePath] {
        guard let data = UserDefaults.standard.data(forKey: key(for: serverId)),
              let favorites = try? JSONDecoder().decode([FavoritePath].self, from: data) else {
            return []
        }
        return favorites
    }
    
    func addFavorite(path: String, name: String? = nil, serverId: String) {
        var favorites = getFavorites(serverId: serverId)
        
        // Don't add duplicates
        guard !favorites.contains(where: { $0.path == path }) else { return }
        
        let fav = FavoritePath(path: path, name: name)
        favorites.append(fav)
        save(favorites, serverId: serverId)
    }
    
    func removeFavorite(path: String, serverId: String) {
        var favorites = getFavorites(serverId: serverId)
        favorites.removeAll { $0.path == path }
        save(favorites, serverId: serverId)
    }
    
    func isFavorite(path: String, serverId: String) -> Bool {
        getFavorites(serverId: serverId).contains { $0.path == path }
    }
    
    func toggleFavorite(path: String, name: String? = nil, serverId: String) {
        if isFavorite(path: path, serverId: serverId) {
            removeFavorite(path: path, serverId: serverId)
        } else {
            addFavorite(path: path, name: name, serverId: serverId)
        }
    }
    
    private func save(_ favorites: [FavoritePath], serverId: String) {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key(for: serverId))
        }
    }
}
