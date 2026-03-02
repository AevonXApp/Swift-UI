//
//  PluginConfigurationView.swift
//  AevonX
//
//

import SwiftUI
import AevonXCore

struct PluginConfigurationView: View {
    @StateObject var viewModel: PluginConfigurationViewModel
    let onBack: () -> Void
    
    @State private var editMode: ConfigEditMode = .keyValue
    
    private var themeColor: Color {
        if let hex = viewModel.config.configInfo?.color {
            return Color(hex: hex)
        }
        return .axAccentBlue
    }
    
    enum ConfigEditMode {
        case keyValue, raw
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.md) {
                // Back Button
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.axTextSecondary)
                        .padding(8)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Plugin Icon
                if let imageUrl = viewModel.plugin.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(themeColor)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.axBackgroundSecondary)
                    .cornerRadius(AXCornerRadius.sm)
                } else {
                    Image(systemName: "puzzlepiece.fill")
                        .foregroundColor(themeColor)
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .background(Color.axBackgroundSecondary)
                        .cornerRadius(AXCornerRadius.sm)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AXSpacing.sm) {
                        Text("Configure \(viewModel.plugin.name)")
                            .font(AXTypography.headline)
                        
                        if !viewModel.config.version.isEmpty {
                            Text("v\(viewModel.config.version)")
                                .font(AXTypography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeColor.opacity(0.1))
                                .foregroundColor(themeColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let description = viewModel.config.description, !description.isEmpty {
                        Text(description)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(2)
                    } else {
                        Text("Manage plugin settings and behavior")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    if let info = viewModel.config.configInfo {
                        HStack(spacing: AXSpacing.sm) {
                            if let docs = info.docsUrl, let url = URL(string: docs) {
                                Link(destination: url) {
                                    Label("Docs", systemImage: "book.fill")
                                        .font(.caption2)
                                }
                                .buttonStyle(AXLinkButtonStyle())
                            }
                            if let github = info.githubUrl, let url = URL(string: github) {
                                Link(destination: url) {
                                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                        .font(.caption2)
                                }
                                .buttonStyle(AXLinkButtonStyle())
                            }
                            if let discord = info.discordUrl, let url = URL(string: discord) {
                                Link(destination: url) {
                                    Label("Discord", systemImage: "bubble.left.and.bubble.right.fill")
                                        .font(.caption2)
                                }
                                .buttonStyle(AXLinkButtonStyle())
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Picker("", selection: $editMode) {
                    Text("Settings").tag(ConfigEditMode.keyValue)
                    Text("Raw File").tag(ConfigEditMode.raw)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 160)
                
                Button(action: {
                    Task {
                        if editMode == .keyValue {
                            await viewModel.saveConfig()
                        } else {
                            await viewModel.saveRawConfig()
                        }
                    }
                }) {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 60)
                    } else {
                        Text("Save Changes")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(themeColor)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading || viewModel.isSaving)
            }
            .padding(AXSpacing.xl)
            .background(Color.axBackgroundTertiary)
            
            Divider()
                .background(Color.axBorder)
            
            // Notifications
            if let error = viewModel.errorMessage {
                AXBanner(message: error, style: .error)
            }
            if let success = viewModel.successMessage {
                AXBanner(message: success, style: .success)
            }
            
            // Content
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading configuration...")
                        .accentColor(themeColor)
                    Spacer()
                }
            } else {
                if editMode == .keyValue {
                    keyValueEditor
                } else {
                    rawEditor
                }
            }
        }
        .background(Color.axBackground)
        .task {
            await viewModel.loadConfig()
        }
    }
    
    @ViewBuilder
    private var keyValueEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                if viewModel.config.configSchema.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 32))
                            .foregroundColor(.axTextMuted)
                        Text("No configuration schema found")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        
                        Button("Edit Raw File") {
                            editMode = .raw
                        }
                        .buttonStyle(AXSecondaryButtonStyle())
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(viewModel.config.configSchema) { section in
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            Text(section.section)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                                .padding(.bottom, AXSpacing.xs)
                            
                            ForEach(section.fields) { field in
                                fieldRow(for: field, in: section)
                            }
                        }
                        .padding(AXSpacing.lg)
                        .background(Color.axBackgroundSecondary)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                }
                
                if let info = viewModel.config.configInfo, let copyright = info.copyright {
                    let year = String(Calendar.current.component(.year, from: Date()))
                    Text(copyright.replacingOccurrences(of: "{YEAR}", with: year))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .padding(.top, AXSpacing.xl)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(AXSpacing.xl)
        }
    }
    
    @ViewBuilder
    private func fieldRow(for field: ConfigField, in section: ConfigSection) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(field.title ?? field.key)
                        .font(AXTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)
                    
                    if let description = field.description, !description.isEmpty {
                        Text(description)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                // Render control based on type
                switch field.type {
                case .boolean:
                    Toggle("", isOn: Binding(
                        get: { field.value.asBool },
                        set: { newValue in
                            updateField(sectionId: section.id, fieldId: field.id, value: .bool(newValue))
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: themeColor))
                    
                case .text:
                    TextField("", text: Binding(
                        get: { field.value.asString },
                        set: { newValue in
                            updateField(sectionId: section.id, fieldId: field.id, value: .string(newValue))
                        }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .frame(width: 220)
                    
                case .number:
                    TextField("", text: Binding(
                        get: { field.value.asString },
                        set: { newValue in
                            if let intVal = Int(newValue) {
                                updateField(sectionId: section.id, fieldId: field.id, value: .int(intVal))
                            } else if let doubleVal = Double(newValue) {
                                updateField(sectionId: section.id, fieldId: field.id, value: .double(doubleVal))
                            } else {
                                updateField(sectionId: section.id, fieldId: field.id, value: .string(newValue))
                            }
                        }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .frame(width: 120)
                    
                case .options, .select:
                    AXOptionPicker(
                        selectedOption: Binding(
                            get: { field.value.asString },
                            set: { newValue in
                                updateField(sectionId: section.id, fieldId: field.id, value: .string(newValue))
                            }
                        ),
                        options: field.options ?? []
                    )
                    
                case .array:
                    Text(field.value.asString)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(AXSpacing.xs)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.xs)
                        .frame(maxWidth: 220, alignment: .trailing)
                    
                case .password:
                    SecureField("", text: Binding(
                        get: { field.value.asString },
                        set: { newValue in
                            updateField(sectionId: section.id, fieldId: field.id, value: .string(newValue))
                        }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .frame(width: 220)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func updateField(sectionId: String, fieldId: String, value: ConfigValue) {
        if let sectionIndex = viewModel.config.configSchema.firstIndex(where: { $0.id == sectionId }),
           let fieldIndex = viewModel.config.configSchema[sectionIndex].fields.firstIndex(where: { $0.id == fieldId }) {
            viewModel.config.configSchema[sectionIndex].fields[fieldIndex].value = value
        }
    }
    
    @ViewBuilder
    private var rawEditor: some View {
        TextEditor(text: $viewModel.rawContent)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.axTextPrimary)
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .padding(AXSpacing.xl)
    }
}

// MARK: - Supporting Views

struct AXBanner: View {
    let message: String
    let style: BannerStyle
    
    enum BannerStyle {
        case success, error
    }
    
    var body: some View {
        HStack {
            Image(systemName: style == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            Text(message)
                .font(AXTypography.caption)
            Spacer()
        }
        .padding(AXSpacing.md)
        .background(style == .success ? Color.axSuccess.opacity(0.1) : Color.axError.opacity(0.1))
        .foregroundColor(style == .success ? .axSuccess : .axError)
    }
}

struct AXOptionPicker: View {
    @Binding var selectedOption: String
    let options: [String]
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    HStack {
                        Text(option)
                        if option == selectedOption {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedOption)
                    .foregroundColor(.axTextPrimary)
                    .font(AXTypography.body)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.xs)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .frame(width: 220)
        }
        .menuStyle(BorderlessButtonMenuStyle())
    }
}

struct AXLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.axSurface)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
