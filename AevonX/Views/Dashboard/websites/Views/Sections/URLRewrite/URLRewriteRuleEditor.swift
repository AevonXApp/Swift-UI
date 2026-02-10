//
//  URLRewriteRuleEditor.swift
//  AevonX
//
//  Editor sheet for creating/editing URL rewrite rules
//

import SwiftUI
import AevonXCore

struct URLRewriteRuleEditor: View {
    @Binding var rule: URLRewriteRule?
    let onSave: (URLRewriteRule) -> Void
    let onCancel: () -> Void

    @State private var sourcePattern: String = ""
    @State private var destination: String = ""
    @State private var selectedStatusCode: Int = 301
    @State private var isEnabled: Bool = true
    @State private var notes: String = ""
    @State private var isRegex: Bool = false

    let statusCodes = [301, 302, 307, 308]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.axTextSecondary)

                Spacer()

                Text(rule == nil ? "Add Rewrite Rule" : "Edit Rewrite Rule")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Button("Save") {
                    saveRule()
                }
                .foregroundColor(.axAccentBlue)
                .fontWeight(.semibold)
                .disabled(!isValid)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    // Source Pattern
                    FormSection(title: "Source Pattern", subtitle: "The URL pattern to match") {
                        TextField("e.g., ^/old-path$ or /old-page", text: $sourcePattern)
                            .textFieldStyle(AXTextFieldStyle())

                        Toggle("Use Regex Pattern", isOn: $isRegex)
                            .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))

                        if isRegex {
                            Text("Regex tips: Use ^ for start, $ for end, .* for any characters")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .padding(.top, 4)
                        }
                    }

                    // Destination
                    FormSection(title: "Destination URL", subtitle: "Where to redirect or rewrite to") {
                        TextField("e.g., /new-path or https://example.com/page", text: $destination)
                            .textFieldStyle(AXTextFieldStyle())

                        Text("Use $1, $2 for regex capture groups")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }

                    // Status Code
                    FormSection(title: "Redirect Type", subtitle: "HTTP status code for redirect") {
                        Picker("Status Code", selection: $selectedStatusCode) {
                            ForEach(statusCodes, id: \.self) { code in
                                Text(statusCodeLabel(code))
                                    .tag(code)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(statusCodeDescription(selectedStatusCode))
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                            .padding(.top, 4)
                    }

                    // Notes
                    FormSection(title: "Notes", subtitle: "Optional description for this rule") {
                        TextField("e.g., Redirect old blog posts", text: $notes)
                            .textFieldStyle(AXTextFieldStyle())
                    }

                    // Status Toggle
                    FormSection(title: "Status", subtitle: "Enable or disable this rule") {
                        Toggle("Rule Enabled", isOn: $isEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
                    }

                    // Preview
                    if !sourcePattern.isEmpty && !destination.isEmpty {
                        rulePreview
                    }
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .frame(width: 600, height: 700)
        .onAppear {
            loadRule()
        }
    }

    // MARK: - Rule Preview

    private var rulePreview: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Preview")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.xs) {
                    Text(sourcePattern)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.axTextPrimary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextTertiary)

                    Text(destination)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                }

                HStack(spacing: AXSpacing.sm) {
                    StatusCodeBadge(code: selectedStatusCode)

                    Text(isRegex ? "Regex" : "Literal")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)

                    Circle()
                        .fill(isEnabled ? Color.axSuccess : Color.axTextMuted)
                        .frame(width: 8, height: 8)

                    Text(isEnabled ? "Enabled" : "Disabled")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func loadRule() {
        guard let existingRule = rule else { return }
        sourcePattern = existingRule.sourcePattern
        destination = existingRule.destination
        selectedStatusCode = existingRule.statusCode
        isEnabled = existingRule.isEnabled
        notes = existingRule.notes ?? ""
        isRegex = existingRule.isRegex
    }

    private func saveRule() {
        let newRule = URLRewriteRule(
            id: rule?.id ?? UUID(),
            sourcePattern: sourcePattern,
            destination: destination,
            statusCode: selectedStatusCode,
            flags: isRegex ? ["R"] : [],
            conditions: [],
            isEnabled: isEnabled,
            order: rule?.order ?? 0,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(newRule)
    }

    private var isValid: Bool {
        !sourcePattern.isEmpty && !destination.isEmpty
    }

    private func statusCodeLabel(_ code: Int) -> String {
        switch code {
        case 301: return "301"
        case 302: return "302"
        case 307: return "307"
        case 308: return "308"
        default: return "\(code)"
        }
    }

    private func statusCodeDescription(_ code: Int) -> String {
        switch code {
        case 301: return "Permanent redirect - Cached by browsers"
        case 302: return "Temporary redirect - Not cached"
        case 307: return "Temporary redirect - Preserves method"
        case 308: return "Permanent redirect - Preserves method"
        default: return ""
        }
    }
}

// MARK: - Form Section Component

struct FormSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    init(title: String, subtitle: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)

                Text(subtitle)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            content()
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
