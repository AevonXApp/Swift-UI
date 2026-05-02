//
//  CustomCertificateUploadSheet.swift
//  AevonX
//
//  Sheet for uploading custom SSL certificates
//

import SwiftUI

struct CustomCertificateUploadSheet: View {
    @ObservedObject var viewModel: SSLManagementViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(L10n.Button.cancel) {
                    viewModel.showCustomCertSheet = false
                }
                .foregroundColor(.axTextSecondary)

                Spacer()

                Text(L10n.Websites.uploadCustomCertificate)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Color.clear.frame(width: 60)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    // Info Box
                    HStack(alignment: .top, spacing: AXSpacing.md) {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(.axWarning)
                            .font(AXTypography.title)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.Websites.uploadRequirements)
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)

                            Text(L10n.Websites.certificateAndPrivateKeyMustBeInPemFormat)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axWarning.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)

                    // Certificate
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text(L10n.Websites.certificateRequired)
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)

                        Text(L10n.Websites.pasteYourSslCertificateInPemFormat)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)

                        TextEditor(text: $viewModel.customCertificate)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 120)
                            .padding(AXSpacing.sm)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }

                    // Private Key
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text(L10n.Websites.privateKeyRequired)
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)

                        Text(L10n.Websites.pasteYourPrivateKeyInPemFormat)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)

                        TextEditor(text: $viewModel.customPrivateKey)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 120)
                            .padding(AXSpacing.sm)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }

                    // Certificate Chain
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text(L10n.Websites.certificateChainOptional)
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)

                        Text(L10n.Websites.caBundleIfRequiredByYourCertificate)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)

                        TextEditor(text: $viewModel.customChain)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 100)
                            .padding(AXSpacing.sm)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }

                    // Upload Button
                    Button(action: {
                        Task { await viewModel.uploadCustomCertificate() }
                    }) {
                        HStack {
                            if viewModel.isUploadingCertificate {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(L10n.Websites.uploading)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                Text(L10n.Websites.uploadCertificate)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(viewModel.customCertificate.isEmpty || viewModel.customPrivateKey.isEmpty || viewModel.isUploadingCertificate)
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .frame(width: 600)
        .fixedSize(horizontal: false, vertical: true)
    }
}
