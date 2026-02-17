//
//  ApacheModulesTab.swift
//  AevonX
//
//  Manage Apache modules (enable/disable)
//

import SwiftUI
import AevonXCore

struct ApacheModulesTab: View {
    let application: ApplicationInstance
    @Binding var apacheConfig: ApacheConfigData
    let serverId: String
    
    @State private var searchText = ""
    @State private var filter: ModuleFilter = .all
    @State private var processingModule: String?
    
    enum ModuleFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case enabled = "Enabled"
        case disabled = "Disabled"
        case builtIn = "Built-in"
        
        var id: String { rawValue }
    }
    
    var filteredModules: [ApacheModule] {
        let modules = apacheConfig.modules
        
        let filtered = modules.filter { module in
            let matchesSearch = searchText.isEmpty || module.name.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool
            
            switch filter {
            case .all: matchesFilter = true
            case .enabled: matchesFilter = module.isEnabled
            case .disabled: matchesFilter = !module.isEnabled
            case .builtIn: matchesFilter = module.isBuiltIn
            }
            
            return matchesSearch && matchesFilter
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Header & Controls
            HStack {
                Text("Apache Modules")
                    .font(AXTypography.title3)
                
                Spacer()
                
                Picker("Filter", selection: $filter) {
                    ForEach(ModuleFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                TextField("Search modules...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            
            // Modules Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: AXSpacing.md)], spacing: AXSpacing.md) {
                    ForEach(filteredModules) { module in
                        ModuleCard(
                            module: module,
                            isProcessing: processingModule == module.name,
                            onToggle: {
                                Task { await toggleModule(module) }
                            }
                        )
                    }
                }
                .padding(.bottom, AXSpacing.xl)
            }
        }
    }
    
    private func toggleModule(_ module: ApacheModule) async {
        processingModule = module.name
        
        do {
            if module.isEnabled {
                try await ApplicationManager.shared.disableApacheModule(module.name, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Module \(module.name) disabled successfully")
            } else {
                try await ApplicationManager.shared.enableApacheModule(module.name, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Module \(module.name) enabled successfully")
            }
            
            // Refresh module list
            let modules = try await ApplicationManager.shared.getInstalledApacheModules(serverId: serverId)
            // Available modules might also change state
            let available = try await ApplicationManager.shared.getAvailableApacheModules(serverId: serverId)
            
            apacheConfig.modules = modules + available
            
        } catch {
            GlobalToastManager.shared.showError("Failed to toggle module: \(error.localizedDescription)")
        }
        
        processingModule = nil
    }
}

private struct ModuleCard: View {
    let module: ApacheModule
    let isProcessing: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(module.name)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                if module.isBuiltIn {
                    Text("Built-in")
                        .font(AXTypography.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.axTextTertiary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.6)
            } else if !module.isBuiltIn {
                Toggle("", isOn: Binding(
                    get: { module.isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }
}
