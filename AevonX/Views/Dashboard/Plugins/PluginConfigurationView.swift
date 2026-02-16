//
//  PluginConfigurationView.swift
//  AevonX
//

import SwiftUI
import AevonXCore

struct PluginConfigurationView: View {
    @StateObject var viewModel: PluginConfigurationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var editMode: ConfigEditMode = .keyValue
    
    enum ConfigEditMode {
        case keyValue, raw
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configure \(viewModel.plugin.name)")
                        .font(AXTypography.headline)
                    Text("Manage plugin settings and behavior")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
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
                            .background(Color.axAccentBlue)
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
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
        .task {
            await viewModel.loadConfig()
        }
    }
    
    private var keyValueEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                if viewModel.config.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 32))
                            .foregroundColor(.axTextMuted)
                        Text("No configuration keys found")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(viewModel.config.keys.sorted(), id: \.self) { key in
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text(key)
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextSecondary)
                            
                            TextField("", text: Binding(
                                get: { viewModel.config[key] ?? "" },
                                set: { viewModel.config[key] = $0 }
                            ))
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(AXSpacing.sm)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.xs)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }
    
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
