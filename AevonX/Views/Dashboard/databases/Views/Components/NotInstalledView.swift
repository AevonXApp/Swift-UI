//
//  NotInstalledView.swift
//  AevonX
//
//  Fallback view shown if a database engine is not installed.
//  With the new design, uninstalled engine tabs are hidden,
//  so this is rarely displayed. Directs users to Applications tab.
//

import SwiftUI
import AevonXCoreBridge

struct NotInstalledView: View {
    let type: DatabaseType
    @ObservedObject var viewModel: DatabaseManagementViewModel

    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()

            Image(systemName: type.iconName)
                .font(.system(size: 64))
                .foregroundColor(type.brandColor.opacity(0.5))

            VStack(spacing: AXSpacing.md) {
                Text("\(type.displayName) Not Installed")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Text("Go to the Applications tab to install \(type.displayName) on your server.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Spacer()
        }
        .padding(AXSpacing.xl)
    }
}
