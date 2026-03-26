//
//  DBImportSQLView.swift
//  AevonX
//
//  Premium Import SQL dialog with file picker,
//  AXCodeEditor for SQL content, and character counter.
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
            dialogHeader
            Divider().background(Color.axBorder)
            dialogContent
            Divider().background(Color.axBorder)
            dialogFooter
        }
        .frame(width: 680, height: 530)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var dialogHeader: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axAccentGreen.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "square.and.arrow.down.fill")
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentGreen)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Database.importSQL)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text("into \(viewModel.database.name)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Button { viewModel.showImportSQL = false } label: {
                Image(systemName: "xmark")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Content

    private var dialogContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // File picker row
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
                            .font(AXTypography.caption)
                        Text("Choose .sql File")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if let name = selectedFileName {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "doc.text")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentGreen)
                        Text(name)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                    }
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentGreen.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }

                Spacer()
            }

            Text("Or paste SQL content below:")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            // SQL editor
            TextEditor(text: $sqlContent)
                .font(AXTypography.monoMd)
                .foregroundColor(.axTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(sqlContent.isEmpty ? Color.axBorder : Color.axAccentGreen.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Footer

    private var dialogFooter: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "text.alignleft")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                    Text("\(sqlContent.count) chars")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                if !sqlContent.isEmpty {
                    let lineCount = sqlContent.components(separatedBy: "\n").count
                    Text("\(lineCount) lines")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            Button { viewModel.showImportSQL = false } label: {
                Text(L10n.Button.cancel)
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
                    if isSubmitting {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    }
                    Text(isSubmitting ? "Importing..." : L10n.Database.importSQL)
                }
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(sqlContent.isEmpty || isSubmitting ? Color.axTextMuted.opacity(0.3) : Color.axAccentGreen)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(sqlContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        }
        .padding(AXSpacing.lg)
    }
}
