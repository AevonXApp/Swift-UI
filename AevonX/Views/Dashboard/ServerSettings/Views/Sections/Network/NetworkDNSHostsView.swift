//
//  NetworkDNSHostsView.swift
//  AevonX
//
//  DNS (/etc/resolv.conf) and Hosts (/etc/hosts) editors.
//

import SwiftUI

extension NetworkManagementSection {

    // MARK: - DNS

    var dnsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                sectionLabel(L10n.ServerSettings.dnsConfiguration, icon: "globe")
                Spacer()
                editButton(isEditing: vm.isEditingDNS) {
                    if vm.isEditingDNS {
                        vm.isEditingDNS = false
                    } else {
                        vm.editedDNS = vm.dnsContent
                        vm.isEditingDNS = true
                    }
                }
            }

            if vm.isEditingDNS {
                editableTextArea(text: $vm.editedDNS)
                saveDiscardBar(
                    onSave: { Task { await vm.saveDNS() } },
                    onDiscard: { vm.isEditingDNS = false }
                )
            } else {
                readOnlyText(vm.dnsContent)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Hosts

    var hostsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                sectionLabel(L10n.ServerSettings.hostsFile, icon: "doc.text")
                Spacer()
                editButton(isEditing: vm.isEditingHosts) {
                    if vm.isEditingHosts {
                        vm.isEditingHosts = false
                    } else {
                        vm.editedHosts = vm.hostsContent
                        vm.isEditingHosts = true
                    }
                }
            }

            if vm.isEditingHosts {
                editableTextArea(text: $vm.editedHosts)
                saveDiscardBar(
                    onSave: { Task { await vm.saveHosts() } },
                    onDiscard: { vm.isEditingHosts = false }
                )
            } else {
                readOnlyText(vm.hostsContent)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Stats

    var statsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.socketStatistics, icon: "chart.bar.fill")
            readOnlyText(vm.netStats)
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Save Message Overlay

    var saveMessageOverlay: some View {
        Group {
            if let (msg, ok) = vm.saveMsg {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(msg)
                }
                .font(AXTypography.caption).fontWeight(.medium)
                .foregroundColor(ok ? .axSuccess : .axError)
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                .background((ok ? Color.axSuccess : Color.axError).opacity(0.12))
                .cornerRadius(AXCornerRadius.sm)
                .transition(.opacity)
            }
        }
    }
}
