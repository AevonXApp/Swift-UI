
import SwiftUI
import AevonXCoreBridge

struct PHPConfigurationTab: View {
    let application: ApplicationInstance
    @Binding var phpConfig: PHPConfigData
    let onSave: (String) async -> Void
    
    @State private var uploadMaxFilesize = "50"
    @State private var uploadUnit = "MB"
    @State private var postMaxSize = "50"
    @State private var postUnit = "MB"
    @State private var maxFileUploads = "20"
    @State private var fileUploads = true
    
    @State private var maxExecutionTime = 300.0
    @State private var maxInputTime = 60.0
    @State private var memoryLimit = "128"
    @State private var memoryUnit = "MB"
    
    @State private var displayErrors = false
    @State private var errorReporting = "E_ALL & ~E_NOTICE"
    
    @State private var isSaving = false
    
    let units = ["KB", "MB", "GB"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("PHP Configuration")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.axTextPrimary)
            
            ScrollView {
                VStack(spacing: AXSpacing.lg) {
                    // File Upload Settings
                    ConfigSection(title: "File Upload Settings") {
                        HStack {
                            ConfigField(label: "upload_max_filesize", value: uploadMaxFilesize, onChange: { uploadMaxFilesize = $0 })
                            Picker("", selection: $uploadUnit) {
                                ForEach(units, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 80)
                        }
                        
                        HStack {
                            ConfigField(label: "post_max_size", value: postMaxSize, onChange: { postMaxSize = $0 })
                            Picker("", selection: $postUnit) {
                                ForEach(units, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 80)
                        }
                        
                        ConfigField(label: "max_file_uploads", value: maxFileUploads, onChange: { maxFileUploads = $0 })
                        
                        ConfigToggle(label: "file_uploads", isOn: $fileUploads)
                    }
                    
                    // Execution Settings
                    ConfigSection(title: "Execution Settings") {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("max_execution_time")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                            
                            HStack {
                                Slider(value: $maxExecutionTime, in: 30...600, step: 30)
                                Text("\(Int(maxExecutionTime)) seconds")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)
                                    .frame(width: 100, alignment: .trailing)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("max_input_time")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                            
                            HStack {
                                Slider(value: $maxInputTime, in: 30...300, step: 10)
                                Text("\(Int(maxInputTime)) seconds")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)
                                    .frame(width: 100, alignment: .trailing)
                            }
                        }
                        
                        HStack {
                            ConfigField(label: "memory_limit", value: memoryLimit, onChange: { memoryLimit = $0 })
                            Picker("", selection: $memoryUnit) {
                                ForEach(units, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 80)
                        }
                    }
                    
                    // Error Handling
                    ConfigSection(title: "Error Handling") {
                        ConfigToggle(label: "display_errors", isOn: $displayErrors)
                        
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("error_reporting")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                            
                            TextField("", text: $errorReporting)
                                .textFieldStyle(.plain)
                                .font(AXTypography.body)
                                .padding(AXSpacing.sm)
                                .background(Color.axSurface.opacity(0.5))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: AXSpacing.md) {
                Spacer()
                
                Button(action: loadConfig) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { Task { await saveConfig() } }) {
                    HStack {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                            Text("Save")
                        }
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
        }
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        let config = phpConfig.rawConfig
        guard !config.isEmpty else { return }
        
        // Parse size directive (e.g. "50M" → ("50", "MB"))
        func parseSizeValue(_ raw: String) -> (String, String) {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix("G") || trimmed.hasSuffix("g") {
                return (String(trimmed.dropLast()), "GB")
            } else if trimmed.hasSuffix("K") || trimmed.hasSuffix("k") {
                return (String(trimmed.dropLast()), "KB")
            } else if trimmed.hasSuffix("M") || trimmed.hasSuffix("m") {
                return (String(trimmed.dropLast()), "MB")
            }
            return (trimmed, "MB")
        }
        
        // Extract a directive value from php.ini text
        func directive(_ name: String) -> String? {
            let pattern = "(?m)^\\s*\(NSRegularExpression.escapedPattern(for: name))\\s*=\\s*(.+?)\\s*$"
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: config, range: NSRange(config.startIndex..., in: config)),
                  let range = Range(match.range(at: 1), in: config) else { return nil }
            return String(config[range])
        }
        
        // File Upload Settings
        if let val = directive("upload_max_filesize") {
            let (num, unit) = parseSizeValue(val)
            uploadMaxFilesize = num
            uploadUnit = unit
        }
        if let val = directive("post_max_size") {
            let (num, unit) = parseSizeValue(val)
            postMaxSize = num
            postUnit = unit
        }
        if let val = directive("max_file_uploads") {
            maxFileUploads = val.trimmingCharacters(in: .whitespaces)
        }
        if let val = directive("file_uploads") {
            fileUploads = val.trimmingCharacters(in: .whitespaces).lowercased() != "off"
                && val.trimmingCharacters(in: .whitespaces) != "0"
        }
        
        // Execution Settings
        if let val = directive("max_execution_time"), let num = Double(val.trimmingCharacters(in: .whitespaces)) {
            maxExecutionTime = min(max(num, 30), 600)
        }
        if let val = directive("max_input_time"), let num = Double(val.trimmingCharacters(in: .whitespaces)) {
            maxInputTime = min(max(num, 30), 300)
        }
        if let val = directive("memory_limit") {
            let (num, unit) = parseSizeValue(val)
            memoryLimit = num
            memoryUnit = unit
        }
        
        // Error Handling
        if let val = directive("display_errors") {
            let v = val.trimmingCharacters(in: .whitespaces).lowercased()
            displayErrors = (v == "on" || v == "1")
        }
        if let val = directive("error_reporting") {
            errorReporting = val.trimmingCharacters(in: .whitespaces)
        }
    }
    
    private func saveConfig() async {
        isSaving = true
        var config = phpConfig.rawConfig
        
        // Maps php.ini unit suffixes
        func unitSuffix(_ unit: String) -> String {
            switch unit {
            case "GB": return "G"
            case "KB": return "K"
            default: return "M"
            }
        }
        
        // Replace or append a directive
        func setDirective(_ name: String, _ value: String) {
            let pattern = "(?m)^(\\s*;?\\s*)\(NSRegularExpression.escapedPattern(for: name))\\s*=.*$"
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: config, range: NSRange(config.startIndex..., in: config)) != nil {
                config = regex.stringByReplacingMatches(
                    in: config, range: NSRange(config.startIndex..., in: config),
                    withTemplate: "\(name) = \(value)"
                )
            } else {
                config += "\n\(name) = \(value)"
            }
        }
        
        // Apply all form values
        setDirective("upload_max_filesize", "\(uploadMaxFilesize)\(unitSuffix(uploadUnit))")
        setDirective("post_max_size", "\(postMaxSize)\(unitSuffix(postUnit))")
        setDirective("max_file_uploads", maxFileUploads)
        setDirective("file_uploads", fileUploads ? "On" : "Off")
        setDirective("max_execution_time", "\(Int(maxExecutionTime))")
        setDirective("max_input_time", "\(Int(maxInputTime))")
        setDirective("memory_limit", "\(memoryLimit)\(unitSuffix(memoryUnit))")
        setDirective("display_errors", displayErrors ? "On" : "Off")
        setDirective("error_reporting", errorReporting)
        
        await onSave(config)
        isSaving = false
    }
}

private struct ConfigSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(title)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            VStack(spacing: AXSpacing.md) {
                content
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
}

private struct ConfigField: View {
    let label: String
    let value: String
    let onChange: (String) -> Void
    
    @State private var localValue: String
    
    init(label: String, value: String, onChange: @escaping (String) -> Void) {
        self.label = label
        self.value = value
        self.onChange = onChange
        _localValue = State(initialValue: value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            
            TextField("", text: $localValue)
                .textFieldStyle(.plain)
                .font(AXTypography.body)
                .padding(AXSpacing.sm)
                .background(Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)
                .onChange(of: localValue) { oldValue, newValue in onChange(newValue) }
        }
    }
}

private struct ConfigToggle: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
        }
    }
}
