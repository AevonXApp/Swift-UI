//
//  AXLaunchSettingsView.swift
//  AevonX
//
//  AXLaunch default settings panel.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchSettingsView: View {
    @State private var defaultWebServer = "nginx"
    @State private var defaultSSL = true
    @State private var defaultForceHTTPS = true
    @State private var defaultTransferMode = "auto"
    @State private var defaultDBEngine = "mysql"

    private let transferModes = ["auto", "tar", "sftp", "delta"]
    private let webServers = ["nginx", "apache", "openlitespeed"]
    private let dbEngines = ["mysql", "postgres"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                sectionHeader("Transfer")
                settingPicker("Default mode", transferModes, $defaultTransferMode)

                Divider().background(Color.axBorder)

                sectionHeader("Domain")
                settingPicker("Web server", webServers, $defaultWebServer)
                settingToggle("SSL by default", $defaultSSL)
                settingToggle("Force HTTPS by default", $defaultForceHTTPS)

                Divider().background(Color.axBorder)

                sectionHeader("Database")
                settingPicker("Default engine", dbEngines, $defaultDBEngine)
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.axTextPrimary)
    }

    private func settingPicker(_ label: String, _ options: [String], _ selection: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt.capitalized).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
        }
    }

    private func settingToggle(_ label: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .toggleStyle(.switch)
    }
}
