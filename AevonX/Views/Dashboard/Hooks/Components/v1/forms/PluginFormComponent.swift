//
//  PluginFormComponent.swift
//  AevonX
//
//  Renders a rich form with typed fields derived from the plugin's `fields`
//  definition. Supports: text, number, password, textarea, select, toggle,
//  date, and slider. Falls back to auto-deriving fields from payload templates
//  when no explicit `fields` array is defined.
//

import SwiftUI
import AevonXCore

// MARK: - Plugin Form Component

public struct PluginFormComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var fieldValues: [String: String] = [:]
    @State private var toggleValues: [String: Bool] = [:]
    @State private var sliderValues: [String: Double] = [:]
    @State private var validationErrors: [String: String] = [:]

    /// Use explicit fields if defined, otherwise fall back to auto-derive
    private var formFields: [HookFormField] {
        if let fields = plugin.fields, !fields.isEmpty {
            return fields
        }
        // Auto-derive from payload templates (legacy support)
        guard let payload = plugin.command?.payload else { return [] }
        return payload.keys.sorted().compactMap { key in
            let templateValue = payload[key]?.stringValue ?? ""
            guard templateValue.contains("{{") else { return nil }
            return HookFormField(key: key, label: key.replacingOccurrences(of: "_", with: " ").capitalized, type: .text, placeholder: extractPlaceholder(from: templateValue))
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            formHeader
                .padding(.horizontal, AXSpacing.lg)
                .padding(.top, AXSpacing.lg)
                .padding(.bottom, AXSpacing.md)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    ForEach(formFields, id: \.key) { field in
                        fieldRow(field)
                    }
                }
                .padding(AXSpacing.lg)
            }

            Divider().opacity(0.4)

            VStack(spacing: AXSpacing.md) {
                if let output = vm.resultOutput, !output.isEmpty {
                    outputView(output)
                }

                if let error = vm.errorMessage {
                    errorView(error)
                }

                submitButton
            }
            .padding(AXSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
        .onAppear { initializeDefaults() }
    }

    // MARK: - Header

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentBlue.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    if let desc = plugin.description {
                        Text(desc)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Field Rendering

    @ViewBuilder
    private func fieldRow(_ field: HookFormField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                if let icon = field.icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
                Text(field.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                if field.required == true {
                    Text("*")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.axError)
                }
                Spacer()
            }

            switch field.type {
            case .text:
                textField(field)
            case .number:
                numberField(field)
            case .password:
                passwordField(field)
            case .textarea:
                textareaField(field)
            case .select, .multiselect:
                selectField(field)
            case .toggle:
                toggleField(field)
            case .date:
                dateField(field)
            case .slider:
                sliderField(field)
            case .tags, .fileSelect:
                textField(field)
            }

            if let help = field.helpText {
                Text(help)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            if let error = validationErrors[field.key] {
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 9))
                    Text(error)
                        .font(.system(size: 10))
                }
                .foregroundColor(.axError)
            }
        }
    }

    // MARK: - Field Types

    private func textField(_ field: HookFormField) -> some View {
        TextField(field.placeholder ?? "", text: binding(for: field.key))
            .font(.system(size: 13))
            .textFieldStyle(.plain)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(validationErrors[field.key] != nil ? Color.axError.opacity(0.6) : Color.axBorder, lineWidth: 1)
            )
    }

    private func numberField(_ field: HookFormField) -> some View {
        HStack {
            TextField(field.placeholder ?? "0", text: binding(for: field.key))
                .font(.system(size: 13, design: .monospaced))
                .textFieldStyle(.plain)

            if let min = field.min, let max = field.max {
                Text("\(Int(min))–\(Int(max))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func passwordField(_ field: HookFormField) -> some View {
        SecureField(field.placeholder ?? "••••••", text: binding(for: field.key))
            .font(.system(size: 13))
            .textFieldStyle(.plain)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
    }

    private func textareaField(_ field: HookFormField) -> some View {
        TextEditor(text: binding(for: field.key))
            .font(.system(size: 12, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(AXSpacing.sm)
            .frame(minHeight: 80, maxHeight: 200)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
    }

    private func selectField(_ field: HookFormField) -> some View {
        let options = field.options ?? []
        let currentValue = fieldValues[field.key] ?? field.defaultValue?.stringValue ?? ""

        return Menu {
            ForEach(options, id: \.value) { option in
                Button(action: { fieldValues[field.key] = option.value }) {
                    HStack {
                        Text(option.label)
                        if currentValue == option.value {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(options.first(where: { $0.value == currentValue })?.label ?? field.placeholder ?? "Select...")
                    .font(.system(size: 13))
                    .foregroundColor(currentValue.isEmpty ? .axTextMuted : .axTextPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
    }

    private func toggleField(_ field: HookFormField) -> some View {
        let isOn = Binding<Bool>(
            get: { toggleValues[field.key] ?? (field.defaultValue?.stringValue == "true") },
            set: { toggleValues[field.key] = $0; fieldValues[field.key] = String($0) }
        )

        return HStack {
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.axAccentBlue)
            Text(isOn.wrappedValue ? "Enabled" : "Disabled")
                .font(.system(size: 12))
                .foregroundColor(isOn.wrappedValue ? .axSuccess : .axTextMuted)
            Spacer()
        }
    }

    private func dateField(_ field: HookFormField) -> some View {
        TextField(field.placeholder ?? "YYYY-MM-DD", text: binding(for: field.key))
            .font(.system(size: 13, design: .monospaced))
            .textFieldStyle(.plain)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
    }

    private func sliderField(_ field: HookFormField) -> some View {
        let minVal = field.min ?? 0
        let maxVal = field.max ?? 100
        let stepVal = field.step ?? 1

        let value = Binding<Double>(
            get: { sliderValues[field.key] ?? (field.defaultValue?.stringValue).flatMap(Double.init) ?? minVal },
            set: {
                sliderValues[field.key] = $0
                fieldValues[field.key] = String(Int($0))
            }
        )

        return VStack(spacing: 4) {
            HStack {
                Text(String(Int(minVal)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                Slider(value: value, in: minVal...maxVal, step: stepVal)
                    .tint(.axAccentBlue)
                Text(String(Int(maxVal)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }
            Text("Current: \(Int(value.wrappedValue))")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.axAccentBlue)
        }
    }

    // MARK: - Output / Error

    private func outputView(_ output: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.axSuccess)
                Text("Output")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axSuccess)
            }
            Text(output.prefix(500))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .lineLimit(8)
        }
    }

    private func errorView(_ error: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(.axError)
            Text(error)
                .font(.system(size: 11))
                .foregroundColor(.axError)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Group {
            if let command = plugin.command {
                Button(action: {
                    guard validateForm() else { return }
                    Task {
                        var mergedContext = context
                        for (key, value) in fieldValues {
                            mergedContext[key] = value
                        }
                        await vm.execute(
                            command: command,
                            pluginId: plugin.id,
                            serverId: serverId,
                            context: mergedContext,
                            namespace: plugin.namespace
                        )
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else if vm.isSuccess {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                        } else if let icon = plugin.icon {
                            Image(systemName: icon)
                                .font(.system(size: 12))
                        }
                        Text(vm.isSuccess ? "Done!" : (plugin.label ?? "Submit"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(vm.isSuccess ? Color.axSuccess : Color.axAccentBlue)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }
        }
    }

    // MARK: - Helpers

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { fieldValues[key] ?? "" },
            set: {
                fieldValues[key] = $0
                validationErrors.removeValue(forKey: key)
            }
        )
    }

    private func initializeDefaults() {
        for field in formFields {
            if let defaultVal = field.defaultValue?.stringValue, !defaultVal.isEmpty {
                if field.type == .toggle {
                    toggleValues[field.key] = defaultVal == "true" || defaultVal == "1"
                    fieldValues[field.key] = defaultVal
                } else if field.type == .slider {
                    sliderValues[field.key] = Double(defaultVal) ?? field.min ?? 0
                    fieldValues[field.key] = defaultVal
                } else {
                    fieldValues[field.key] = defaultVal
                }
            }
        }
    }

    private func validateForm() -> Bool {
        validationErrors = [:]
        var isValid = true

        for field in formFields {
            let value = fieldValues[field.key] ?? ""

            if field.required == true && value.isEmpty && field.type != .toggle {
                validationErrors[field.key] = "\(field.label) is required"
                isValid = false
                continue
            }

            if field.type == .number || field.type == .slider {
                if let numValue = Double(value) {
                    if let min = field.min, numValue < min {
                        validationErrors[field.key] = "Must be at least \(Int(min))"
                        isValid = false
                    }
                    if let max = field.max, numValue > max {
                        validationErrors[field.key] = "Must be at most \(Int(max))"
                        isValid = false
                    }
                } else if !value.isEmpty {
                    validationErrors[field.key] = "Must be a valid number"
                    isValid = false
                }
            }

            if let pattern = field.pattern, !value.isEmpty {
                if value.range(of: pattern, options: .regularExpression) == nil {
                    validationErrors[field.key] = "Invalid format"
                    isValid = false
                }
            }
        }

        return isValid
    }

    private func extractPlaceholder(from template: String) -> String {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        if let range = template.range(of: pattern, options: .regularExpression) {
            return String(template[range])
                .replacingOccurrences(of: "{{", with: "")
                .replacingOccurrences(of: "}}", with: "")
        }
        return template
    }
}
