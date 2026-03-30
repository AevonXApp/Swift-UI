//
//  NetworkHelpers.swift
//  AevonX
//
//  Shared helper views for network section.
//

import SwiftUI

extension NetworkManagementSection {

    func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: icon).font(AXTypography.caption2).foregroundColor(.axAccentBlue)
            Text(title).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
        }
    }

    func editButton(isEditing: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(isEditing ? L10n.Button.cancel : L10n.Button.edit)
                .font(AXTypography.caption2).fontWeight(.medium)
                .foregroundColor(isEditing ? .axTextMuted : .axAccentBlue)
        }.buttonStyle(PlainButtonStyle())
    }

    func readOnlyText(_ text: String) -> some View {
        ScrollView {
            Text(text.isEmpty ? L10n.Status.empty : text)
                .font(AXTypography.monoXs)
                .foregroundColor(text.isEmpty ? .axTextMuted : .axTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 120)
    }

    func editableTextArea(text: Binding<String>) -> some View {
        TextEditor(text: text)
            .font(.system(.caption, design: .monospaced))
            .frame(minHeight: 80, maxHeight: 160)
            .padding(AXSpacing.xxs)
            .background(Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.sm)
    }

    func saveDiscardBar(onSave: @escaping () -> Void, onDiscard: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button(L10n.Button.discard, action: onDiscard)
                .font(AXTypography.caption).foregroundColor(.axTextMuted)
                .buttonStyle(PlainButtonStyle())
            Button(action: onSave) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "checkmark")
                    Text(L10n.Button.save)
                }
                .font(AXTypography.caption).fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.sm)
            }.buttonStyle(PlainButtonStyle())
        }
    }
}
