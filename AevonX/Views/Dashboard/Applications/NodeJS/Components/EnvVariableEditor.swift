//
//  EnvVariableEditor.swift
//  AevonX
//
//  CRUD editor for Node.js .env files.
//  Premium design with dark-themed fields and inline editing.
//

import SwiftUI
import AevonXCoreBridge

struct EnvVariableEditor: View {
    let serverId: String
    let appPath: String?

    @State private var variables: [EnvironmentVariable] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var hasChanges = false

    // New variable form
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var showAddForm = false

    private let configService = NodeJSConfigService()

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            if isLoading {
                AXLoadingState(message: "Loading environment variables…")
            } else {
                headerCard
                if showAddForm { addFormCard }
                if variables.isEmpty {
                    emptyState
                } else {
                    variablesCard
                }
            }
        }
        .task { await loadData() }
    }

    // MARK: - Header

    private var headerCard: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                // Section icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#F7DF1E").opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: "key.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#F7DF1E"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Environment Variables")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text("\(variables.count) variables • .env")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                if hasChanges {
                    Button {
                        Task { await saveChanges() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isSaving ? "hourglass" : "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text(isSaving ? "Saving…" : "Save Changes")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.axSuccess, Color.axSuccess.opacity(0.8)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .cornerRadius(AXCornerRadius.sm)
                        .shadow(color: Color.axSuccess.opacity(0.3), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }

                Button {
                    withAnimation(.spring(response: 0.3)) { showAddForm.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAddForm ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 11))
                        Text(showAddForm ? "Cancel" : "Add")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await loadData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 28, height: 28)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Add Form

    private var addFormCard: some View {
        AXCard(accentColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text("New Variable")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axAccentBlue)

                HStack(spacing: AXSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("KEY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.axTextMuted)
                        envField(text: $newKey, placeholder: "VARIABLE_NAME")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("VALUE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.axTextMuted)
                        envField(text: $newValue, placeholder: "value")
                    }

                    Button { addVariable() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(newKey.isEmpty ? .axTextMuted : .axSuccess)
                    }
                    .buttonStyle(.plain)
                    .disabled(newKey.isEmpty)
                    .padding(.top, 14)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        AXPlaceholder(
            icon: "key",
            title: "No Environment Variables",
            subtitle: "No .env file found. Add variables to create one.",
            action: AXPlaceholderAction(label: "Add Variable") {
                await MainActor.run { showAddForm = true }
            }
        )
    }

    // MARK: - Variables List

    private var variablesCard: some View {
        AXCard {
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("KEY")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("VALUE")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("")
                        .frame(width: 60)
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .padding(.bottom, AXSpacing.sm)
                .padding(.horizontal, 4)

                ForEach(Array(variables.enumerated()), id: \.element.id) { index, variable in
                    variableRow(variable, index: index)

                    if index < variables.count - 1 {
                        Divider()
                            .overlay(Color.axBorder.opacity(0.2))
                            .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func variableRow(_ variable: EnvironmentVariable, index: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            // Key
            TextField("KEY", text: binding(for: index, keyPath: \.key))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.axAccentBlue)
                .textFieldStyle(.plain)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.axBackground.opacity(0.5))
                .cornerRadius(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: variables[safe: index]?.key ?? "") { _, _ in hasChanges = true }

            // Value
            if variable.isSecret {
                SecureField("value", text: binding(for: index, keyPath: \.value))
                    .font(.system(size: 11, design: .monospaced))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.axBackground.opacity(0.5))
                    .cornerRadius(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: variables[safe: index]?.value ?? "") { _, _ in hasChanges = true }
            } else {
                TextField("value", text: binding(for: index, keyPath: \.value))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.axBackground.opacity(0.5))
                    .cornerRadius(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: variables[safe: index]?.value ?? "") { _, _ in hasChanges = true }
            }

            // Actions
            Button { toggleSecret(at: index) } label: {
                Image(systemName: variable.isSecret ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 11))
                    .foregroundColor(variable.isSecret ? .axWarning : .axTextMuted)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(variable.isSecret ? Color.axWarning.opacity(0.1) : Color.clear)
                    )
            }
            .buttonStyle(.plain)

            Button { deleteVariable(at: index) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.axError.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.axError.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
    }

    // MARK: - Reusable Components

    private func envField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.axTextPrimary)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 7)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
    }

    // MARK: - Bindings

    private func binding(for index: Int, keyPath: WritableKeyPath<EnvironmentVariable, String>) -> Binding<String> {
        Binding(
            get: { variables[safe: index]?[keyPath: keyPath] ?? "" },
            set: { newValue in
                guard index < variables.count else { return }
                variables[index][keyPath: keyPath] = newValue
                hasChanges = true
            }
        )
    }

    // MARK: - Actions

    private func loadData() async {
        guard let path = appPath else { isLoading = false; return }
        isLoading = true
        variables = (try? await configService.readEnvFile(appPath: path, serverId: serverId)) ?? []
        hasChanges = false
        isLoading = false
    }

    private func addVariable() {
        guard !newKey.isEmpty else { return }
        let secretKeys = ["KEY", "SECRET", "PASSWORD", "TOKEN", "AUTH", "API"]
        let isSecret = secretKeys.contains { newKey.uppercased().contains($0) }
        variables.append(EnvironmentVariable(key: newKey, value: newValue, isSecret: isSecret))
        newKey = ""
        newValue = ""
        hasChanges = true
        showAddForm = false
    }

    private func deleteVariable(at index: Int) {
        guard index < variables.count else { return }
        variables.remove(at: index)
        hasChanges = true
    }

    private func toggleSecret(at index: Int) {
        guard index < variables.count else { return }
        variables[index] = EnvironmentVariable(
            id: variables[index].id,
            key: variables[index].key,
            value: variables[index].value,
            isSecret: !variables[index].isSecret
        )
    }

    private func saveChanges() async {
        guard let path = appPath else { return }
        isSaving = true
        do {
            try await configService.writeEnvFile(variables: variables, appPath: path, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Environment variables saved")
            hasChanges = false
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        isSaving = false
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
