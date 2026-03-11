//
//  DBImportSQLView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge
import UniformTypeIdentifiers

struct DBImportSQLView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var sqlContent = ""
    @State private var selectedFileName: String?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            importHeader
            Divider()
            importContent
            Divider()
            importFooter
        }
        .frame(width: 650, height: 500)
        .background(Color.axBackground)
    }

    private var importHeader: some View {
        HStack {
            Text("Import SQL")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("into \(viewModel.database.name)")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showImportSQL = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    private var importContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // File picker
            HStack(spacing: AXSpacing.md) {
                Button {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [UTType(filenameExtension: "sql") ?? .plainText]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        selectedFileName = url.lastPathComponent
                        if let data = try? String(contentsOf: url, encoding: .utf8) {
                            sqlContent = data
                        }
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 12))
                        Text("Choose .sql File")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.database.type.brandColor)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(viewModel.database.type.brandColor.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)

                if let name = selectedFileName {
                    Text(name)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
            }

            Text("Or paste SQL content below:")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            TextEditor(text: $sqlContent)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
        .padding(AXSpacing.xl)
    }

    private var importFooter: some View {
        HStack {
            Text("\(sqlContent.count) characters")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showImportSQL = false } label: {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
            }
            .buttonStyle(.plain)

            Button {
                isSubmitting = true
                Task {
                    await viewModel.importSQL(sqlContent)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting { ProgressView().scaleEffect(0.7).tint(.axBackground) }
                    Text(isSubmitting ? "Importing..." : "Import")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(sqlContent.isEmpty || isSubmitting ? Color.axTextMuted.opacity(0.5) : Color.axAccentGreen)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(sqlContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        }
        .padding(AXSpacing.xl)
    }
}
