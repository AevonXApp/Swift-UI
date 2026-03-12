//
//  ServiceSidebarHeader.swift
//  AevonX
//
//  Unified sidebar header for all service engines
//  Displays service name, version, logo, and back button
//

import SwiftUI
import AevonXCoreBridge

/// Unified sidebar header component for all service engines
struct ServiceSidebarHeader: View {
    let application: ApplicationInstance
    let brandColor: Color
    let logoName: String?
    let iconName: String?
    let onBack: () -> Void

    /// Initialize with a logo image name
    init(
        application: ApplicationInstance,
        brandColor: Color,
        logoName: String,
        onBack: @escaping () -> Void
    ) {
        self.application = application
        self.brandColor = brandColor
        self.logoName = logoName
        self.iconName = nil
        self.onBack = onBack
    }

    /// Initialize with a system icon name
    init(
        application: ApplicationInstance,
        brandColor: Color,
        iconName: String,
        onBack: @escaping () -> Void
    ) {
        self.application = application
        self.brandColor = brandColor
        self.logoName = nil
        self.iconName = iconName
        self.onBack = onBack
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Back Button
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                    Text("Applications")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.axTextTertiary)
            }
            .buttonStyle(.plain)

            // Service Info
            HStack(spacing: AXSpacing.md) {
                // Logo/Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(brandColor.opacity(0.15))

                    if let logoName = logoName {
                        // Use custom logo image
                        Image(logoName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    } else if let iconName = iconName {
                        // Use SF Symbol
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(brandColor)
                    }
                }
                .frame(width: 52, height: 52)

                // Name and Version
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.axTextPrimary)

                    if let version = application.version {
                        Text(version)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.axTextMuted)
                            .monospaced()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ServiceSidebarHeader(
            application: ApplicationInstance(
                name: "MySQL",
                type: .mysql,
                version: "8.0.35"
            ),
            brandColor: Color(hex: "#00758F"),
            iconName: "cylinder.split.1x2",
            onBack: {}
        )

        Divider()

        ServiceSidebarHeader(
            application: ApplicationInstance(
                name: "PostgreSQL",
                type: .postgresql,
                version: "15.3"
            ),
            brandColor: Color(hex: "#336791"),
            iconName: "cylinder.split.1x2",
            onBack: {}
        )

        Divider()

        ServiceSidebarHeader(
            application: ApplicationInstance(
                name: "Redis",
                type: .redis,
                version: "7.2.0"
            ),
            brandColor: Color(hex: "#DC382D"),
            iconName: "bolt.fill",
            onBack: {}
        )
    }
    .frame(width: 260)
    .background(Color.axSurface.opacity(0.4))
}
