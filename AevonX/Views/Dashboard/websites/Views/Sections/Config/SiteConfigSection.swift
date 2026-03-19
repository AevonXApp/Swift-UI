//
//  SiteConfigSection.swift
//  AevonX
//
//  Site-level Nginx/Apache configuration editor section
//

import SwiftUI
import AevonXCoreBridge

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
                                .font(AXTypography.subheadline).fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        // Backups
                        Button(action: { showBackups.toggle() }) {
                            Label("Backups (\(viewModel.configBackups.count))", systemImage: "clock.arrow.circlepath")
                                .font(AXTypography.subheadline).fontWeight(.medium)
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
                            .font(AXTypography.subheadline).fontWeight(.medium)
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
                            .font(AXTypography.subheadline).fontWeight(.semibold)
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
                            .font(AXTypography.monoMd)
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
                            .font(AXTypography.subheadline)
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
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextTertiary)
                    Text(viewModel.configPath)
                        .font(AXTypography.monoSm)
                        .foregroundColor(.axTextSecondary)
                    Spacer()
                    if viewModel.hasUnsavedChanges {
                        Text("● Modified")
                            .font(AXTypography.caption).fontWeight(.bold)
                            .foregroundColor(.axWarning)
                    }
                }

                // Editor
                if viewModel.isLoading {
                    VStack(spacing: AXSpacing.md) {
                        ProgressView()
                        Text("Loading configuration...")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(AXSpacing.xxl)
                } else {
                    TextEditor(text: $viewModel.configContent)
                        .font(AXTypography.monoMd)
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
                    .font(AXTypography.title3).fontWeight(.bold)
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
                                    .font(AXTypography.title2)
                                    .foregroundColor(.axAccentBlue)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.rawValue)
                                        .font(AXTypography.headline)
                                        .foregroundColor(.axTextPrimary)
                                    Text(template.description)
                                        .font(AXTypography.footnote)
                                        .foregroundColor(.axTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AXTypography.footnote)
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
                    .font(AXTypography.title3).fontWeight(.bold)
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
                                        .font(AXTypography.monoMd).fontWeight(.medium)
                                        .foregroundColor(.axTextPrimary)
                                    Text(backup.formattedDate)
                                        .font(AXTypography.caption)
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
