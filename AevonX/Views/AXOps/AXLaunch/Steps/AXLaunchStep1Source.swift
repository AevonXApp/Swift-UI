//
//  AXLaunchStep1Source.swift
//  AevonX
//
//  Step 1: Select project folder (drag & drop or file picker).
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

            dropZone
            selectedFolderInfo
            Spacer()
        }
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 36))
                .foregroundStyle(isDragTarget ? Color.axAccentBlue : Color.axTextMuted)

            Text(L10n.AXLaunch.dragDrop)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)

            Text(L10n.AXLaunch.or)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            Button(action: { viewModel.selectFolder() }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "folder")
                    Text(L10n.AXLaunch.chooseFolder)
                }
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
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

    @ViewBuilder
    private var selectedFolderInfo: some View {
        if !viewModel.localPath.isEmpty {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "folder.fill")
                    .foregroundColor(.axAccentBlue)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(viewModel.localFolderName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                    Text(viewModel.localPath)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button {
                    viewModel.localPath = ""
                    viewModel.localFolderName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        }
    }

    // MARK: - Drop Handler

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.hasDirectoryPath else { return }
            DispatchQueue.main.async {
                viewModel.setLocalPath(url.path)
            }
        }
        return true
    }
}
