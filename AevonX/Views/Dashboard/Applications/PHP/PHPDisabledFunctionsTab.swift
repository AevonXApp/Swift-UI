
import SwiftUI
import AevonXCoreBridge

struct PHPDisabledFunctionsTab: View {
    let application: ApplicationInstance
    @Binding var phpConfig: PHPConfigData
    let serverId: String
    
    @State private var searchText = ""
    @State private var dangerousFunctions: [DisabledPHPFunction] = []
    @State private var customFunction = ""
    @State private var isProcessing: Set<String> = []
    
    var filteredDangerousFunctions: [DisabledPHPFunction] {
        if searchText.isEmpty { return dangerousFunctions }
        return dangerousFunctions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disabled Functions")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    
                    Text("\(phpConfig.disabledFunctions.count) functions currently disabled")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                
                Spacer()
                
                // Quick Add Custom Function
                HStack {
                    TextField("Function name", text: $customFunction)
                        .textFieldStyle(.plain)
                        .font(AXTypography.body)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axSurface.opacity(0.5))
                        .cornerRadius(AXCornerRadius.sm)
                        .frame(width: 150)
                    
                    Button(action: { Task { await addCustomFunction() } }) {
                        Text("Disable")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.xs)
                            .background(Color.axError)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    .disabled(customFunction.isEmpty)
                }
            }
            
            // Search
            AXSearchBar(text: $searchText, placeholder: "Search functions...")
            
            // Functions Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: AXSpacing.md) {
                    ForEach(filteredDangerousFunctions) { function in
                        FunctionCard(
                            function: function,
                            isDisabled: phpConfig.disabledFunctions.contains(function.name),
                            isProcessing: isProcessing.contains(function.name),
                            onToggle: { await toggleFunction(function.name) }
                        )
                    }
                }
            }
        }
        .onAppear {
            Task {
                dangerousFunctions = await GoApplicationService.shared.getDangerousPHPFunctions()
            }
        }
    }
    
    private func toggleFunction(_ functionName: String) async {
        isProcessing.insert(functionName)
        
        do {
            if phpConfig.disabledFunctions.contains(functionName) {
                try await GoApplicationService.shared.enablePHPFunction(functionName, serverId: serverId)
                phpConfig.disabledFunctions.removeAll { $0 == functionName }
                GlobalToastManager.shared.showSuccess("Function '\(functionName)' enabled.")
            } else {
                try await GoApplicationService.shared.disablePHPFunction(functionName, serverId: serverId)
                phpConfig.disabledFunctions.append(functionName)
                GlobalToastManager.shared.showSuccess("Function '\(functionName)' disabled.")
            }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        
        isProcessing.remove(functionName)
    }
    
    private func addCustomFunction() async {
        guard !customFunction.isEmpty else { return }
        let functionName = customFunction
        isProcessing.insert(functionName)
        
        do {
            try await GoApplicationService.shared.disablePHPFunction(functionName, serverId: serverId)
            phpConfig.disabledFunctions.append(functionName)
            customFunction = ""
            GlobalToastManager.shared.showSuccess("Function '\(functionName)' disabled.")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        
        isProcessing.remove(functionName)
    }
}

private struct FunctionCard: View {
    let function: DisabledPHPFunction
    let isDisabled: Bool
    let isProcessing: Bool
    let onToggle: () async -> Void
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Icon
            Image(systemName: function.isDangerous ? "exclamationmark.triangle.fill" : "hand.raised")
                .font(.system(size: 18))
                .foregroundColor(function.isDangerous ? .axError : .axWarning)
                .frame(width: 36, height: 36)
                .background((function.isDangerous ? Color.axError : Color.axWarning).opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AXSpacing.sm) {
                    Text(function.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                        .monospaced()
                    
                    if function.isDangerous {
                        Text("HIGH RISK")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.axError)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axError.opacity(0.15))
                            .cornerRadius(AXCornerRadius.xs)
                    }
                }
                
                Text(function.description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Toggle Button
            Button(action: { Task { await onToggle() } }) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(isDisabled ? "Enable" : "Disable")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 70, height: 28)
            .background(isDisabled ? Color.axSuccess : Color.axError)
            .cornerRadius(AXCornerRadius.sm)
            .buttonStyle(.plain)
            .disabled(isProcessing)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(isDisabled ? Color.axError.opacity(0.3) : Color.axBorder.opacity(0.2), lineWidth: isDisabled ? 2 : 1)
        )
    }
}
