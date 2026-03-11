//
//  UnifiedServiceSidebar.swift
//  AevonX
//
//  Unified sidebar component that works for ALL service engines
//  Replaces individual PHP/Nginx/Database sidebars with a single generic component
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

/// Generic sidebar that works for ANY service engine
/// Supports PHP, Nginx, MySQL, PostgreSQL, Redis, MongoDB, etc.
struct UnifiedServiceSidebar<Section: SidebarSection>: View {
    let application: ApplicationInstance
    let brandColor: Color
    let logoName: String?
    let iconName: String?
    @Binding var selectedSection: Section
    let sections: [Section]
    let onBack: () -> Void
    let onControl: (ServiceControlButtons.ServiceAction) -> Void

    /// Initialize with custom logo
    init(
        application: ApplicationInstance,
        brandColor: Color,
        logoName: String,
        selectedSection: Binding<Section>,
        sections: [Section],
        onBack: @escaping () -> Void,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void
    ) {
        self.application = application
        self.brandColor = brandColor
        self.logoName = logoName
        self.iconName = nil
        self._selectedSection = selectedSection
        self.sections = sections
        self.onBack = onBack
        self.onControl = onControl
    }

    /// Initialize with SF Symbol icon
    init(
        application: ApplicationInstance,
        brandColor: Color,
        iconName: String,
        selectedSection: Binding<Section>,
        sections: [Section],
        onBack: @escaping () -> Void,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void
    ) {
        self.application = application
        self.brandColor = brandColor
        self.logoName = nil
        self.iconName = iconName
        self._selectedSection = selectedSection
        self.sections = sections
        self.onBack = onBack
        self.onControl = onControl
    }

    var body: some View {
        AXSidebarContainer(
            width: 260,
            header: {
                if let logoName = logoName {
                    ServiceSidebarHeader(
                        application: application,
                        brandColor: brandColor,
                        logoName: logoName,
                        onBack: onBack
                    )
                } else if let iconName = iconName {
                    ServiceSidebarHeader(
                        application: application,
                        brandColor: brandColor,
                        iconName: iconName,
                        onBack: onBack
                    )
                }
            },
            items: {
                ForEach(sections, id: \.id) { section in
                    AXSidebarRow(
                        icon: section.icon,
                        title: section.displayName,
                        color: brandColor,
                        isSelected: selectedSection.id == section.id,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSection = section
                            }
                        }
                    )
                }
            },
            footer: {
                ServiceControlButtons(
                    application: application,
                    onControl: onControl
                )
            }
        )
    }
}

// MARK: - Convenience Initializers for Specific Services

extension UnifiedServiceSidebar {
    /// Create sidebar for MySQL
    static func mysql(
        application: ApplicationInstance,
        selectedSection: Binding<Section>,
        sections: [Section],
        onBack: @escaping () -> Void,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void
    ) -> UnifiedServiceSidebar {
        UnifiedServiceSidebar(
            application: application,
            brandColor: Color(hex: "#00758F"),
            iconName: "cylinder.split.1x2",
            selectedSection: selectedSection,
            sections: sections,
            onBack: onBack,
            onControl: onControl
        )
    }

    /// Create sidebar for PostgreSQL
    static func postgresql(
        application: ApplicationInstance,
        selectedSection: Binding<Section>,
        sections: [Section],
        onBack: @escaping () -> Void,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void
    ) -> UnifiedServiceSidebar {
        UnifiedServiceSidebar(
            application: application,
            brandColor: Color(hex: "#336791"),
            iconName: "cylinder.split.1x2",
            selectedSection: selectedSection,
            sections: sections,
            onBack: onBack,
            onControl: onControl
        )
    }

    /// Create sidebar for Redis
    static func redis(
        application: ApplicationInstance,
        selectedSection: Binding<Section>,
        sections: [Section],
        onBack: @escaping () -> Void,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void
    ) -> UnifiedServiceSidebar {
        UnifiedServiceSidebar(
            application: application,
            brandColor: Color(hex: "#DC382D"),
            iconName: "bolt.fill",
            selectedSection: selectedSection,
            sections: sections,
            onBack: onBack,
            onControl: onControl
        )
    }

    /// Create sidebar for MongoDB
    static func mongodb(
        application: ApplicationInstance,
        selectedSection: Binding<Section>,
        sections: [Section],
        onBack: @escaping () -> Void,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void
    ) -> UnifiedServiceSidebar {
        UnifiedServiceSidebar(
            application: application,
            brandColor: Color(hex: "#47A248"),
            iconName: "leaf.fill",
            selectedSection: selectedSection,
            sections: sections,
            onBack: onBack,
            onControl: onControl
        )
    }

    /// Create sidebar for any database type
    static func database(
        databaseType: AevonXCoreBridge.DatabaseType,
        application: ApplicationInstance,
        selectedSection: Binding<Section>,
        sections: [Section],
        onBack: @escaping () -> Void,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void
    ) -> UnifiedServiceSidebar {
        let color: Color = {
            switch databaseType {
            case .mysql: return Color(hex: "#00758F")
            case .postgresql: return Color(hex: "#336791")
            case .redis: return Color(hex: "#DC382D")
            case .mongodb: return Color(hex: "#47A248")
            case .sqlite: return Color(hex: "#003B57")
            case .mariadb: return Color(hex: "#003545")
            case .cockroachdb: return Color(hex: "#6933FF")
            case .cassandra: return Color(hex: "#1287B1")
            case .elasticsearch: return Color(hex: "#FEC514")
            default: return .gray
            }
        }()
        let icon: String = {
            switch databaseType {
            case .mysql, .mariadb: return "cylinder.split.1x2"
            case .postgresql: return "cylinder"
            case .redis: return "memorychip"
            case .mongodb: return "leaf"
            case .sqlite: return "doc"
            case .cockroachdb: return "network"
            case .cassandra: return "square.grid.3x3"
            case .elasticsearch: return "magnifyingglass"
            default: return "questionmark.circle"
            }
        }()
        return UnifiedServiceSidebar(
            application: application,
            brandColor: color,
            iconName: icon,
            selectedSection: selectedSection,
            sections: sections,
            onBack: onBack,
            onControl: onControl
        )
    }
}

// MARK: - Preview

#Preview {
    UnifiedServiceSidebar(
        application: ApplicationInstance(
            name: "MySQL",
            type: .mysql,
            version: "8.0.35",
            isRunning: true
        ),
        brandColor: Color(hex: "#00758F"),
        iconName: "cylinder.split.1x2",
        selectedSection: .constant(PreviewSection.overview),
        sections: PreviewSection.allCases,
        onBack: {},
        onControl: { _ in }
    )
    .frame(width: 260)
    .background(Color.axSurface.opacity(0.4))
}

// Preview section
private enum PreviewSection: String, SidebarSection, CaseIterable {
    case overview = "Overview"
    case configuration = "Configuration"
    case logs = "Logs"
    case versions = "Versions"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .configuration: return "slider.horizontal.3"
        case .logs: return "doc.text"
        case .versions: return "number"
        }
    }
}
