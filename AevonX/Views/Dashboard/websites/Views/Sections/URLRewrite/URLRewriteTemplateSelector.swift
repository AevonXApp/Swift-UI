//
//  URLRewriteTemplateSelector.swift
//  AevonX
//
//  Simple template selector - Just dropdown and code field
//

import SwiftUI

struct URLRewriteTemplateSelector: View {
    @ObservedObject var viewModel: URLRewriteViewModel
    let onCancel: () -> Void

    @State private var selectedTemplate: RewriteRuleTemplate = .laravel
    @State private var ruleCode: String = ""
    @State private var showSuccessMessage: Bool = false
    @State private var isSaving: Bool = false

    private let domain = "example.com"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // Success Message
                    if showSuccessMessage {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.axSuccess)
                                .font(.system(size: 18))

                            Text("Template saved successfully! The rewrite rule has been applied.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button(action: {
                                showSuccessMessage = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.axTextTertiary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(AXSpacing.md)
                        .background(Color.axSuccess.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axSuccess, lineWidth: 1)
                        )
                    }

                    // Template Type Selection
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text("1. Select Template Type")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.axTextPrimary)

                        Picker("Template", selection: $selectedTemplate) {
                            ForEach(RewriteRuleTemplate.allCases, id: \.self) { template in
                                Text(template.rawValue).tag(template)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: selectedTemplate) { _, newTemplate in
                            ruleCode = newTemplate.getRuleCode(domain: domain)
                        }

                        // Description
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.axAccentBlue)
                                .font(.system(size: 12))

                            Text(selectedTemplate.description)
                                .font(.system(size: 12))
                                .foregroundColor(.axTextSecondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.lg)

                    // Code Field
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        HStack {
                            Text("2. Preview Code")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(ruleCode, forType: .string)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        TextEditor(text: $ruleCode)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .frame(minHeight: 120)
                            .padding(AXSpacing.md)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )

                        Text("You can edit the code above before saving")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextSecondary)
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.lg)

                    // Save Button
                    Button(action: {
                        Task {
                            isSaving = true
                            await viewModel.applyTemplate(selectedTemplate)
                            isSaving = false
                            showSuccessMessage = true

                            // Auto-hide success message and close sheet after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                onCancel()
                            }
                        }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isSaving ? "Saving..." : "Save & Apply")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.md)
                        .background(isSaving ? Color.axTextSecondary : Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSaving)
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
            .navigationTitle("URL Rewrite Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .frame(width: 600, height: 520)
        .onAppear {
            ruleCode = selectedTemplate.getRuleCode(domain: domain)
        }
    }
}
