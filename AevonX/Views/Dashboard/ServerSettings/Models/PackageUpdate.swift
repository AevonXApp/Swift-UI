//
//  PackageUpdate.swift
//  AevonX
//
//  Data model for available package updates.
//

import SwiftUI

struct PackageUpdate: Identifiable {
    let id: String
    let name: String
    let currentVersion: String
    let availableVersion: String
    let isSecurity: Bool
    let source: String

    var typeColor: Color { isSecurity ? .axError : .axAccentBlue }
    var typeLabel: String { isSecurity ? "SEC" : "STD" }
    var typeIcon: String { isSecurity ? "shield.fill" : "shippingbox.fill" }
}
