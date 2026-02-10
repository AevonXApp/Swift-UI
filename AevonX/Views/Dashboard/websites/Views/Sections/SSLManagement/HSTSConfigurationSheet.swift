//
//  HSTSConfigurationSheet.swift
//  AevonX
//
//  Sheet for configuring HSTS (HTTP Strict Transport Security)
//

import SwiftUI

struct HSTSConfigurationSheet: View {
    @ObservedObject var viewModel: SSLManagementViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    viewModel.showHSTSSheet = false
                }
                .foregroundColor(.axTextSecondary)

                Spacer()

                Text("HSTS Configuration")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Color.clear.frame(width: 60)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    // Info Box
                    HStack(alignment: .top, spacing: AXSpacing.md) {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(.axAccentBlue)
                            .font(.system(size: 24))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("HTTP Strict Transport Security")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)

                            Text("Forces browsers to only use HTTPS connections")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)

                    // Enable HSTS
                    FormSection(title: "Enable HSTS", subtitle: "Turn on HTTP Strict Transport Security") {
                        Toggle("Enable HSTS", isOn: $viewModel.hstsConfig.enabled)
                            .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
                    }

                    if viewModel.hstsConfig.enabled {
                        // Max Age
                        FormSection(title: "Max Age", subtitle: "How long browsers should remember HSTS") {
                            Picker("Max Age", selection: $viewModel.hstsConfig.maxAge) {
                                Text("1 month").tag(2592000)
                                Text("6 months").tag(15768000)
                                Text("1 year").tag(31536000)
                                Text("2 years").tag(63072000)
                            }
                            .pickerStyle(.segmented)

                            Text("Selected: \(viewModel.hstsConfig.formattedMaxAge)")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .padding(.top, 4)
                        }

                        // Include Subdomains
                        FormSection(title: "Include Subdomains", subtitle: "Apply HSTS to all subdomains") {
                            Toggle("Include Subdomains", isOn: $viewModel.hstsConfig.includeSubDomains)
                                .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                        }

                        // Preload
                        FormSection(title: "Preload", subtitle: "Submit to browser preload list (requires includeSubDomains)") {
                            Toggle("Enable Preload", isOn: $viewModel.hstsConfig.preload)
                                .toggleStyle(SwitchToggleStyle(tint: .axWarning))
                                .disabled(!viewModel.hstsConfig.includeSubDomains)

                            if viewModel.hstsConfig.preload {
                                HStack(alignment: .top, spacing: AXSpacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.axWarning)
                                        .font(.system(size: 12))

                                    Text("Preload is a permanent commitment. Removal from the preload list can take months.")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axWarning)
                                }
                                .padding(.top, 4)
                            }
                        }

                        // Header Preview
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("HSTS Header Preview")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)

                            Text(viewModel.hstsConfig.headerValue)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }

                    // Save Button
                    Button(action: {
                        Task { await viewModel.configureHSTS() }
                    }) {
                        HStack {
                            if viewModel.isConfiguringHSTS {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Configuring...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Configuration")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(viewModel.isConfiguringHSTS)
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .frame(width: 500, height: 700)
    }
}
