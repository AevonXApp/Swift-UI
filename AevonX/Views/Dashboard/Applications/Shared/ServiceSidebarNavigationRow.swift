//
//  ServiceSidebarNavigationRow.swift
//  AevonX
//
//  Unified navigation row component for service sidebar
//  Works with any section type (PHPSection, NginxSection, DatabaseSection, etc.)
//

import SwiftUI

/// Generic navigation row for service sidebar
/// Works with any section type that conforms to SidebarSection protocol
struct ServiceSidebarNavigationRow<Section: SidebarSection>: View {
    let section: Section
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                    .frame(width: 20)

                Text(section.displayName)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(Color.axAccentBlue)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Protocol

/// Protocol that sidebar sections must conform to
protocol SidebarSection: Identifiable, CaseIterable {
    var displayName: String { get }
    var icon: String { get }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AXSpacing.xs) {
        ServiceSidebarNavigationRow(
            section: MockSection.overview,
            isSelected: true,
            action: {}
        )

        ServiceSidebarNavigationRow(
            section: MockSection.configuration,
            isSelected: false,
            action: {}
        )

        ServiceSidebarNavigationRow(
            section: MockSection.logs,
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .frame(width: 260)
    .background(Color.axSurface.opacity(0.4))
}

// Mock section for preview
private enum MockSection: String, SidebarSection, CaseIterable {
    case overview = "Overview"
    case configuration = "Configuration"
    case logs = "Logs"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .configuration: return "slider.horizontal.3"
        case .logs: return "doc.text"
        }
    }
}
