//
//  CerberusCustomRulesView.swift
//  AevonX
//
//  Custom Rules Engine — DSL-based request matching & filtering.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusCustomRulesView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var showAddSheet = false
    @State private var newRuleID = ""
    @State private var newRuleExpression = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                heroHeader
                if viewModel.rulesLoading && viewModel.customRules.isEmpty {
                    skeletonContent
                } else if viewModel.customRules.isEmpty {
                    emptyContent
                } else {
                    statsRow
                    rulesList
                    syntaxReferenceCard
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadCustomRules() }
        .sheet(isPresented: $showAddSheet) { addRuleSheet }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            heroIconBox
            heroTitleGroup
            Spacer()
            if !viewModel.customRules.isEmpty {
                ruleCountBadge
            }
            addRuleButton
        }
    }

    private var heroIconBox: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(
                LinearGradient(
                    colors: [Color.axAccentGreen.opacity(0.2), Color.axAccentBlue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.axAccentGreen)
            )
    }

    private var heroTitleGroup: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text("Custom Rules Engine")
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text("DSL-based request matching & filtering")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    private var ruleCountBadge: some View {
        AXBadge(
            text: "\(viewModel.customRules.count) rule\(viewModel.customRules.count == 1 ? "" : "s")",
            color: .axAccentGreen,
            style: .soft
        )
    }

    private var addRuleButton: some View {
        AXPrimaryButton(
            title: "Add Rule",
            icon: "plus",
            action: { showAddSheet = true },
            accentColor: .axAccentGreen
        )
    }

    // MARK: - Stats Row

    private var enabledCount: Int { viewModel.customRules.filter(\.enabled).count }
    private var disabledCount: Int { viewModel.customRules.count - enabledCount }

    private var statsRow: some View {
        HStack(spacing: AXSpacing.md) {
            statCard(label: "Total Rules", value: "\(viewModel.customRules.count)", color: .axAccentBlue, icon: "list.bullet.rectangle")
            statCard(label: "Enabled", value: "\(enabledCount)", color: .axAccentGreen, icon: "checkmark.shield")
            statCard(label: "Disabled", value: "\(disabledCount)", color: .axTextMuted, icon: "pause.circle")
        }
    }

    private func statCard(label: String, value: String, color: Color, icon: String) -> some View {
        AXGlassCard(padding: AXSpacing.md, cornerRadius: AXCornerRadius.lg) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(value)
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(label)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextTertiary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Rules List

    private var rulesList: some View {
        VStack(spacing: AXSpacing.sm) {
            ForEach(viewModel.customRules) { rule in
                ruleRow(rule)
            }
        }
    }

    private func ruleRow(_ rule: WAFCustomRule) -> some View {
        AXGlassCard(padding: AXSpacing.lg, cornerRadius: AXCornerRadius.lg) {
            HStack(spacing: AXSpacing.md) {
                ruleStatusDot(rule.enabled)
                ruleInfo(rule)
                Spacer()
                actionBadge(rule.action)
                deleteButton(ruleID: rule.ruleID)
            }
        }
    }

    private func ruleStatusDot(_ enabled: Bool) -> some View {
        Circle()
            .fill(enabled ? Color.axAccentGreen : Color.axTextMuted.opacity(0.5))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .fill(enabled ? Color.axAccentGreen.opacity(0.3) : Color.clear)
                    .frame(width: 16, height: 16)
            )
    }

    private func ruleInfo(_ rule: WAFCustomRule) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            Text(rule.ruleID)
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)
            Text(rule.raw)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextSecondary)
                .lineLimit(2)
        }
    }

    private func actionBadge(_ action: String) -> some View {
        AXBadge(
            text: action.uppercased(),
            color: actionColor(action),
            style: .soft
        )
    }

    private func actionColor(_ action: String) -> Color {
        switch action.lowercased() {
        case "block": return .axError
        case "challenge": return .axWarning
        case "log": return .axAccentBlue
        case "allow": return .axAccentGreen
        default: return .axTextMuted
        }
    }

    private func deleteButton(ruleID: String) -> some View {
        Button {
            Task { await viewModel.removeCustomRule(id: ruleID) }
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.axError)
                .frame(width: 30, height: 30)
                .background(Color.axError.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Syntax Reference

    private var syntaxReferenceCard: some View {
        AXGlassCard(padding: AXSpacing.lg, cornerRadius: AXCornerRadius.lg) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.axAccentPurple)
                    Text("Syntax Reference")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextSecondary)
                }
                syntaxExampleBlock
            }
        }
    }

    private var syntaxExampleBlock: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text("WHEN <conditions> THEN <action>")
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axAccentGreen)
            Text("WHEN path.startsWith(\"/api\") AND method == \"POST\" THEN block")
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextTertiary)
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
    }

    // MARK: - Empty State

    private var emptyContent: some View {
        AXEmptyState(
            icon: "doc.text.magnifyingglass",
            title: "No Custom Rules",
            description: "Define DSL-based rules to match and filter incoming requests with precision.",
            actionLabel: "Add Rule",
            action: { showAddSheet = true },
            accentColor: .axAccentGreen
        )
        .padding(.vertical, AXSpacing.xxxxl)
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(Color.axSurface.opacity(0.5))
                        .frame(height: 64)
                        .shimmer()
                }
            }
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axSurface.opacity(0.5))
                    .frame(height: 72)
                    .shimmer()
            }
        }
    }

    // MARK: - Add Rule Sheet

    private var addRuleSheet: some View {
        VStack(spacing: 0) {
            ruleSheetHero
            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
            ruleSheetBody
            Spacer(minLength: 0)
            Rectangle().fill(Color.axBorder.opacity(0.15)).frame(height: 1)
            ruleSheetActions
        }
        .frame(width: 540, height: 460)
        .background(Color.axBackground)
    }

    private var ruleSheetHero: some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.axAccentGreen.opacity(0.2), Color.axAccentGreen.opacity(0.04)],
                            center: .center, startRadius: 0, endRadius: 24
                        )
                    )
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(Color.axAccentGreen.opacity(0.2), lineWidth: 1)
                    .frame(width: 44, height: 44)
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.axAccentGreen)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text("New Custom Rule")
                    .font(AXTypography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text("Define a DSL expression to match and act on requests")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            Spacer()
        }
        .padding(AXSpacing.xl)
        .background(LinearGradient(colors: [Color.axAccentGreen.opacity(0.04), Color.clear], startPoint: .leading, endPoint: .trailing))
    }

    private var ruleSheetBody: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Rule ID
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Rule ID")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextSecondary)
                AXTextField(
                    placeholder: "e.g. block-php-admin",
                    text: $newRuleID,
                    icon: "tag",
                    accentColor: .axAccentGreen
                )
            }

            // Expression
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Rule Expression")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextSecondary)
                AXTextField(
                    placeholder: "WHEN ... THEN ...",
                    text: $newRuleExpression,
                    icon: "chevron.left.forwardslash.chevron.right",
                    accentColor: .axAccentGreen
                )
            }

            // Syntax hint
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.axAccentPurple)
                    Text("Syntax Example")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axAccentPurple)
                }
                Text("WHEN path.startsWith(\"/api\") AND method == \"POST\" THEN block")
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextTertiary)
                    .padding(AXSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            }
            .padding(AXSpacing.md)
            .background(Color.axAccentPurple.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
        .padding(AXSpacing.xl)
    }

    private var ruleSheetActions: some View {
        HStack(spacing: AXSpacing.md) {
            Button { dismissSheet() } label: {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).strokeBorder(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            AXPrimaryButton(
                title: "Add Rule",
                icon: "plus.circle.fill",
                action: {
                    Task {
                        await viewModel.addCustomRule(id: newRuleID, expression: newRuleExpression)
                        dismissSheet()
                    }
                },
                isDisabled: newRuleID.isEmpty || newRuleExpression.isEmpty,
                accentColor: .axAccentGreen
            )
        }
        .padding(AXSpacing.xl)
    }

    private func dismissSheet() {
        showAddSheet = false
        newRuleID = ""
        newRuleExpression = ""
    }
}
