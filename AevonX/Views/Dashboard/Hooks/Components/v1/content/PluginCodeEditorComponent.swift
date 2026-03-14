//
//  PluginCodeEditorComponent.swift
//  AevonX
//
//  Syntax-highlighted text/code editor for config files.
//  Supports reading file content from data_source and saving via command.
//

import SwiftUI
import AevonXCoreBridge

public struct PluginCodeEditorComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var content: String = ""
    @State private var originalContent: String = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var lineCount: Int = 0

    private var hasChanges: Bool { content != originalContent }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                Text(plugin.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Spacer()

                if hasChanges {
                    Text("Modified")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axWarning)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.axWarning.opacity(0.1))
                        .cornerRadius(4)
                }

                Text("\(lineCount) lines")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)

                if hasChanges {
                    Button(action: { content = originalContent }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10))
                            Text("Revert")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }

                if plugin.command != nil {
                    Button(action: { Task { await saveContent() } }) {
                        HStack(spacing: 3) {
                            if isSaving {
                                ProgressView().scaleEffect(0.5)
                            } else if saveSuccess {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 10))
                            }
                            Text(saveSuccess ? "Saved!" : "Save")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill(saveSuccess ? Color.axSuccess : (hasChanges ? Color.axAccentBlue : Color.axTextMuted))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasChanges || isSaving)
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface)

            Divider().opacity(0.3)

            if isLoading {
                HStack {
                    Spacer()
                    VStack(spacing: AXSpacing.sm) {
                        ProgressView()
                        Text("Loading file...")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }
                    .padding(AXSpacing.xxl)
                    Spacer()
                }
            } else {
                HStack(spacing: 0) {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...max(lineCount, 1), id: \.self) { num in
                            Text("\(num)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextMuted.opacity(0.5))
                                .frame(height: 18)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .background(Color.axBackground.opacity(0.5))

                    Divider().opacity(0.2)

                    TextEditor(text: $content)
                        .font(.system(size: 12, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(AXSpacing.sm)
                        .onChange(of: content) { _, newValue in
                            lineCount = newValue.components(separatedBy: "\n").count
                        }
                }
                .background(Color.axBackground)
            }

            if let error = vm.errorMessage {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 11))
                }
                .foregroundColor(.axError)
                .padding(AXSpacing.sm)
            }
        }
        .frame(minHeight: 300)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        .task { await loadContent() }
    }

    private func loadContent() async {
        guard let ds = plugin.dataSource else { isLoading = false; return }
        let cmd = HookPluginCommand(type: ds.type ?? .coreCmd, action: ds.action, payload: ds.payload)
        await vm.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)

        if let output = vm.resultOutput {
            content = output
            originalContent = output
            lineCount = output.components(separatedBy: "\n").count
        }
        isLoading = false
    }

    private func saveContent() async {
        guard let command = plugin.command else { return }
        isSaving = true
        saveSuccess = false

        let payload: [String: AnyCodable] = ["content": AnyCodable(content)]
        let cmd = HookPluginCommand(type: command.type, action: command.action, payload: payload)
        await vm.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)

        isSaving = false
        if vm.errorMessage == nil {
            saveSuccess = true
            originalContent = content
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                saveSuccess = false
            }
        }
    }
}
