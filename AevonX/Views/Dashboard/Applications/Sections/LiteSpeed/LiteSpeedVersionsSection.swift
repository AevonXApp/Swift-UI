//
//  LiteSpeedVersionsSection.swift
//  AevonX
//
//  Installed & available version management for LiteSpeed.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedVersionsSection: View {
    let serverId: String
    let installedVersions: [BridgeAppVersion]
    let availableVersions: [BridgeAppVersion]

    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Installed
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    AXSectionTitle(title: "Installed Versions", icon: "checkmark.circle.fill")
                    if installedVersions.isEmpty {
                        HStack {
                            Image(systemName: "shippingbox").foregroundColor(.axTextMuted)
                            Text("No versions detected").font(AXTypography.subheadline).foregroundColor(.axTextMuted)
                        }
                        .padding(AXSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.axSurface.opacity(0.3)).cornerRadius(AXCornerRadius.md)
                    } else {
                        ForEach(installedVersions, id: \.version) { version in
                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: version.isActive ? "checkmark.seal.fill" : "shippingbox")
                                    .font(AXTypography.body)
                                    .foregroundColor(version.isActive ? lsGreen : .axTextMuted)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("v\(version.version)")
                                        .font(AXTypography.monoLg).fontWeight(.semibold)
                                        .foregroundColor(.axTextPrimary)
                                    if version.isActive {
                                        Text("Active")
                                            .font(AXTypography.caption).fontWeight(.bold)
                                            .foregroundColor(lsGreen)
                                    }
                                }
                                Spacer()

                                if version.isActive {
                                    Text("CURRENT")
                                        .font(AXTypography.caption2).fontWeight(.bold)
                                        .foregroundColor(lsGreen)
                                        .padding(.horizontal, 6).padding(.vertical, 3)
                                        .background(lsGreen.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(AXSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(version.isActive ? lsGreen.opacity(0.05) : Color.axSurface.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(version.isActive ? lsGreen.opacity(0.2) : Color.axBorder.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }

                // Available
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    AXSectionTitle(title: "Available Versions", icon: "arrow.down.circle")
                    if availableVersions.isEmpty {
                        HStack {
                            Image(systemName: "arrow.down.circle").foregroundColor(.axTextMuted)
                            Text("No additional versions available").font(AXTypography.subheadline).foregroundColor(.axTextMuted)
                        }
                        .padding(AXSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.axSurface.opacity(0.3)).cornerRadius(AXCornerRadius.md)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 3), spacing: AXSpacing.md) {
                            ForEach(availableVersions, id: \.version) { version in
                                HStack(spacing: AXSpacing.sm) {
                                    Image(systemName: "shippingbox")
                                        .font(AXTypography.subheadline)
                                        .foregroundColor(.indigo)
                                    Text("v\(version.version)")
                                        .font(AXTypography.monoMd)
                                        .foregroundColor(.axTextPrimary)
                                    Spacer()
                                }
                                .padding(AXSpacing.md)
                                .background(Color.axSurface.opacity(0.3))
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }
}
