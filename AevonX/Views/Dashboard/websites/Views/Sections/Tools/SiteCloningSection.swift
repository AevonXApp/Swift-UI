//
//  SiteCloningSection.swift
//  AevonX
//
//  Site cloning, staging, and migration UI
//

import SwiftUI
import AevonXCore

struct SiteCloningSection: View {
    @ObservedObject var viewModel: SiteCloningViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                SectionHeader(title: "Clone & Migrate", icon: "doc.on.doc.fill")

                if viewModel.isCloning {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView().scaleEffect(0.8)
                        Text(viewModel.cloningProgress)
                            .font(.system(size: 12))
                            .foregroundColor(.axAccentBlue)
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }

                // Clone to new domain
                ConfigCard(icon: "doc.on.doc", title: "Clone Site", description: "Copy this site to a new domain on the same server") {
                    VStack(spacing: AXSpacing.sm) {
                        HStack {
                            Text("Source:")
                                .font(.system(size: 11))
                                .foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .trailing)
                            Text(viewModel.domain)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                            Spacer()
                        }
                        HStack {
                            Text("Target:")
                                .font(.system(size: 11))
                                .foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .trailing)
                            TextField("newsite.com", text: $viewModel.targetDomain)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                        }
                        Button(action: { Task { await viewModel.cloneSite() } }) {
                            Label("Clone Site", systemImage: "doc.on.doc.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(viewModel.isCloning || viewModel.targetDomain.isEmpty)
                    }
                }

                // Quick actions row
                HStack(spacing: AXSpacing.md) {
                    // Create staging
                    actionCard(
                        icon: "flask",
                        title: "Create Staging",
                        subtitle: "staging.\(viewModel.domain)",
                        color: .purple,
                        action: { Task { await viewModel.createStaging() } }
                    )

                    // Export for migration
                    actionCard(
                        icon: "arrow.up.doc",
                        title: "Export for Migration",
                        subtitle: "Files + Config + DB",
                        color: .orange,
                        action: { Task { await viewModel.exportForMigration() } }
                    )
                }

                // Include DB toggle
                Toggle(isOn: $viewModel.includeDBInExport) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "cylinder.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.axAccentBlue)
                        Text("Include database in export")
                            .font(.system(size: 12))
                    }
                }
                .toggleStyle(.switch)
                .padding(.horizontal, AXSpacing.md)

                // Clone result
                if let result = viewModel.lastCloneResult {
                    ConfigCard(icon: "checkmark.circle.fill", title: "Clone Ready", description: "Site cloned successfully") {
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            infoRow("Domain", result.domain)
                            infoRow("Path", result.docRoot)
                            infoRow("Size", result.size)
                        }
                    }
                }

                // Export path
                if let path = viewModel.exportPath {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.axSuccess)
                        Text("Export saved: ")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextSecondary)
                        Text(path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                            .textSelection(.enabled)
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axSuccess.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    private func actionCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(AXSpacing.lg)
            .background(color.opacity(0.06))
            .cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isCloning)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.axTextMuted)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .textSelection(.enabled)
        }
    }
}
