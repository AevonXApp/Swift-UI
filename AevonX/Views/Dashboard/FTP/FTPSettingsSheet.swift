//
//  FTPSettingsSheet.swift
//  AevonX
//
//  FTP settings: port change, service control
//

import SwiftUI
import AevonXCoreBridge

struct FTPSettingsSheet: View {
    @ObservedObject var vm: FTPViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var portText = ""
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                    Text("FTP Settings")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.lg)
            
            Divider().background(Color.axBorder)
            
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    // Server Status
                    settingsGroup("Service Status") {
                        HStack(spacing: AXSpacing.lg) {
                            // Status indicator
                            HStack(spacing: AXSpacing.sm) {
                                Circle()
                                    .fill(vm.serverInfo.isRunning ? Color.axSuccess : Color.axError)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: (vm.serverInfo.isRunning ? Color.axSuccess : Color.axError).opacity(0.5), radius: 4)
                                Text(vm.serverInfo.isRunning ? L10n.Status.running : L10n.Status.stopped)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(vm.serverInfo.isRunning ? .axSuccess : .axError)
                            }
                            
                            Spacer()
                            
                            // Version
                            HStack(spacing: AXSpacing.xs) {
                                Text("PureFTPd")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.axAccentGreen)
                                Text(vm.serverInfo.version)
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextTertiary)
                            }
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 4)
                            .background(Color.axAccentGreen.opacity(0.08))
                            .cornerRadius(AXCornerRadius.sm)
                            
                            // Service controls
                            HStack(spacing: AXSpacing.sm) {
                                serviceButton(
                                    label: L10n.Button.start,
                                    icon: "play.fill",
                                    color: .axSuccess,
                                    disabled: vm.serverInfo.isRunning
                                ) {
                                    Task { await vm.startService() }
                                }

                                serviceButton(
                                    label: L10n.Button.stop,
                                    icon: "stop.fill",
                                    color: .axError,
                                    disabled: !vm.serverInfo.isRunning
                                ) {
                                    Task { await vm.stopService() }
                                }

                                serviceButton(
                                    label: L10n.Button.restart,
                                    icon: "arrow.clockwise",
                                    color: .axWarning,
                                    disabled: false
                                ) {
                                    Task { await vm.restartService() }
                                }
                            }
                        }
                    }
                    
                    // Change Port
                    settingsGroup("FTP Port") {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            Text("Change the FTP listening port. Default: 21")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextTertiary)
                            
                            HStack(spacing: AXSpacing.md) {
                                HStack(spacing: AXSpacing.xs) {
                                    Image(systemName: "network")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axTextMuted)
                                    TextField(L10n.Field.port, text: $portText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 13, design: .monospaced))
                                        .frame(width: 80)
                                }
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 8)
                                .background(Color.axBackgroundTertiary)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                                .cornerRadius(AXCornerRadius.sm)
                                
                                Button(action: changePort) {
                                    HStack(spacing: AXSpacing.xs) {
                                        if isSaving {
                                            ProgressView()
                                                .scaleEffect(0.6)
                                                .frame(width: 14, height: 14)
                                        }
                                        Text("Change Port")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AXSpacing.lg)
                                    .padding(.vertical, 7)
                                    .background(Color.axAccentBlue)
                                    .cornerRadius(AXCornerRadius.md)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(portText.isEmpty || isSaving)
                                .opacity(portText.isEmpty ? 0.5 : 1)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // FTP Address info
                    settingsGroup("Connection Info") {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            infoRow("Address", value: vm.serverInfo.ftpAddress)
                            infoRow(L10n.Field.port, value: "\(vm.serverInfo.port)")
                            infoRow("Protocol", value: "FTP / FTPS")
                        }
                    }
                }
                .padding(AXSpacing.lg)
            }
        }
        .frame(width: 560, height: 450)
        .background(Color.axBackground)
        .onAppear {
            portText = "\(vm.serverInfo.port)"
        }
    }
    
    private func changePort() {
        guard let port = Int(portText), port > 0, port <= 65535 else { return }
        isSaving = true
        Task {
            await vm.changePort(to: port)
            isSaving = false
        }
    }
    
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.axTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            content()
                .padding(AXSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axSurface.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                        )
                )
        }
    }
    
    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.axTextTertiary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextPrimary)
            Spacer()
            
            Button(action: {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
                #endif
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 9))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func serviceButton(label: String, icon: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(disabled ? .axTextMuted : color)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 5)
            .background(color.opacity(disabled ? 0.03 : 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(color.opacity(disabled ? 0.1 : 0.2), lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
    }
}
