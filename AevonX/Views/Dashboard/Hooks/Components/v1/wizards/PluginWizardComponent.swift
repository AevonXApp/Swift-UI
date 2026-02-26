//
//  PluginWizardComponent.swift
//  AevonX
//
//  Multi-step wizard component for guided setup flows.
//  Developers define steps in JSON with form fields, validation, and commands.
//

import SwiftUI
import AevonXCore

struct PluginWizardComponent: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @State private var currentStepIndex: Int = 0
    @State private var formValues: [String: String] = [:]
    @State private var stepResults: [String: Bool] = [:]
    @State private var isExecuting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isCompleted: Bool = false
    @StateObject private var vm = HookPluginViewModel()

    private var steps: [HookWizardStep] { plugin.steps ?? [] }
    private var currentStep: HookWizardStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    private var isLastStep: Bool { currentStepIndex == steps.count - 1 }
    private var canGoBack: Bool { currentStepIndex > 0 }

    var body: some View {
        VStack(spacing: 0) {
            wizardHeader

            Divider().background(Color.axBorder)

            if isCompleted {
                completedView
            } else if let step = currentStep {
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.xl) {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            HStack(spacing: AXSpacing.sm) {
                                if let icon = step.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.axAccentBlue)
                                }
                                Text(step.title)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                            }
                            if let desc = step.description {
                                Text(desc)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                            }
                        }
                        .padding(.horizontal, AXSpacing.xxl)
                        .padding(.top, AXSpacing.xl)

                        if let fields = step.fields, !fields.isEmpty {
                            VStack(spacing: AXSpacing.lg) {
                                ForEach(fields, id: \.key) { field in
                                    wizardField(field)
                                }
                            }
                            .padding(.horizontal, AXSpacing.xxl)
                        }

                        if let error = errorMessage {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.axError)
                                Text(error)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axError)
                            }
                            .padding(AXSpacing.md)
                            .background(Color.axError.opacity(0.08))
                            .cornerRadius(AXCornerRadius.sm)
                            .padding(.horizontal, AXSpacing.xxl)
                        }

                        Spacer(minLength: AXSpacing.xxl)
                    }
                }

                Divider().background(Color.axBorder)

                HStack(spacing: AXSpacing.md) {
                    if canGoBack {
                        Button(action: goBack) {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Spacer()

                    Button(action: { Task { await goNext() } }) {
                        HStack(spacing: AXSpacing.xs) {
                            if isExecuting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                            Text(isLastStep ? "Complete" : "Next")
                            if !isLastStep {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.xl)
                        .padding(.vertical, AXSpacing.sm)
                        .background(isExecuting ? Color.axAccentBlue.opacity(0.6) : Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isExecuting)
                }
                .padding(AXSpacing.lg)
                .background(Color.axBackgroundTertiary)
            }
        }
        .background(Color.axBackground)
    }

    private var wizardHeader: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .foregroundColor(.axAccentBlue)
                }
                Text(plugin.name)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Text("Step \(currentStepIndex + 1) of \(steps.count)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.top, AXSpacing.lg)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axBorder)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axAccentBlue)
                        .frame(width: geo.size.width * CGFloat(currentStepIndex + 1) / CGFloat(max(steps.count, 1)), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.bottom, AXSpacing.md)
        }
    }

    private var completedView: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.axSuccess)
            Text("Setup Complete!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.axTextPrimary)
            if let desc = plugin.description {
                Text(desc)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xxl)
    }

    @ViewBuilder
    private func wizardField(_ field: HookFormField) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(field.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.axTextSecondary)
                .textCase(.uppercase)
                .tracking(0.3)

            switch field.type {
            case .text, .password, .number:
                TextField(field.placeholder ?? "", text: binding(for: field.key))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AXTypography.body)
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            case .textarea:
                TextEditor(text: binding(for: field.key))
                    .font(AXTypography.body)
                    .frame(minHeight: 80)
                    .padding(AXSpacing.xs)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            case .toggle:
                Toggle(isOn: Binding(
                    get: { formValues[field.key] == "true" },
                    set: { formValues[field.key] = $0 ? "true" : "false" }
                )) {
                    EmptyView()
                }
                .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
            case .select:
                if let options = field.options {
                    Picker("", selection: binding(for: field.key)) {
                        ForEach(options, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            default:
                TextField(field.placeholder ?? "", text: binding(for: field.key))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AXTypography.body)
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            }

            if let hint = field.helpText {
                Text(hint)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
        }
    }

    private func goBack() {
        guard canGoBack else { return }
        errorMessage = nil
        withAnimation { currentStepIndex -= 1 }
    }

    private func goNext() async {
        guard let step = currentStep else { return }
        errorMessage = nil

        if let validation = step.validation, let required = validation.required {
            for key in required {
                if formValues[key]?.isEmpty ?? true {
                    errorMessage = "Please fill in all required fields"
                    return
                }
            }
        }

        if let cmd = step.command {
            isExecuting = true
            await vm.execute(
                command: cmd,
                pluginId: plugin.id,
                serverId: serverId,
                context: context.merging(formValues) { _, new in new },
                namespace: plugin.namespace
            )
            isExecuting = false

            if vm.errorMessage != nil {
                errorMessage = vm.errorMessage
                return
            }
            stepResults[step.title] = true
        }

        if isLastStep {
            withAnimation { isCompleted = true }
        } else {
            withAnimation { currentStepIndex += 1 }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { formValues[key] ?? "" },
            set: { formValues[key] = $0 }
        )
    }
}
