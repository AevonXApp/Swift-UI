//
//  SiteConfigSection.swift
//  AevonX
//
//  Site-level Nginx/Apache configuration editor section
//

import SwiftUI
import AevonXCore

struct SiteConfigSection: View {
    @ObservedObject var viewModel: SiteConfigViewModel
    @State private var showTemplates = false
    @State private var showBackups = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Toolbar
                HStack {
                    AXSectionTitle(title: "Server Config", icon: "doc.badge.gearshape.fill")
                    Spacer()
                    HStack(spacing: AXSpacing.sm) {
                        // Templates
                        Button(action: { showTemplates.toggle() }) {
                            Label("Templates", systemImage: "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        // Backups
                        Button(action: { showBackups.toggle() }) {
                            Label("Backups (\(viewModel.configBackups.count))", systemImage: "clock.arrow.circlepath")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        // Validate
                        Button(action: { Task { await viewModel.validateConfig() } }) {
                            HStack(spacing: 4) {
                                if viewModel.isValidating {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: "checkmark.shield")
                                }
                                Text("Validate")
                            }
                            .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        // Save
                        Button(action: { Task { await viewModel.saveConfig() } }) {
                            HStack(spacing: 4) {
                                if viewModel.isSaving {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                }
                                Text("Save & Reload")
                            }
                            .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!viewModel.hasUnsavedChanges || viewModel.isSaving)
                    }
                }

                // Validation Result
                if let result = viewModel.validationResult {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: viewModel.validationPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.validationPassed ? .axSuccess : .axError)
                        Text(result)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(viewModel.validationPassed ? .axSuccess : .axError)
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((viewModel.validationPassed ? Color.axSuccess : Color.axError).opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }

                // Error
                if let error = viewModel.errorMessage {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axError)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.axError)
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axError.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }

                // Config Path Info
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextTertiary)
                    Text(viewModel.configPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                    Spacer()
                    if viewModel.hasUnsavedChanges {
                        Text("● Modified")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.axWarning)
                    }
                }

                // Editor
                if viewModel.isLoading {
                    VStack(spacing: AXSpacing.md) {
                        ProgressView()
                        Text("Loading configuration...")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(AXSpacing.xxl)
                } else {
                    TextEditor(text: $viewModel.configContent)
                        .font(.system(size: 13, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(AXSpacing.md)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                .stroke(viewModel.hasUnsavedChanges ? Color.axWarning.opacity(0.5) : Color.axBorder.opacity(0.5), lineWidth: 1)
                        )
                        .frame(minHeight: 500)
                        .onChange(of: viewModel.configContent) { _, _ in
                            viewModel.contentDidChange()
                        }
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadConfig(); await viewModel.loadBackups() } }
        .sheet(isPresented: $showTemplates) { templateSheet }
        .sheet(isPresented: $showBackups) { backupsSheet }
    }

    // MARK: - Templates Sheet

    private var templateSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Config Templates")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button("Close") { showTemplates = false }
                    .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    ForEach(SiteConfigTemplate.allCases) { template in
                        Button(action: {
                            viewModel.applyTemplate(template, docRoot: "/var/www/\(viewModel.configPath.components(separatedBy: "/").last ?? "site")")
                            showTemplates = false
                        }) {
                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: template.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.axAccentBlue)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.axTextPrimary)
                                    Text(template.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.axTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextMuted)
                            }
                            .padding(AXSpacing.md)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 550)
        .background(Color.axSurface)
    }

    // MARK: - Backups Sheet

    private var backupsSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Config Backups")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button("Close") { showBackups = false }
                    .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if viewModel.configBackups.isEmpty {
                EmptyStateCard(icon: "clock.arrow.circlepath", title: "No Backups", message: "Backups are created automatically before each save")
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(viewModel.configBackups) { backup in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(backup.filename)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                    Text(backup.formattedDate)
                                        .font(.system(size: 10))
                                        .foregroundColor(.axTextTertiary)
                                }
                                Spacer()
                                Button("Restore") {
                                    Task { await viewModel.restoreBackup(backup) }
                                    showBackups = false
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(AXSpacing.md)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 500, height: 450)
        .background(Color.axSurface)
    }
}
