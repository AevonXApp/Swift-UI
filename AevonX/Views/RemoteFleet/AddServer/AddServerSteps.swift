//
//  AddServerSteps.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

import UniformTypeIdentifiers

// MARK: - Identity Step
struct AddServerIdentityStep: View {
    @ObservedObject var viewModel: AddServerViewModel
    
    var body: some View {
        GlassCard(icon: "tag.fill", title: L10n.Fleet.serverIdentity, iconColor: .axAccentBlue) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: L10n.Field.serverName,
                    text: $viewModel.name,
                    placeholder: "My Production Server",
                    icon: "text.cursor"
                )
                
                // Encryption notice for server name
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                    Text(L10n.Fleet.serverNameHelp)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                .padding(.top, -AXSpacing.sm)
                
                // Icon Picker
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "app.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text(L10n.Field.icon)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.sm) {
                            ForEach(ServerIcon.allCases) { icon in
                                Button {
                                    viewModel.selectedIcon = icon
                                } label: {
                                    Image(systemName: icon.rawValue)
                                        .font(.system(size: 18))
                                        .foregroundColor(viewModel.selectedIcon == icon ? .white : .axTextSecondary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .fill(viewModel.selectedIcon == icon ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Color Picker
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text(L10n.Field.color)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    HStack(spacing: AXSpacing.sm) {
                        ForEach(ServerColor.allCases) { color in
                            Button {
                                viewModel.selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color.rawValue))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: viewModel.selectedColor == color ? 2 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                                    .overlay {
                                        if viewModel.selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                PremiumTextField(
                    title: "Tags",
                    text: $viewModel.tagsText,
                    placeholder: "production, web, database",
                    icon: "tag",
                    isOptional: true
                )
            }
        }
    }
}

// MARK: - Connection Step
struct AddServerConnectionStep: View {
    @ObservedObject var viewModel: AddServerViewModel
    
    var body: some View {
        GlassCard(icon: "network", title: L10n.Fleet.connectionDetails, iconColor: .axAccentGreen) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: L10n.Field.host,
                    text: $viewModel.host,
                    placeholder: L10n.Field.hostPlaceholder,
                    icon: "globe"
                )
                
                HStack(spacing: AXSpacing.md) {
                    PremiumTextField(
                        title: L10n.Field.port,
                        text: Binding(
                            get: { String(viewModel.port) },
                            set: { viewModel.port = Int($0) ?? 22 }
                        ),
                        placeholder: "22",
                        icon: "number"
                    )
                    .frame(maxWidth: 100)
                    
                    PremiumTextField(
                        title: L10n.Field.username,
                        text: $viewModel.username,
                        placeholder: L10n.Field.usernamePlaceholder,
                        icon: "person"
                    )
                }
            }
        }
    }
}

// MARK: - Authentication Step
struct AddServerAuthStep: View {
    @ObservedObject var viewModel: AddServerViewModel
    
    var body: some View {
        GlassCard(icon: "key.fill", title: L10n.Fleet.authentication, iconColor: .orange) {
            VStack(spacing: AXSpacing.lg) {
                // Auth Type Selector
                AuthTypePicker(selection: $viewModel.authType)
                
                // Auth Fields
                if viewModel.authType == .password {
                    PremiumSecureField(
                        title: L10n.Field.password,
                        text: $viewModel.password,
                        placeholder: "Enter SSH password",
                        icon: "lock.fill"
                    )
                } else {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextMuted)
                            Text(L10n.Field.privateKey)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            
                            Spacer()
                            
                            // File import button
                            Button {
                                viewModel.showSSHKeyFilePicker = true
                            } label: {
                                HStack(spacing: AXSpacing.xs) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 11))
                                    Text(viewModel.sshKeyFileName ?? "Import File")
                                        .font(AXTypography.caption)
                                        .lineLimit(1)
                                }
                                .foregroundColor(.axAccentBlue)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xxs)
                                .background(Color.axAccentBlue.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        TextEditor(text: $viewModel.privateKey)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100, maxHeight: 150)
                            .padding(AXSpacing.md)
                            .background(Color.axBackgroundTertiary)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if viewModel.privateKey.isEmpty {
                                        VStack {
                                            HStack {
                                                Text(L10n.Fleet.pasteYourPrivateKeyOrImportAFile)
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(.axTextMuted)
                                                    .padding(.top, AXSpacing.md)
                                                    .padding(.leading, AXSpacing.md + 5)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .allowsHitTesting(false)
                            )
                    }
                    .fileImporter(
                        isPresented: $viewModel.showSSHKeyFilePicker,
                        allowedContentTypes: [.item],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                viewModel.importSSHKeyFile(from: url)
                            }
                        case .failure(let error):
                            viewModel.errorMessage = "Failed to import key file: \(error.localizedDescription)"
                            viewModel.showError = true
                        }
                    }
                    
                    PremiumSecureField(
                        title: "Key Passphrase",
                        text: $viewModel.keyPassphrase,
                        placeholder: "Optional passphrase",
                        icon: "lock.shield",
                        isOptional: true
                    )
                }
            }
        }
    }
}

// MARK: - Verify Step
struct AddServerVerifyStep: View {
    @ObservedObject var viewModel: AddServerViewModel
    
    var body: some View {
        GlassCard(icon: "wifi", title: "Connection Test", iconColor: .purple) {
            VStack(spacing: AXSpacing.md) {
                // Test Button
                Button {
                    Task {
                        await viewModel.testConnection()
                    }
                } label: {
                    HStack(spacing: AXSpacing.sm) {
                        if viewModel.isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text(viewModel.isTesting ? "Testing..." : "Test Connection")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.md)
                    .background(
                        Group {
                            if viewModel.canTest {
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.axTextMuted
                            }
                        }
                    )
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isTesting || !viewModel.canTest)
                
                // Progress
                if let progress = viewModel.connectionProgress {
                    PremiumProgressView(progress: progress)
                }
                
                // Result
                if let result = viewModel.testResult {
                    PremiumResultView(result: result)
                }
            }
        }
    }
}
