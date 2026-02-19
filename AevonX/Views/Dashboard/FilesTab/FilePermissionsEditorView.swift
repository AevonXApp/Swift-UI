//
//  FilePermissionsEditorView.swift
//  AevonX
//
//  Interactive permissions editor with numeric + symbolic display
//

import SwiftUI
import AevonXCore

// MARK: - Permissions Editor Sheet

struct FilePermissionsEditorView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var ownerRead = false
    @State private var ownerWrite = false
    @State private var ownerExec = false
    @State private var groupRead = false
    @State private var groupWrite = false
    @State private var groupExec = false
    @State private var othersRead = false
    @State private var othersWrite = false
    @State private var othersExec = false
    
    private var numericValue: Int {
        let o = (ownerRead ? 4 : 0) + (ownerWrite ? 2 : 0) + (ownerExec ? 1 : 0)
        let g = (groupRead ? 4 : 0) + (groupWrite ? 2 : 0) + (groupExec ? 1 : 0)
        let t = (othersRead ? 4 : 0) + (othersWrite ? 2 : 0) + (othersExec ? 1 : 0)
        return o * 100 + g * 10 + t
    }
    
    private var humanLabel: String {
        let o = (ownerRead ? 4 : 0) + (ownerWrite ? 2 : 0) + (ownerExec ? 1 : 0)
        switch o {
        case 7: return "Full Access"
        case 6: return "Read & Write"
        case 5: return "Read & Execute"
        case 4: return "Read Only"
        case 2: return "Write Only"
        case 1: return "Execute Only"
        default: return "No Access"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("Edit Permissions")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    if let file = viewModel.permissionsFile {
                        Text(file.path)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button(action: { viewModel.isPermissionsEditorOpen = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.lg)
            .background(Color.axBackgroundSecondary)
            
            Divider().background(Color.axBorder)
            
            VStack(spacing: AXSpacing.xl) {
                // Numeric Display
                HStack(spacing: AXSpacing.lg) {
                    VStack(spacing: AXSpacing.xs) {
                        Text("Numeric")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                        Text(String(format: "%03d", numericValue))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                    }
                    
                    Divider().frame(height: 50)
                    
                    VStack(spacing: AXSpacing.xs) {
                        Text("Access Level")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                        Text(humanLabel)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                }
                .padding(AXSpacing.lg)
                .frame(maxWidth: .infinity)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                
                // Permission Toggles
                VStack(spacing: AXSpacing.md) {
                    permissionRow(title: "Owner", icon: "person.fill",
                                  read: $ownerRead, write: $ownerWrite, execute: $ownerExec)
                    Divider().background(Color.axBorder)
                    permissionRow(title: "Group", icon: "person.2.fill",
                                  read: $groupRead, write: $groupWrite, execute: $groupExec)
                    Divider().background(Color.axBorder)
                    permissionRow(title: "Others", icon: "globe",
                                  read: $othersRead, write: $othersWrite, execute: $othersExec)
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                
                // Quick Presets
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Quick Presets")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    
                    HStack(spacing: AXSpacing.sm) {
                        presetButton("755", label: "Standard Dir")
                        presetButton("644", label: "Standard File")
                        presetButton("600", label: "Private")
                        presetButton("777", label: "Full Access")
                    }
                }
            }
            .padding(AXSpacing.lg)
            
            Spacer()
            
            Divider().background(Color.axBorder)
            
            // Footer
            HStack(spacing: AXSpacing.md) {
                Button(action: { viewModel.isPermissionsEditorOpen = false }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    let isDir = viewModel.permissionsFile?.isDirectory ?? false
                    let isLink = viewModel.permissionsFile?.isSymlink ?? false
                    viewModel.editingPermissions = .fromNumeric(numericValue, isDirectory: isDir, isSymlink: isLink)
                    viewModel.savePermissions()
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if viewModel.isSavingPermissions {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .axBackground))
                                .scaleEffect(0.6)
                        }
                        Text("Apply")
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isSavingPermissions)
            }
            .padding(AXSpacing.lg)
            .background(Color.axBackgroundSecondary)
        }
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
        .onAppear { loadPermissions() }
    }
    
    private func loadPermissions() {
        guard let perms = viewModel.editingPermissions else { return }
        ownerRead = perms.ownerRead
        ownerWrite = perms.ownerWrite
        ownerExec = perms.ownerExecute
        groupRead = perms.groupRead
        groupWrite = perms.groupWrite
        groupExec = perms.groupExecute
        othersRead = perms.othersRead
        othersWrite = perms.othersWrite
        othersExec = perms.othersExecute
    }
    
    private func permissionRow(title: String, icon: String,
                                read: Binding<Bool>, write: Binding<Bool>, execute: Binding<Bool>) -> some View {
        HStack {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 20)
                Text(title)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                    .frame(width: 60, alignment: .leading)
            }
            
            Spacer()
            
            HStack(spacing: AXSpacing.md) {
                toggleChip("R", isOn: read, color: .axAccentGreen)
                toggleChip("W", isOn: write, color: .axWarning)
                toggleChip("X", isOn: execute, color: .axError)
            }
        }
    }
    
    private func toggleChip(_ label: String, isOn: Binding<Bool>, color: Color) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isOn.wrappedValue ? .white : .axTextMuted)
                .frame(width: 32, height: 28)
                .background(isOn.wrappedValue ? color : Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func presetButton(_ value: String, label: String) -> some View {
        Button(action: { applyPreset(value) }) {
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.axTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func applyPreset(_ value: String) {
        guard let num = Int(value) else { return }
        let o = num / 100
        let g = (num / 10) % 10
        let t = num % 10
        ownerRead = (o & 4) != 0; ownerWrite = (o & 2) != 0; ownerExec = (o & 1) != 0
        groupRead = (g & 4) != 0; groupWrite = (g & 2) != 0; groupExec = (g & 1) != 0
        othersRead = (t & 4) != 0; othersWrite = (t & 2) != 0; othersExec = (t & 1) != 0
    }
}
