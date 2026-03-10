//
//  EnvVariablesTab.swift
//  AevonX
//
//  Environment variables (.env) management tab for website detail view.
//  Key-value editor with add/remove, secret detection, and save.
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - ViewModel

@MainActor
final class EnvVariablesViewModel: ObservableObject {
    @Published var variables: [EnvironmentVariable] = []
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var newKey = ""
    @Published var newValue = ""
    @Published var showAddForm = false
    @Published var hasChanges = false
    
    let serverId: String?
    let appPath: String
    
    private let configService = NodeJSConfigService()
    
    init(serverId: String?, appPath: String) {
        self.serverId = serverId
        self.appPath = appPath
    }
    
    func loadVariables() async {
        guard let serverId = serverId else { return }
        isLoading = true
        
        do {
            variables = try await configService.readEnvFile(appPath: appPath, serverId: serverId)
        } catch {
            CoreLogger.shared.error("Failed to load .env: \(error)", module: "EnvVariablesTab")
        }
        
        isLoading = false
        hasChanges = false
    }
    
    func saveVariables() async {
        guard let serverId = serverId else { return }
        isSaving = true
        
        do {
            try await configService.writeEnvFile(variables: variables, appPath: appPath, serverId: serverId)
            hasChanges = false
            GlobalToastManager.shared.showSuccess(".env saved successfully")
        } catch {
            GlobalToastManager.shared.showError("Failed to save: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    func addVariable() {
        guard !newKey.isEmpty else { return }
        
        let secretKeys = ["SECRET", "KEY", "PASSWORD", "TOKEN", "API_KEY", "PRIVATE"]
        let isSecret = secretKeys.contains { newKey.uppercased().contains($0) }
        
        variables.append(EnvironmentVariable(key: newKey, value: newValue, isSecret: isSecret))
        newKey = ""
        newValue = ""
        showAddForm = false
        hasChanges = true
    }
    
    func removeVariable(at offsets: IndexSet) {
        variables.remove(atOffsets: offsets)
        hasChanges = true
    }
    
    func removeVariable(_ variable: EnvironmentVariable) {
        variables.removeAll { $0.id == variable.id }
        hasChanges = true
    }
    
    func updateValue(for variable: EnvironmentVariable, newValue: String) {
        if let index = variables.firstIndex(where: { $0.id == variable.id }) {
            variables[index].value = newValue
            hasChanges = true
        }
    }
}

// MARK: - View

struct EnvVariablesTab: View {
    @StateObject var viewModel: EnvVariablesViewModel
    
    init(serverId: String?, appPath: String) {
        _viewModel = StateObject(wrappedValue: EnvVariablesViewModel(serverId: serverId, appPath: appPath))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Loading environment variables...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // Header
                    headerActions
                    
                    // Variables List
                    if viewModel.variables.isEmpty && !viewModel.showAddForm {
                        emptyState
                    } else {
                        variablesList
                    }
                    
                    // Add Form
                    if viewModel.showAddForm {
                        addForm
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .task {
            await viewModel.loadVariables()
        }
    }
    
    // MARK: - Header
    
    private var headerActions: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(".env Configuration")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text(viewModel.appPath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            if viewModel.hasChanges {
                Button(action: { Task { await viewModel.saveVariables() } }) {
                    HStack(spacing: 6) {
                        if viewModel.isSaving {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                        }
                        Text("Save Changes")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSuccess)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
            }
            
            Button(action: { viewModel.showAddForm.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Variable")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "key")
                .font(.system(size: 32))
                .foregroundColor(.axTextMuted)
            Text("No Environment Variables")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            Text("No .env file found. Add variables to create one.")
                .font(.system(size: 12))
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }
    
    // MARK: - Variables List
    
    private var variablesList: some View {
        VStack(spacing: AXSpacing.xs) {
            // Table Header
            HStack {
                Text("KEY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .frame(width: 200, alignment: .leading)
                
                Text("VALUE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                
                Spacer()
                
                Text("ACTIONS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .frame(width: 60)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            
            ForEach(viewModel.variables) { variable in
                variableRow(variable)
            }
        }
    }
    
    @State private var revealedSecrets: Set<UUID> = []
    
    private func variableRow(_ variable: EnvironmentVariable) -> some View {
        HStack(spacing: AXSpacing.sm) {
            // Key
            Text(variable.key)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.axAccentBlue)
                .frame(width: 200, alignment: .leading)
            
            // Value
            if variable.isSecret && !revealedSecrets.contains(variable.id) {
                HStack(spacing: 4) {
                    Text("••••••••")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                    
                    Button(action: { revealedSecrets.insert(variable.id) }) {
                        Image(systemName: "eye")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text(variable.value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                
                if variable.isSecret {
                    Button(action: { revealedSecrets.remove(variable.id) }) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            // Delete
            Button(action: { viewModel.removeVariable(variable) }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.axError)
                    .frame(width: 26, height: 26)
                    .background(Color.axError.opacity(0.05))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .frame(width: 60)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.2))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    // MARK: - Add Form
    
    private var addForm: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Add Variable")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.axTextPrimary)
            
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextTertiary)
                    TextField("DATABASE_URL", text: $viewModel.newKey)
                        .textFieldStyle(AXTextFieldStyle())
                        .font(.system(size: 12, design: .monospaced))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextTertiary)
                    TextField("postgres://...", text: $viewModel.newValue)
                        .textFieldStyle(AXTextFieldStyle())
                        .font(.system(size: 12, design: .monospaced))
                }
                
                Button(action: { viewModel.addVariable() }) {
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(viewModel.newKey.isEmpty ? Color.axTextMuted : Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.newKey.isEmpty)
                .padding(.top, 16)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
    }
}
