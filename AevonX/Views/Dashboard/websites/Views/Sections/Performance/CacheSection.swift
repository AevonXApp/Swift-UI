//
//  CacheSection.swift
//  AevonX
//
//  Per-site cache management section
//

import SwiftUI
import AevonXCoreBridge

struct CacheSection: View {
    @ObservedObject var viewModel: CacheViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Header
                HStack {
                    AXSectionTitle(title: "Cache Manager", icon: "bolt.circle.fill")
                    Spacer()
                    Button(action: { Task { await viewModel.purgeAllCache() } }) {
                        HStack(spacing: 4) {
                            if viewModel.isPurging {
                                ProgressView().scaleEffect(0.7)
                            } else {
                                Image(systemName: "trash")
                            }
                            Text("Purge All")
                        }
                        .font(AXTypography.subheadline).fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .tint(.axError)
                    .controlSize(.small)
                }

                // Cache Type Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                    ForEach(viewModel.cacheStatuses) { status in
                        cacheCard(status)
                    }
                }

                // Browser Cache Rules
                AXConfigCard(icon: "clock.fill", title: "Browser Cache Rules", subtitle: "Configure Cache-Control and Expires headers") {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(viewModel.browserCacheRules) { rule in
                            HStack {
                                Text(rule.fileTypes)
                                    .font(AXTypography.monoMd)
                                    .foregroundColor(.axAccentBlue)
                                Spacer()
                                Text(rule.duration)
                                    .font(AXTypography.subheadline).fontWeight(.semibold)
                                    .foregroundColor(.axSuccess)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.axSuccess.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                                Text(rule.cacheControl)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.axError)
                        Text(error).font(AXTypography.subheadline).foregroundColor(.axError)
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axError.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadCacheStatus() } }
    }

    private func cacheCard(_ status: SiteCacheStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: status.type.icon)
                    .font(AXTypography.title2)
                    .foregroundColor(status.type.color)
                Spacer()
                Circle()
                    .fill(status.enabled ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 8, height: 8)
            }
            Text(status.type.rawValue)
                .font(AXTypography.callout).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)
            Text(status.enabled ? L10n.Status.active : L10n.Status.inactive)
                .font(AXTypography.footnote)
                .foregroundColor(status.enabled ? .axSuccess : .axTextTertiary)

            Button(action: {
                Task { await viewModel.purgeSpecificCache(status.type) }
            }) {
                Text("Purge")
                    .font(AXTypography.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(!status.enabled)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
    }
}
