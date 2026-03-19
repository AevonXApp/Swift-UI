//
//  SiteCloningSection.swift
//  AevonX
//
//  Site cloning, staging, and migration UI
//

import SwiftUI
import AevonXCoreBridge

struct SiteCloningSection: View {
    @ObservedObject var viewModel: SiteCloningViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Clone & Migrate", icon: "doc.on.doc.fill")

                if viewModel.isCloning {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView().scaleEffect(0.8)
                        Text(viewModel.cloningProgress)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }

                // Clone to new domain
                AXConfigCard(icon: "doc.on.doc", title: "Clone Site", subtitle: "Copy this site to a new domain on the same server") {
                    VStack(spacing: AXSpacing.sm) {
                        HStack {
                            Text("Source:")
                                .font(AXTypography.footnote)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .trailing)
                            Text(viewModel.domain)
                                .font(AXTypography.monoMd).fontWeight(.medium)
                                .foregroundColor(.axTextSecondary)
                            Spacer()
                        }
                        HStack {
                            Text("Target:")
                                .font(AXTypography.footnote)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .trailing)
                            TextField("newsite.com", text: $viewModel.targetDomain)
                                .textFieldStyle(.roundedBorder)
                                .font(AXTypography.monoMd)
                        }
                        Button(action: { Task { await viewModel.cloneSite() } }) {
                            Label("Clone Site", systemImage: "doc.on.doc.fill")
                                .font(AXTypography.subheadline).fontWeight(.semibold)
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
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                        Text("Include database in export")
                            .font(AXTypography.subheadline)
                    }
                }
                .toggleStyle(.switch)
                .padding(.horizontal, AXSpacing.md)

                // Clone result
                if let result = viewModel.lastCloneResult {
                    AXConfigCard(icon: "checkmark.circle.fill", title: "Clone Ready", subtitle: "Site cloned successfully") {
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
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextSecondary)
                        Text(path)
                            .font(AXTypography.monoSm)
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
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(AXTypography.title)
                    .foregroundColor(color)
                Text(title)
                    .font(AXTypography.subheadline).fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                Text(subtitle)
                    .font(AXTypography.caption)
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
                .font(AXTypography.footnote).fontWeight(.medium)
                .foregroundColor(.axTextMuted)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(AXTypography.monoMd)
                .foregroundColor(.axTextPrimary)
                .textSelection(.enabled)
        }
    }
}
