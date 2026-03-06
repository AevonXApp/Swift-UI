//
//  UnifiedEnvEditorView.swift
//  AevonX
//
//  Shared .env file editor component for Python and Node.js apps.
//  Supports viewing, editing, adding, and removing environment variables.
//

import SwiftUI
import AevonXCore

// MARK: - Env Variable Item

struct EnvItem: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
    var isSensitive: Bool
    var isNew: Bool = false

    static func == (lhs: EnvItem, rhs: EnvItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Unified Env Editor View

struct UnifiedEnvEditorView: View {
    let title: String
    @Binding var variables: [EnvItem]
    let accentColor: Color
    var onSave: (([EnvItem]) -> Void)?
    var onRefresh: (() async -> Void)?

    @State private var editingKey: UUID?
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    @State private var showAddForm = false
    @State private var revealedSecrets: Set<UUID> = []

    private let sensitivePatterns = ["SECRET", "PASSWORD", "TOKEN", "API_KEY", "PRIVATE", "CREDENTIAL", "AUTH", "KEY"]

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Header
            HStack {
                Text(title)
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Text("\(variables.count) vars")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)

                Spacer()

                AXActionButton(label: "Add", icon: "plus.circle", style: .primary, size: .small) {
                    showAddForm.toggle()
                }

                if let onRefresh = onRefresh {
                    AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost, size: .small) {
                        Task { await onRefresh() }
                    }
                }
            }

            // Add new variable form
            if showAddForm {
                AXCard {
                    VStack(spacing: AXSpacing.sm) {
                        HStack {
                            Text("New Variable")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            Spacer()
                        }

                        HStack(spacing: AXSpacing.sm) {
                            TextField("KEY", text: $newKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: 200)

                            Text("=")
                                .foregroundColor(.axTextMuted)

                            TextField("value", text: $newValue)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))

                            AXActionButton(label: "Add", style: .primary, size: .small) {
                                guard !newKey.isEmpty else { return }
                                let isSensitive = sensitivePatterns.contains { newKey.uppercased().contains($0) }
                                variables.append(EnvItem(key: newKey, value: newValue, isSensitive: isSensitive, isNew: true))
                                newKey = ""
                                newValue = ""
                                showAddForm = false
                            }
                        }
                    }
                }
            }

            // Variable list
            if variables.isEmpty {
                AXPlaceholder(
                    icon: "key.fill",
                    title: "No Environment Variables",
                    subtitle: "Add variables or load from .env file"
                )
            } else {
                AXCard {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Key")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 200, alignment: .leading)
                            Text("Value")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("")
                                .frame(width: 60)
                        }
                        .padding(.bottom, 8)

                        Divider()

                        ForEach(variables) { envVar in
                            envVarRow(envVar)
                            Divider()
                        }
                    }
                }

                if let onSave = onSave {
                    HStack {
                        Spacer()
                        AXActionButton(label: "Save Changes", icon: "square.and.arrow.down", style: .primary) {
                            onSave(variables)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func envVarRow(_ envVar: EnvItem) -> some View {
        HStack {
            Text(envVar.key)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(accentColor)
                .frame(width: 200, alignment: .leading)

            if envVar.isSensitive && !revealedSecrets.contains(envVar.id) {
                HStack(spacing: 4) {
                    Text("•••••••••••")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)

                    Button {
                        revealedSecrets.insert(envVar.id)
                    } label: {
                        Image(systemName: "eye")
                            .font(.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(envVar.value)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                variables.removeAll { $0.id == envVar.id }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.axError)
            }
            .buttonStyle(.plain)
            .frame(width: 60)
        }
        .padding(.vertical, 6)
    }
}
