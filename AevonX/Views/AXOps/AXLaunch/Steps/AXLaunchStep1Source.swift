//
//  AXLaunchStep1Source.swift
//  AevonX
//
//  Step 1: Select project folder or compressed file.
//

import SwiftUI
import AevonXCoreBridge
import UniformTypeIdentifiers

struct AXLaunchStep1Source: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel
    @State private var isDragTarget = false

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            AXLaunchStepHeader(
                stepIndex: 1, totalSteps: viewModel.totalWizardSteps,
                title: L10n.AXLaunch.stepSelectSource
            )
            sourceTypePicker
            dropZone
            selectedInfo
            Spacer()
        }
    }

    // MARK: - Source Type Picker

    private var sourceTypePicker: some View {
        HStack(spacing: AXSpacing.sm) {
            sourceTypeButton(.folder, L10n.AXLaunch.sourceFolder, "folder.fill")
            sourceTypeButton(.compressed, L10n.AXLaunch.sourceCompressed, "doc.zipper")
        }
    }

    private func sourceTypeButton(
        _ type: AXLaunchWizardViewModel.SourceType,
        _ label: String, _ icon: String
    ) -> some View {
        let isSelected = viewModel.sourceType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.sourceType = type }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(AXTypography.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .axBackground : .axTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
            .background(isSelected ? Color.axAccentBlue : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: viewModel.sourceType == .folder ? "arrow.down.doc.fill" : "doc.zipper")
                .font(.system(size: 36))
                .foregroundStyle(isDragTarget ? Color.axAccentBlue : Color.axTextMuted)

            Text(viewModel.sourceType == .folder ? L10n.AXLaunch.dragDrop : L10n.AXLaunch.dragDropFile)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)

            Text(L10n.AXLaunch.or)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            Button(action: {
                if viewModel.sourceType == .folder {
                    viewModel.selectFolder()
                } else {
                    viewModel.selectFile()
                }
            }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: viewModel.sourceType == .folder ? "folder" : "doc.badge.plus")
                    Text(viewModel.sourceType == .folder ? L10n.AXLaunch.chooseFolder : L10n.AXLaunch.chooseFile)
                }
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)

            if viewModel.sourceType == .compressed {
                Text(L10n.AXLaunch.supportedFormats)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxl)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .strokeBorder(
                    isDragTarget ? Color.axAccentBlue : Color.axBorder,
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(isDragTarget ? Color.axAccentBlue.opacity(0.05) : Color.clear)
                )
        )
        .shadow(color: isDragTarget ? Color.axAccentBlue.opacity(0.3) : .clear, radius: 16)
        .animation(.easeInOut(duration: 0.2), value: isDragTarget)
        .onDrop(of: [.fileURL], isTargeted: $isDragTarget) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Selected Info

    @ViewBuilder
    private var selectedInfo: some View {
        if viewModel.sourceType == .folder && !viewModel.localPath.isEmpty {
            selectedItemRow(
                icon: "folder.fill",
                name: viewModel.localFolderName,
                detail: viewModel.localPath,
                onClear: {
                    viewModel.localPath = ""
                    viewModel.localFolderName = ""
                }
            )
        } else if viewModel.sourceType == .compressed && !viewModel.compressedFilePath.isEmpty {
            selectedItemRow(
                icon: "doc.zipper",
                name: viewModel.compressedFileName,
                detail: viewModel.compressedFilePath,
                onClear: {
                    viewModel.compressedFilePath = ""
                    viewModel.compressedFileName = ""
                }
            )
        }
    }

    private func selectedItemRow(icon: String, name: String, detail: String, onClear: @escaping () -> Void) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.axAccentBlue)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                Text(detail)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Drop Handler

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                if url.hasDirectoryPath {
                    viewModel.sourceType = .folder
                    viewModel.setLocalPath(url.path)
                } else {
                    let ext = url.pathExtension.lowercased()
                    let compressedExts = ["zip", "tar", "gz", "tgz", "bz2", "xz", "rar", "7z"]
                    if compressedExts.contains(ext) {
                        viewModel.sourceType = .compressed
                        viewModel.compressedFilePath = url.path
                        viewModel.compressedFileName = url.lastPathComponent
                        let stem = url.deletingPathExtension().lastPathComponent
                            .replacingOccurrences(of: ".tar", with: "")
                        viewModel.remoteAppName = stem.lowercased().replacingOccurrences(of: " ", with: "-")
                    } else {
                        viewModel.sourceType = .folder
                        viewModel.setLocalPath(url.path)
                    }
                }
            }
        }
        return true
    }
}
