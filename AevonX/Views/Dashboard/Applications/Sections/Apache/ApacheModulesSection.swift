//
//  ApacheModulesSection.swift
//  AevonX
//
//  Loaded Apache modules list — pure display, data from detail view.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheModulesSection: View {
    let modules: [BridgeModuleInfo]

    @State private var searchText = ""

    private var filteredModules: [BridgeModuleInfo] {
        if searchText.isEmpty { return modules }
        return modules.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                AXSearchBar(text: $searchText, placeholder: "Filter modules...")
                Spacer()
                let enabled = modules.filter { $0.enabled }.count
                Text("\(enabled) loaded · \(modules.count) total")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider().background(Color.axBorder.opacity(0.3))

            if modules.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 28)).foregroundColor(.axTextMuted)
                    Text("No modules detected")
                        .font(AXTypography.caption).foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.sm) {
                        ForEach(filteredModules) { module in
                            moduleChip(module)
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
        }
    }

    private func moduleChip(_ module: BridgeModuleInfo) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: module.enabled ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 11))
                .foregroundColor(module.enabled ? apacheRed : .axTextMuted)

            Text(module.name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(module.enabled ? .axTextPrimary : .axTextMuted)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(module.enabled ? apacheRed.opacity(0.04) : Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .stroke(module.enabled ? apacheRed.opacity(0.15) : Color.axBorder.opacity(0.15), lineWidth: 1)
        )
    }
}
