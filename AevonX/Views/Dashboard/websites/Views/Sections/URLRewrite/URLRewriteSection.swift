//
//  URLRewriteSection.swift
//  AevonX
//
//  URL Rewrite management section - Main view
//

import SwiftUI
import AevonXCoreBridge

struct URLRewriteSection: View {
    @ObservedObject var viewModel: URLRewriteViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Header
                sectionHeader

                // Quick Actions
                quickActions

                // Rules List
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.rules.isEmpty {
                    emptyStateView
                } else {
                    rulesListView
                }

                Divider()
                    .padding(.vertical, AXSpacing.md)

                // Rewrite Tester
                rewriteTesterView
            }
            .padding(AXSpacing.xl)
        }
        .sheet(isPresented: $viewModel.isEditingRule) {
            URLRewriteRuleEditor(
                rule: $viewModel.selectedRule,
                onSave: { rule in
                    Task {
                        if let existing = viewModel.selectedRule, viewModel.rules.contains(where: { $0.id == existing.id }) {
                            await viewModel.updateRule(existing.id, with: rule)
                        } else {
                            await viewModel.addRule(rule)
                        }
                        viewModel.isEditingRule = false
                    }
                },
                onCancel: {
                    viewModel.isEditingRule = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showTemplateSheet) {
            URLRewriteTemplateSelector(
                viewModel: viewModel,
                onCancel: {
                    viewModel.showTemplateSheet = false
                }
            )
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Websites.urlRewriteRules)
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Websites.manageRedirectsAndUrlRewritingForYourWebsite)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()

            if !viewModel.rules.isEmpty {
                Text("\(viewModel.rules.count) rules")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: AXSpacing.md) {
            Button(action: {
                viewModel.selectedRule = nil
                viewModel.isEditingRule = true
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.Website.addRule)
                }
            }
            .buttonStyle(AXPrimaryButtonStyle())

            Button(action: {
                viewModel.showTemplateSheet = true
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "doc.text.fill")
                    Text(L10n.Website.browseTemplates)
                }
            }
            .buttonStyle(AXSecondaryButtonStyle())

            Spacer()

            Button(action: {
                Task { await viewModel.load() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(L10n.Websites.loadingRewriteRules)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            }
            .padding(AXSpacing.xxl)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "arrow.triangle.turn.up.right.circle")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axTextMuted)

            VStack(spacing: AXSpacing.xs) {
                Text(L10n.Websites.noRewriteRules)
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)

                Text(L10n.Websites.addYourFirstRewriteRuleOrUseATemplateToGetStarted)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: AXSpacing.md) {
                Button(L10n.Website.addRule) {
                    viewModel.selectedRule = nil
                    viewModel.isEditingRule = true
                }
                .buttonStyle(AXPrimaryButtonStyle())

                Button(L10n.Website.browseTemplates) {
                    viewModel.showTemplateSheet = true
                }
                .buttonStyle(AXSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.xxl)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
    }

    // MARK: - Rules List

    private var rulesListView: some View {
        VStack(spacing: AXSpacing.md) {
            ForEach(viewModel.rules.sorted { $0.order < $1.order }) { rule in
                URLRewriteRuleRow(
                    rule: rule,
                    onEdit: {
                        viewModel.selectedRule = rule
                        viewModel.isEditingRule = true
                    },
                    onDelete: {
                        Task { await viewModel.deleteRule(rule.id) }
                    },
                    onToggle: {
                        Task { await viewModel.toggleRule(rule.id) }
                    }
                )
            }
        }
    }

    // MARK: - Rewrite Tester

    private var rewriteTesterView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(L10n.Websites.testRewriteRules)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            Text(L10n.Websites.enterAUrlToTestHowItWillBeRewritten)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            HStack(spacing: AXSpacing.md) {
                TextField("https://example.com/old-path", text: $viewModel.testURL)
                    .textFieldStyle(AXTextFieldStyle())
                    .frame(maxWidth: .infinity)

                Button(action: {
                    Task { await viewModel.testRewrite() }
                }) {
                    HStack(spacing: AXSpacing.sm) {
                        if viewModel.isTesting {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(L10n.Websites.test)
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(viewModel.testURL.isEmpty || viewModel.isTesting)
            }

            if let result = viewModel.testResult {
                URLRewriteTestResult(result: result)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }
}

// MARK: - Rule Row Component

struct URLRewriteRuleRow: View {
    let rule: URLRewriteRule
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Status Toggle
            Button(action: onToggle) {
                Circle()
                    .fill(rule.isEnabled ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(PlainButtonStyle())

            // Rule Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: AXSpacing.sm) {
                    Text(rule.sourcePattern)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)

                    Image(systemName: "arrow.right")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)

                    Text(rule.destination)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                        .lineLimit(1)
                }

                HStack(spacing: AXSpacing.sm) {
                    StatusCodeBadge(code: rule.statusCode)

                    Text(rule.ruleType)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)

                    if !rule.flags.isEmpty {
                        ForEach(rule.flags.prefix(3), id: \.self) { flag in
                            FlagBadge(flag: flag)
                        }
                    }

                    if let notes = rule.notes, !notes.isEmpty {
                        Text("•")
                            .foregroundColor(.axTextMuted)
                        Text(notes)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Actions
            HStack(spacing: AXSpacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.axAccentBlue)
                        .font(AXTypography.title2)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.axError)
                        .font(AXTypography.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.md)
        .background(rule.isEnabled ? Color.axSurface : Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(rule.isEnabled ? Color.axBorder : Color.axBorder.opacity(0.5), lineWidth: 1)
        )
        .opacity(rule.isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Status Code Badge

struct StatusCodeBadge: View {
    let code: Int

    var color: Color {
        switch code {
        case 200..<300: return .axSuccess
        case 300..<400: return .axAccentBlue
        case 400..<500: return .axWarning
        case 500..<600: return .axError
        default: return .axTextMuted
        }
    }

    var body: some View {
        Text("\(code)")
            .font(AXTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
    }
}

// MARK: - Flag Badge

struct FlagBadge: View {
    let flag: String

    var body: some View {
        Text(flag)
            .font(AXTypography.caption)
            .foregroundColor(.axTextSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
    }
}

// MARK: - Test Result Component

struct URLRewriteTestResult: View {
    let result: RewriteTestResult

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Image(systemName: result.wasRewritten ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.wasRewritten ? .axSuccess : .axTextMuted)

                Text(result.wasRewritten ? "URL was rewritten" : "URL was not rewritten")
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
            }

            if result.wasRewritten {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(L10n.Websites.original)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        Text(result.inputURL)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                    }

                    HStack {
                        Text(L10n.Websites.rewritten)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        Text(result.finalURL)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                    }
                }
            }
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(result.wasRewritten ? Color.axSuccess.opacity(0.1) : Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }
}
