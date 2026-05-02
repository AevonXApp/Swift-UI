//
//  LiteSpeedModulesSection.swift
//  AevonX
//
//  Loaded modules list for LiteSpeed.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedModulesSection: View {
    let modules: [BridgeModuleInfo]

    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Loaded Modules (\(modules.count))", icon: "puzzlepiece.extension.fill")

                if modules.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Spacer()
                        Image(systemName: "puzzlepiece.extension").font(AXTypography.largeTitle).foregroundColor(.axTextMuted.opacity(0.3))
                        Text(L10n.Apps.noModulesDetected).font(AXTypography.callout).foregroundColor(.axTextMuted)
                        Spacer()
                    }.frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 3), spacing: AXSpacing.md) {
                        ForEach(modules, id: \.name) { module in
                            HStack(spacing: AXSpacing.sm) {
                                Circle()
                                    .fill(module.enabled ? lsGreen : Color.axTextMuted)
                                    .frame(width: 8, height: 8)
                                Text(module.name)
                                    .font(AXTypography.monoMd).fontWeight(.medium)
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text(module.enabled ? L10n.Status.active : L10n.Status.inactive)
                                    .font(AXTypography.caption2).fontWeight(.semibold)
                                    .foregroundColor(module.enabled ? lsGreen : .axTextMuted)
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

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }
}
