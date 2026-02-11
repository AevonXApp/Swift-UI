//
//  ApacheConfigurationTab.swift
//  AevonX
//
//  Configuration editor for Apache
//

import SwiftUI
import AevonXCore

struct ApacheConfigurationTab: View {
    let application: ApplicationInstance
    @Binding var apacheConfig: ApacheConfigData
    let onSave: (String) -> Void

    @State private var editedConfig: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configuration")
                        .font(AXTypography.title3)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(apacheConfig.configPath)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .monospaced()
                }
                
                Spacer()
                
                if isEditing {
                    Button("Cancel") {
                        editedConfig = apacheConfig.rawConfig
                        withAnimation { isEditing = false }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    
                    Button(action: {
                        onSave(editedConfig)
                        withAnimation { isEditing = false }
                    }) {
                        Text("Save & Restart")
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.xs)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        editedConfig = apacheConfig.rawConfig
                        withAnimation { isEditing = true }
                    }) {
                        Text("Edit Configuration")
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.xs)
                            .background(Color.axSurface.opacity(0.8))
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Editor
            ScrollView {
                TextEditor(text: isEditing ? $editedConfig : .constant(apacheConfig.rawConfig))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isEditing ? .axTextPrimary : .axTextSecondary)
                    .scrollContentBackground(.hidden) 
                    .padding(AXSpacing.md)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .frame(minHeight: 500)
                    .disabled(!isEditing)
            }
        }
        .onAppear {
            editedConfig = apacheConfig.rawConfig
        }
        .onChange(of: apacheConfig.rawConfig) { newValue in
            if !isEditing {
                editedConfig = newValue
            }
        }
    }
}
