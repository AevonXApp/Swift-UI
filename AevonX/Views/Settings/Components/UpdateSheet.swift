//
//  UpdateSheet.swift
//  AevonX
//
//  Update available sheet with changelog and download progress
//

import SwiftUI

struct UpdateSheet: View {
    @ObservedObject var updateService: AppUpdateService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().background(Color.axBorder)
            contentSection
            Divider().background(Color.axBorder)
            actionsSection
        }
        .frame(width: 480, height: 520)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AXSpacing.md) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [.axAccentBlue, .axAccentBlue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .axAccentBlue.opacity(0.3), radius: 12, y: 6)

                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: AXSpacing.xs) {
                Text(titleText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)

                if let version = updateService.availableVersion {
                    HStack(spacing: AXSpacing.sm) {
                        versionPill(label: L10n.Update.versionCurrent, version: currentVersion, color: .axTextMuted)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        versionPill(label: L10n.Update.versionNew, version: version.version, color: .axAccentBlue)
                    }
                }
            }
        }
        .padding(.vertical, AXSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.axSurface.opacity(0.5), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Content

    private var contentSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                if let version = updateService.availableVersion {
                    // Changelog
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Label(L10n.Update.whatsNew, systemImage: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.axTextPrimary)

                        Text(version.changelog)
                            .font(.system(size: 12))
                            .foregroundColor(.axTextSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(AXCornerRadius.md)

                    // Download info
                    HStack(spacing: AXSpacing.xl) {
                        infoItem(icon: "arrow.down.circle", label: L10n.Update.infoSize, value: updateService.formattedDownloadSize)
                        infoItem(icon: "calendar", label: L10n.Update.infoReleased, value: formattedDate(version.releasedAt))

                        if updateService.isForceUpdate {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                Text(L10n.Update.badgeRequired)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.axWarning)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xxs)
                            .background(Color.axWarning.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                        }
                    }

                    // Download progress
                    if case .downloading(let progress) = updateService.state {
                        downloadProgressView(progress: progress)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        HStack(spacing: AXSpacing.md) {
            switch updateService.state {
            case .updateAvailable:
                if !updateService.isForceUpdate {
                    Button(action: { dismiss() }) {
                        Text(L10n.Button.later)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        updateService.skipVersion()
                        dismiss()
                    }) {
                        Text(L10n.Button.skip)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { Task { await updateService.downloadUpdate() } }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                        Text(L10n.Update.downloadInstall)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

            case .downloading:
                Button(action: {}) {
                    HStack(spacing: AXSpacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                        Text(L10n.Update.downloading)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(true)

            case .downloaded:
                if !updateService.isForceUpdate {
                    Button(action: { dismiss() }) {
                        Text(L10n.Button.notNow)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { Task { await updateService.installAndRelaunch() } }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 12))
                        Text(L10n.Update.installRestart)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.axSuccess)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

            case .installing:
                HStack(spacing: AXSpacing.xs) {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.Update.installing)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)

            case .error(let msg):
                VStack(spacing: AXSpacing.xs) {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundColor(.axError)
                        .lineLimit(2)

                    Button(action: { Task { await updateService.checkForUpdate() } }) {
                        Text(L10n.Button.retry)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }

            default:
                EmptyView()
            }
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackgroundTertiary.opacity(0.5))
    }

    // MARK: - Helpers

    private var titleText: String {
        switch updateService.state {
        case .updateAvailable: return L10n.Update.titleAvailable
        case .downloading: return L10n.Update.titleDownloading
        case .downloaded: return L10n.Update.titleReady
        case .installing: return L10n.Update.titleInstalling
        case .error: return L10n.Update.titleError
        default: return L10n.Update.titleGeneric
        }
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func versionPill(label: String, version: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color.opacity(0.7))
                .textCase(.uppercase)
            Text(version)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(color.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func infoItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted)
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
            }
        }
    }

    private func downloadProgressView(progress: Double) -> some View {
        VStack(spacing: AXSpacing.sm) {
            HStack {
                Text(L10n.Update.downloading)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axSurface)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.axAccentBlue, .axAccentBlue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
    }

    private func formattedDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            let df = DateFormatter()
            df.dateStyle = .medium
            return df.string(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: iso) {
            let df = DateFormatter()
            df.dateStyle = .medium
            return df.string(from: date)
        }
        return iso
    }
}
