//
//  ServiceDetailContainer.swift
//  AevonX
//
//  Unified container for all service detail views
//  Provides consistent HStack(Sidebar + Divider + Content) layout
//

import SwiftUI
import AevonXCore

/// Generic container that provides the standard service detail layout:
/// Left sidebar (UnifiedServiceSidebar) + Divider + Right content area (ScrollView)
struct ServiceDetailContainer<Section: SidebarSection & ServiceSection, Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let application: ApplicationInstance
    let brandColor: Color
    let logoName: String?
    let iconName: String?
    @Binding var selectedSection: Section
    let sections: [Section]
    let isLoading: Bool
    let loadingMessage: String
    let onBack: (() -> Void)?
    let onControl: (ServiceControlButtons.ServiceAction) -> Void
    @ViewBuilder let content: () -> Content

    /// Initialize with logo image
    init(
        application: ApplicationInstance,
        brandColor: Color,
        logoName: String,
        selectedSection: Binding<Section>,
        sections: [Section],
        isLoading: Bool,
        loadingMessage: String = "Loading…",
        onBack: (() -> Void)? = nil,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.application = application
        self.brandColor = brandColor
        self.logoName = logoName
        self.iconName = nil
        self._selectedSection = selectedSection
        self.sections = sections
        self.isLoading = isLoading
        self.loadingMessage = loadingMessage
        self.onBack = onBack
        self.onControl = onControl
        self.content = content
    }

    /// Initialize with SF Symbol icon
    init(
        application: ApplicationInstance,
        brandColor: Color,
        iconName: String,
        selectedSection: Binding<Section>,
        sections: [Section],
        isLoading: Bool,
        loadingMessage: String = "Loading…",
        onBack: (() -> Void)? = nil,
        onControl: @escaping (ServiceControlButtons.ServiceAction) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.application = application
        self.brandColor = brandColor
        self.logoName = nil
        self.iconName = iconName
        self._selectedSection = selectedSection
        self.sections = sections
        self.isLoading = isLoading
        self.loadingMessage = loadingMessage
        self.onBack = onBack
        self.onControl = onControl
        self.content = content
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            sidebarView

            Divider()

            // Right Content Area
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    if isLoading {
                        AXLoadingState(message: loadingMessage)
                    } else {
                        content()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                }
                .padding(AXSpacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
    }

    @ViewBuilder
    private var sidebarView: some View {
        if let logoName = logoName {
            UnifiedServiceSidebar(
                application: application,
                brandColor: brandColor,
                logoName: logoName,
                selectedSection: $selectedSection,
                sections: sections,
                onBack: { handleBack() },
                onControl: onControl
            )
        } else if let iconName = iconName {
            UnifiedServiceSidebar(
                application: application,
                brandColor: brandColor,
                iconName: iconName,
                selectedSection: $selectedSection,
                sections: sections,
                onBack: { handleBack() },
                onControl: onControl
            )
        }
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}
