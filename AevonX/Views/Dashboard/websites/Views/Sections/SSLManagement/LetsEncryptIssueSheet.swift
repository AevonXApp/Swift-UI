//
//  LetsEncryptIssueSheet.swift
//  AevonX
//
//  Sheet for issuing Let's Encrypt certificates
//

import SwiftUI

struct LetsEncryptIssueSheet: View {
    @ObservedObject var viewModel: SSLManagementViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    viewModel.showLetsEncryptSheet = false
                }
                .foregroundColor(.axTextSecondary)

                Spacer()

                Text("Issue Let's Encrypt Certificate")
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
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.axAccentBlue)
                            .font(.system(size: 24))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Let's Encrypt")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)

                            Text("Free SSL certificates that auto-renew every 90 days")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)

                    // Email
                    FormSection(title: "Email Address", subtitle: "Required for certificate notifications") {
                        TextField("your@email.com", text: $viewModel.letsEncryptEmail)
                            .textFieldStyle(AXTextFieldStyle())
                    }

                    // Challenge Type
                    FormSection(title: "Verification Method", subtitle: "How Let's Encrypt will verify your domain") {
                        VStack(spacing: AXSpacing.sm) {
                            ForEach(SSLChallengeType.allCases, id: \.rawValue) { challenge in
                                ChallengeTypeRow(
                                    challenge: challenge,
                                    isSelected: viewModel.selectedChallengeType == challenge
                                ) {
                                    viewModel.selectedChallengeType = challenge
                                }
                            }
                        }
                    }

                    // Issue Button
                    Button(action: {
                        Task { await viewModel.issueLetsEncryptCertificate() }
                    }) {
                        HStack {
                            if viewModel.isIssuingCertificate {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Issuing Certificate...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Issue Certificate")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(viewModel.letsEncryptEmail.isEmpty || viewModel.isIssuingCertificate)
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Challenge Type Row

struct ChallengeTypeRow: View {
    let challenge: SSLChallengeType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: challenge.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.rawValue)
                        .font(AXTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)

                    Text(challenge.description)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.axAccentBlue)
                }
            }
            .padding(AXSpacing.md)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.axBackground)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
