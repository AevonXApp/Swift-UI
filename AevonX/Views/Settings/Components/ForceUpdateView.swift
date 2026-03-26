//
//  ForceUpdateView.swift
//  AevonX
//
//  Full-screen blocking force update view — cannot be dismissed
//

import SwiftUI

struct ForceUpdateView: View {
    @ObservedObject var updateService: AppUpdateService

    var body: some View {
        ZStack {
            Color.axBackground.edgesIgnoringSafeArea(.all)

            VStack(spacing: AXSpacing.xxxl) {
                Spacer()
                iconSection
                textSection
                actionSection
                Spacer()
                footerSection
            }
            .frame(maxWidth: 440)
            .padding(AXSpacing.xxxxl)
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axWarning.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.xxl)
                    .fill(
                        LinearGradient(
                            colors: [.axWarning, .axWarning.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .axWarning.opacity(0.4), radius: 16, y: 8)

                Image(systemName: "exclamationmark.arrow.circlepath")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Text

    private var textSection: some View {
        VStack(spacing: AXSpacing.md) {
            Text(L10n.Update.required)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)

            if let version = updateService.availableVersion {
                Text(L10n.Update.versionRequired(version.version))
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)

                Text(version.changelog)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, AXSpacing.xs)
            }
        }
    }

    // MARK: - Action

    private var actionSection: some View {
        VStack(spacing: AXSpacing.md) {
            switch updateService.state {
            case .updateAvailable:
                Button(action: { Task { await updateService.downloadUpdate() } }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                        Text(L10n.Update.downloadInstall)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AXCornerRadius.lg)
                    .shadow(color: .axAccentBlue.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)

            case .downloading(let progress):
                VStack(spacing: AXSpacing.sm) {
                    HStack {
                        Text(L10n.Update.downloading)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                    }

                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.axAccentBlue)

                    Text(updateService.formattedDownloadSize)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)

            case .downloaded:
                Button(action: { Task { await updateService.installAndRelaunch() } }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 14))
                        Text(L10n.Update.installRestart)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.axSuccess)
                    .cornerRadius(AXCornerRadius.lg)
                    .shadow(color: .axSuccess.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)

            case .installing:
                HStack(spacing: AXSpacing.sm) {
                    ProgressView()
                        .controlSize(.regular)
                    Text(L10n.Update.installingUpdate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                }
                .frame(height: 44)

            case .error(let msg):
                VStack(spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axError)
                        Text(msg)
                            .font(.system(size: 11))
                            .foregroundColor(.axError)
                    }

                    Button(action: { Task { await updateService.downloadUpdate() } }) {
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
                ProgressView()
                    .controlSize(.regular)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text(L10n.Update.requiredReason)
            .font(.system(size: 10))
            .foregroundColor(.axTextMuted)
            .multilineTextAlignment(.center)
    }
}
