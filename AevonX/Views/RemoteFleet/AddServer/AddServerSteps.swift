//
//  AddServerSteps.swift
//  AevonX
//

import SwiftUI
import AevonXCore

// MARK: - Identity Step
struct AddServerIdentityStep: View {
    @ObservedObject var viewModel: AddServerViewModel
    
    var body: some View {
        GlassCard(icon: "tag.fill", title: "Server Identity", iconColor: .axAccentBlue) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: "Server Name",
                    text: $viewModel.name,
                    placeholder: "My Production Server",
                    icon: "text.cursor"
                )
                
                // Icon Picker
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "app.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text("Icon")
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
                        Text("Color")
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
        GlassCard(icon: "network", title: "Connection Details", iconColor: .axAccentGreen) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: "Host",
                    text: $viewModel.host,
                    placeholder: "server.example.com",
                    icon: "globe"
                )
                
                HStack(spacing: AXSpacing.md) {
                    PremiumTextField(
                        title: "Port",
                        text: Binding(
                            get: { String(viewModel.port) },
                            set: { viewModel.port = Int($0) ?? 22 }
                        ),
                        placeholder: "22",
                        icon: "number"
                    )
                    .frame(maxWidth: 100)
                    
                    PremiumTextField(
                        title: "Username",
                        text: $viewModel.username,
                        placeholder: "root",
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
        GlassCard(icon: "key.fill", title: "Authentication", iconColor: .orange) {
            VStack(spacing: AXSpacing.lg) {
                // Auth Type Selector
                AuthTypePicker(selection: $viewModel.authType)
                
                // Auth Fields
                if viewModel.authType == .password {
                    PremiumSecureField(
                        title: "Password",
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
                            Text("Private Key")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
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
                                                Text("Paste your private key here...")
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
