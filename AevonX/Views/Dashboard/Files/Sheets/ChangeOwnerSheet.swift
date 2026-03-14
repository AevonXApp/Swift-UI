//
//  ChangeOwnerSheet.swift
//  AevonX
//
//  Sheet view for changing file/directory ownership (chown)
//  Supports common presets and custom owner/group values
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Change Owner Sheet

struct ChangeOwnerSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var owner = "root"
    @State private var group = "root"
    @State private var recursive = false
    @State private var customOwner = false
    @State private var customGroup = false
    
    private let commonOwners = ["root", "www-data", "nginx", "nobody", "ubuntu", "deploy"]
    private let commonGroups = ["root", "www-data", "nginx", "nogroup", "adm", "users"]
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "person.2")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Change Owner")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            if let file = viewModel.changeOwnerFile {
                Text(file.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(2)
                
                Text("Current: \(file.owner):\(file.group)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Owner
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Owner")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    ownerChipRow(options: commonOwners, selected: $owner, isCustom: $customOwner)
                    
                    if customOwner {
                        TextField("custom user", text: $owner)
                            .textFieldStyle(AXTextFieldStyle())
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                
                // Group
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Group")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    ownerChipRow(options: commonGroups, selected: $group, isCustom: $customGroup)
                    
                    if customGroup {
                        TextField("custom group", text: $group)
                            .textFieldStyle(AXTextFieldStyle())
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                
                Toggle("Apply recursively", isOn: $recursive)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            
            // Preview
            Text("chown \(recursive ? "-R " : "")\(owner):\(group)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxs)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showChangeOwnerSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button("Apply") {
                    guard let file = viewModel.changeOwnerFile else { return }
                    viewModel.changeOwner(file: file, owner: owner, group: group, recursive: recursive)
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(owner.isEmpty || group.isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 420)
        .background(Color.axBackground)
        .onAppear {
            if let file = viewModel.changeOwnerFile {
                owner = file.owner
                group = file.group
                customOwner = !commonOwners.contains(file.owner)
                customGroup = !commonGroups.contains(file.group)
            }
        }
    }
    
    private func ownerChipRow(options: [String], selected: Binding<String>, isCustom: Binding<Bool>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selected.wrappedValue = option
                        isCustom.wrappedValue = false
                    } label: {
                        Text(option)
                            .font(.system(size: 10, weight: selected.wrappedValue == option && !isCustom.wrappedValue ? .bold : .regular, design: .monospaced))
                            .foregroundColor(selected.wrappedValue == option && !isCustom.wrappedValue ? .white : .axTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                selected.wrappedValue == option && !isCustom.wrappedValue
                                    ? Color.axAccentBlue
                                    : Color.axBackgroundSecondary
                            )
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Custom option
                Button {
                    isCustom.wrappedValue = true
                    selected.wrappedValue = ""
                } label: {
                    Text("Custom")
                        .font(.system(size: 10, weight: isCustom.wrappedValue ? .bold : .regular))
                        .foregroundColor(isCustom.wrappedValue ? .white : .axTextTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isCustom.wrappedValue ? Color.axAccentBlue : Color.axBackgroundSecondary)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
