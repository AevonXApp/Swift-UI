//
//  ServerSettingsEditableRows.swift
//  AevonX
//
//  Editable hostname and timezone rows for server settings.
//

import SwiftUI

// MARK: - Hostname Editable Row

struct ServerSettingsHostnameRow: View {
    @ObservedObject var vm: ServerSettingsViewModel

    var body: some View {
        HStack {
            Image(systemName: "desktopcomputer").font(AXTypography.callout).foregroundColor(.axTextMuted).frame(width: 22)
            Text("Hostname").font(AXTypography.body).foregroundColor(.axTextPrimary)
            Spacer()
            if vm.isEditingHostname {
                HStack(spacing: AXSpacing.xxs) {
                    TextField("hostname", text: $vm.newHostname)
                        .font(AXTypography.monoSm)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, AXSpacing.xs).padding(.vertical, 3)
                        .background(Color.axBackgroundTertiary).cornerRadius(AXCornerRadius.xs).frame(width: 150)
                    Button(action: { Task { await vm.changeHostname() } }) {
                        Image(systemName: vm.isChangingHostname ? "hourglass" : "checkmark")
                            .font(AXTypography.caption).fontWeight(.bold).foregroundColor(.axSuccess)
                    }.buttonStyle(PlainButtonStyle())
                    Button(action: { vm.isEditingHostname = false; vm.newHostname = vm.hostname }) {
                        Image(systemName: "xmark").font(AXTypography.caption).fontWeight(.bold).foregroundColor(.axTextMuted)
                    }.buttonStyle(PlainButtonStyle())
                }
            } else {
                HStack(spacing: AXSpacing.xxs) {
                    Text(vm.hostname).font(AXTypography.monoSm).foregroundColor(.axTextSecondary)
                    Button(action: { vm.isEditingHostname = true }) {
                        Image(systemName: "pencil").font(AXTypography.caption2).foregroundColor(.axAccentBlue)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Timezone Editable Row

struct ServerSettingsTimezoneRow: View {
    @ObservedObject var vm: ServerSettingsViewModel

    private var timezoneList: [String] {
        vm.serverTimezones.isEmpty ? vm.commonTimezones : vm.serverTimezones
    }

    var body: some View {
        HStack {
            Image(systemName: "globe.americas").font(AXTypography.callout).foregroundColor(.axTextMuted).frame(width: 22)
            Text("Timezone").font(AXTypography.body).foregroundColor(.axTextPrimary)
            Spacer()
            if vm.isEditingTimezone {
                HStack(spacing: AXSpacing.xxs) {
                    if vm.isLoadingTimezones {
                        ProgressView().scaleEffect(0.5)
                    } else {
                        Picker("", selection: $vm.selectedTimezone) {
                            ForEach(timezoneList, id: \.self) { Text($0).tag($0) }
                        }.frame(width: 200)
                    }
                    Button(action: { Task { await vm.changeTimezone() } }) {
                        Image(systemName: vm.isChangingTimezone ? "hourglass" : "checkmark")
                            .font(AXTypography.caption).fontWeight(.bold).foregroundColor(.axSuccess)
                    }.buttonStyle(PlainButtonStyle())
                    Button(action: { vm.isEditingTimezone = false; vm.selectedTimezone = vm.currentTimezone }) {
                        Image(systemName: "xmark").font(AXTypography.caption).fontWeight(.bold).foregroundColor(.axTextMuted)
                    }.buttonStyle(PlainButtonStyle())
                }
            } else {
                HStack(spacing: AXSpacing.xxs) {
                    Text(vm.currentTimezone).font(AXTypography.monoSm).foregroundColor(.axTextSecondary)
                    Button(action: {
                        vm.isEditingTimezone = true
                        Task { await vm.loadTimezones() }
                    }) {
                        Image(systemName: "pencil").font(AXTypography.caption2).foregroundColor(.axAccentBlue)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
