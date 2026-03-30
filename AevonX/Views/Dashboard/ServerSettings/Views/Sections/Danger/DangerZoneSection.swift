//
//  DangerZoneSection.swift
//  AevonX
//
//  Danger zone card — destructive actions with confirmation.
//

import SwiftUI

struct DangerZoneSection: View {
    let server: Server
    @Binding var showRemoveAlert: Bool

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "exclamationmark.triangle.fill", title: L10n.ServerSettings.dangerZone, subtitle: L10n.ServerSettings.destructiveActions, gradient: [.axError, .red.opacity(0.7)])
                Divider().background(Color.axError.opacity(0.3))

                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(L10n.ServerSettings.removeServer).font(AXTypography.body).foregroundColor(.axTextPrimary)
                        Text(L10n.ServerSettings.removeServerDesc).font(AXTypography.caption).foregroundColor(.axTextTertiary)
                    }
                    Spacer()
                    Button(action: { showRemoveAlert = true }) {
                        Text(L10n.Button.remove)
                            .font(AXTypography.caption).fontWeight(.semibold)
                            .foregroundColor(.axError)
                            .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.xs)
                            .background(Color.axError.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axError.opacity(0.3), lineWidth: 1))
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axError.opacity(0.2), lineWidth: 1))
    }
}
