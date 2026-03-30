//
//  ServiceCategoryGroup.swift
//  AevonX
//
//  A collapsible category group showing services with action buttons.
//

import SwiftUI

struct ServiceCategoryGroup: View {
    @ObservedObject var vm: ServerSettingsViewModel
    let category: ServiceCategory
    let services: [ServiceInfo]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            categoryHeader
            if isExpanded {
                ForEach(services) { svc in
                    ServiceRowView(vm: vm, service: svc)
                }
            }
        }
    }

    private var categoryHeader: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: category.icon)
                    .font(AXTypography.caption).foregroundColor(category.color)
                Text(category.rawValue)
                    .font(AXTypography.caption).fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                Text("(\(services.count))")
                    .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(AXTypography.caption2).foregroundColor(.axTextMuted)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Service Row

struct ServiceRowView: View {
    @ObservedObject var vm: ServerSettingsViewModel
    let service: ServiceInfo

    private var isOperating: Bool { vm.operatingServices.contains(service.name) }

    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: service.activeState.icon)
                .font(AXTypography.caption2)
                .foregroundColor(service.activeState.color)
                .frame(width: 14)

            Text(service.name)
                .font(AXTypography.monoXs).fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)

            enabledBadge

            Spacer()

            if isOperating {
                ProgressView().scaleEffect(0.5)
            } else {
                actionButtons
            }
        }
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
        .background(Color.axBackgroundTertiary.opacity(0.5))
        .cornerRadius(AXCornerRadius.sm)
    }

    private var enabledBadge: some View {
        Group {
            if service.enabledState != .unknown {
                Text(service.enabledState.label)
                    .font(AXTypography.caption2)
                    .foregroundColor(service.enabledState.color)
                    .padding(.horizontal, AXSpacing.xxs)
                    .background(service.enabledState.color.opacity(0.1))
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: AXSpacing.xxs) {
            // Logs
            Button(action: { vm.selectedServiceForLogs = service.name }) {
                Image(systemName: "doc.text").font(AXTypography.caption2).foregroundColor(.axTextMuted)
            }.buttonStyle(PlainButtonStyle())

            // Restart
            Button(action: { Task { await vm.restartService(service.name) } }) {
                Image(systemName: "arrow.clockwise").font(AXTypography.caption2).foregroundColor(.axAccentBlue)
            }.buttonStyle(PlainButtonStyle())

            // Start/Stop
            Button(action: { Task { await vm.toggleService(service.name, start: service.activeState != .active) } }) {
                Image(systemName: service.activeState == .active ? "stop.fill" : "play.fill")
                    .font(AXTypography.caption2)
                    .foregroundColor(service.activeState == .active ? .axError : .axSuccess)
            }.buttonStyle(PlainButtonStyle())

            // Enable/Disable
            if service.enabledState == .enabled || service.enabledState == .disabled {
                Button(action: {
                    Task {
                        if service.enabledState == .enabled {
                            await vm.disableService(service.name)
                        } else {
                            await vm.enableService(service.name)
                        }
                    }
                }) {
                    Image(systemName: service.enabledState == .enabled ? "power.circle.fill" : "power.circle")
                        .font(AXTypography.caption2)
                        .foregroundColor(service.enabledState == .enabled ? .axSuccess : .axTextMuted)
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}
