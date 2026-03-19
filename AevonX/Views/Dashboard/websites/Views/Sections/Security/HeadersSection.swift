//
//  HeadersSection.swift
//  AevonX
//
//  Per-site HTTP headers management section
//

import SwiftUI
import AevonXCoreBridge

struct HeadersSection: View {
    @ObservedObject var viewModel: HeadersViewModel
    @State private var showAddHeader = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack {
                    AXSectionTitle(title: "HTTP Headers", icon: "text.badge.plus")
                    Spacer()
                    HStack(spacing: AXSpacing.sm) {
                        Button(action: { Task { await viewModel.runSecurityAudit() } }) {
                            HStack(spacing: 4) {
                                if viewModel.isAuditing {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: "checkmark.shield")
                                }
                                Text("Audit")
                            }
                            .font(AXTypography.subheadline).fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button(action: { Task { await viewModel.applyRecommendedHeaders() } }) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Apply Recommended")
                            }
                            .font(AXTypography.subheadline).fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                // Audit Results
                if !viewModel.auditResults.isEmpty {
                    AXConfigCard(icon: "checkmark.shield", title: "Security Headers Audit", subtitle: "Check which security headers are present") {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.auditResults) { result in
                                HStack {
                                    Image(systemName: result.grade.icon)
                                        .font(AXTypography.body)
                                        .foregroundColor(result.grade.color)
                                        .frame(width: 22)
                                    Text(result.headerName)
                                        .font(AXTypography.callout).fontWeight(.medium)
                                        .foregroundColor(.axTextPrimary)
                                    Spacer()
                                    if let value = result.value {
                                        Text(String(value.prefix(40)))
                                            .font(AXTypography.monoXs)
                                            .foregroundColor(.axTextTertiary)
                                            .lineLimit(1)
                                    } else {
                                        Text(result.grade.rawValue)
                                            .font(AXTypography.footnote).fontWeight(.medium)
                                            .foregroundColor(result.grade.color)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                // Current Headers
                AXConfigCard(icon: "list.bullet", title: "Current Headers (\(viewModel.headers.count))", subtitle: "Headers configured in Nginx site config") {
                    if viewModel.headers.isEmpty {
                        AXPlaceholder(icon: "text.badge.minus", title: "No custom headers configured")
                    } else {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.headers) { header in
                                HStack {
                                    Image(systemName: header.type.icon)
                                        .font(AXTypography.subheadline)
                                        .foregroundColor(header.type.color)
                                        .frame(width: 20)
                                    Text(header.headerName)
                                        .font(AXTypography.monoMd).fontWeight(.semibold)
                                        .foregroundColor(.axAccentBlue)
                                    Spacer()
                                    Text(String(header.headerValue.prefix(50)))
                                        .font(AXTypography.monoSm)
                                        .foregroundColor(.axTextSecondary)
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }
                }

                // Header Types Reference
                AXConfigCard(icon: "book", title: "Header Reference", subtitle: "Available security header types") {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: AXSpacing.sm), GridItem(.flexible(), spacing: AXSpacing.sm)], spacing: AXSpacing.sm) {
                        ForEach(HTTPHeaderType.allCases.filter { $0 != .custom }) { type in
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: type.icon)
                                    .font(AXTypography.headline)
                                    .foregroundColor(type.color)
                                    .frame(width: 28, height: 28)
                                    .background(type.color.opacity(0.12))
                                    .cornerRadius(AXCornerRadius.sm)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(type.rawValue)
                                        .font(AXTypography.subheadline).fontWeight(.semibold)
                                        .foregroundColor(.axTextPrimary)
                                    Text(type.description)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextTertiary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(AXSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadHeaders() } }
    }
}
