
import SwiftUI
import AevonXCoreBridge

struct DockerContainerWizard: View {
    let serverId: String
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Wizard state
    @State private var currentStep = 0
    @State private var config = ContainerConfig()
    @State private var isDeploying = false
    @State private var errorMessage: String?
    @State private var availableNetworks: [DockerNetwork] = []
    
    private let steps = ["Image", "Name", "Ports", "Env Vars", "Volumes", "Network", "Resources", "Review"]
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !config.image.isEmpty
        case 1: return !config.name.isEmpty
        default: return true
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.Docker.createContainer)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            // Progress bar
            progressBar
            
            Divider()
            
            // Step content
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    stepContent
                    
                    if let error = errorMessage {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .padding()
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                    }
                }
                .padding(AXSpacing.lg)
            }
            
            Divider()
            
            // Navigation
            HStack {
                if currentStep > 0 {
                    Button(action: { currentStep -= 1 }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10))
                            Text(L10n.Button.back)
                        }
                    }
                    .buttonStyle(AXSecondaryButtonStyle())
                } else {
                    Button(L10n.Button.cancel) { dismiss() }
                        .buttonStyle(AXSecondaryButtonStyle())
                }
                
                Spacer()
                
                if currentStep < steps.count - 1 {
                    Button(action: { currentStep += 1 }) {
                        HStack(spacing: 4) {
                            Text(L10n.Docker.next)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                        }
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(!canProceed)
                } else {
                    Button(action: deploy) {
                        HStack(spacing: 6) {
                            if isDeploying {
                                ProgressView().controlSize(.small)
                            }
                            Image(systemName: "rocket.fill")
                                .font(.system(size: 12))
                            Text(isDeploying ? "Deploying..." : "Deploy")
                        }
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(isDeploying || config.image.isEmpty || config.name.isEmpty)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 580, height: 520)
        .background(Color.axBackground)
        .task {
            do {
                availableNetworks = try await DockerService.shared.getNetworks(serverId: serverId)
            } catch {}
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Color.axAccentBlue : Color.axSurface)
                            .frame(width: 22, height: 22)
                        
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(index == currentStep ? .white : .axTextMuted)
                        }
                    }
                    
                    Text(title)
                        .font(.system(size: 9, weight: index == currentStep ? .bold : .regular))
                        .foregroundColor(index <= currentStep ? .axTextPrimary : .axTextMuted)
                        .lineLimit(1)
                }
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.axAccentBlue : Color.axBorder)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.5))
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: imageStep
        case 1: nameStep
        case 2: portsStep
        case 3: envStep
        case 4: volumesStep
        case 5: networkStep
        case 6: resourcesStep
        case 7: reviewStep
        default: EmptyView()
        }
    }
    
    // Step 1: Image
    private var imageStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            stepHeader(icon: "shippingbox.fill", title: "Docker Image", subtitle: "Enter the image name and tag to use")
            
            WizardField(label: "Image") {
                TextField("e.g. nginx:latest, redis:7-alpine", text: $config.image)
                    .textFieldStyle(AXTextFieldStyle())
            }
            
            Text(L10n.Docker.tipUseImageTagFormatIfNoTagIsSpecifiedLatestWillBeUsed)
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
        }
    }
    
    // Step 2: Name
    private var nameStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            stepHeader(icon: "tag.fill", title: "Container Name", subtitle: "Give your container a unique name")
            
            WizardField(label: "Name") {
                TextField("e.g. my-web-app", text: $config.name)
                    .textFieldStyle(AXTextFieldStyle())
            }
        }
    }
    
    // Step 3: Ports
    private var portsStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            stepHeader(icon: "network", title: "Port Mapping", subtitle: "Map host ports to container ports")
            
            ForEach(config.ports.indices, id: \.self) { i in
                HStack(spacing: AXSpacing.sm) {
                    TextField("Host", text: $config.ports[i].hostPort)
                        .textFieldStyle(AXTextFieldStyle())
                        .frame(width: 100)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    
                    TextField("Container", text: $config.ports[i].containerPort)
                        .textFieldStyle(AXTextFieldStyle())
                        .frame(width: 100)
                    
                    Picker("", selection: $config.ports[i].proto) {
                        Text("TCP").tag("tcp")
                        Text("UDP").tag("udp")
                    }
                    .frame(width: 70)
                    
                    Button(action: { config.ports.remove(at: i) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            addButton("Add Port Mapping") {
                config.ports.append(PortMapping())
            }
        }
    }
    
    // Step 4: Env Vars
    private var envStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            stepHeader(icon: "list.bullet.rectangle.fill", title: "Environment Variables", subtitle: "Set environment variables for the container")
            
            ForEach(config.envVars.indices, id: \.self) { i in
                HStack(spacing: AXSpacing.sm) {
                    TextField("KEY", text: $config.envVars[i].key)
                        .textFieldStyle(AXTextFieldStyle())
                        .font(.system(size: 12, design: .monospaced))
                    
                    Text("=")
                        .foregroundColor(.axTextMuted)
                    
                    Group {
                        if config.envVars[i].isSecret {
                            SecureField("value", text: $config.envVars[i].value)
                        } else {
                            TextField("value", text: $config.envVars[i].value)
                        }
                    }
                    .textFieldStyle(AXTextFieldStyle())
                    .font(.system(size: 12, design: .monospaced))
                    
                    Button(action: { config.envVars[i].isSecret.toggle() }) {
                        Image(systemName: config.envVars[i].isSecret ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.axTextMuted)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help(config.envVars[i].isSecret ? "Show value" : "Hide value")
                    
                    Button(action: { config.envVars.remove(at: i) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            addButton("Add Variable") {
                config.envVars.append(EnvVar())
            }
        }
    }
    
    // Step 5: Volumes
    private var volumesStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            stepHeader(icon: "externaldrive.fill", title: "Volume Mounts", subtitle: "Mount host directories or named volumes")
            
            ForEach(config.volumes.indices, id: \.self) { i in
                HStack(spacing: AXSpacing.sm) {
                    TextField("Host path or volume", text: $config.volumes[i].hostPath)
                        .textFieldStyle(AXTextFieldStyle())
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    
                    TextField("Container path", text: $config.volumes[i].containerPath)
                        .textFieldStyle(AXTextFieldStyle())
                    
                    Toggle("RO", isOn: $config.volumes[i].readOnly)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 10))
                    
                    Button(action: { config.volumes.remove(at: i) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            addButton("Add Volume") {
                config.volumes.append(VolumeMount())
            }
        }
    }
    
    // Step 6: Network
    private var networkStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            stepHeader(icon: "network", title: "Network", subtitle: "Select a Docker network for this container")
            
            WizardField(label: "Network") {
                Picker("", selection: $config.network) {
                    Text(L10n.Docker.defaultBridge).tag("")
                    ForEach(availableNetworks) { net in
                        Text("\(net.name) (\(net.driver))").tag(net.name)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    // Step 7: Resources
    private var resourcesStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            stepHeader(icon: "cpu.fill", title: "Resource Limits", subtitle: "Set CPU, memory, and restart policy limits")
            
            WizardField(label: "CPU Limit (0 = unlimited)") {
                HStack {
                    Slider(value: $config.cpuLimit, in: 0...8, step: 0.5)
                    Text(config.cpuLimit == 0 ? "∞" : "\(String(format: "%.1f", config.cpuLimit)) cores")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 80, alignment: .trailing)
                }
            }
            
            WizardField(label: "Memory Limit (0 = unlimited)") {
                HStack {
                    Slider(value: Binding(
                        get: { Double(config.memoryLimitMB) },
                        set: { config.memoryLimitMB = Int($0) }
                    ), in: 0...16384, step: 64)
                    Text(config.memoryLimitMB == 0 ? "∞" : "\(config.memoryLimitMB) MB")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 80, alignment: .trailing)
                }
            }
            
            WizardField(label: "Restart Policy") {
                Picker("", selection: $config.restartPolicy) {
                    ForEach(RestartPolicy.allCases) { policy in
                        Text(policy.displayName).tag(policy)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            WizardField(label: "Health Check Command (optional)") {
                TextField("e.g. curl -f http://localhost/ || exit 1", text: $config.healthCheckCmd)
                    .textFieldStyle(AXTextFieldStyle())
                    .font(.system(size: 12, design: .monospaced))
            }
        }
    }
    
    // Step 8: Review
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            stepHeader(icon: "checkmark.seal.fill", title: "Review & Deploy", subtitle: "Review your container configuration")
            
            reviewRow("Image", config.image, icon: "shippingbox.fill")
            reviewRow("Name", config.name, icon: "tag.fill")
            
            if !config.ports.isEmpty {
                reviewRow("Ports", config.ports.map { "\($0.hostPort):\($0.containerPort)/\($0.proto)" }.joined(separator: ", "), icon: "network")
            }
            
            if !config.envVars.isEmpty {
                reviewRow("Env Vars", "\(config.envVars.count) variable(s)", icon: "list.bullet.rectangle.fill")
            }
            
            if !config.volumes.isEmpty {
                reviewRow("Volumes", "\(config.volumes.count) mount(s)", icon: "externaldrive.fill")
            }
            
            if !config.network.isEmpty {
                reviewRow("Network", config.network, icon: "network")
            }
            
            if config.cpuLimit > 0 {
                reviewRow("CPU", "\(String(format: "%.1f", config.cpuLimit)) cores", icon: "cpu.fill")
            }
            
            if config.memoryLimitMB > 0 {
                reviewRow("Memory", "\(config.memoryLimitMB) MB", icon: "memorychip")
            }
            
            reviewRow("Restart", config.restartPolicy.displayName, icon: "arrow.clockwise")
            
            // Command preview
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Docker.generatedCommand)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                
                ScrollView(.horizontal, showsIndicators: true) {
                    Text("docker run \(config.buildFlags()) \(config.image)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                        .padding(AXSpacing.sm)
                }
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.axAccentBlue)
                .frame(width: 36, height: 36)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text(subtitle)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
        }
    }
    
    private func addButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.axAccentBlue)
        }
        .buttonStyle(.plain)
    }
    
    private func reviewRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Deploy
    
    private func deploy() {
        isDeploying = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerService.shared.runContainerAdvanced(
                    config: config,
                    serverId: serverId
                )
                await MainActor.run {
                    isDeploying = false
                    onComplete()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeploying = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Wizard Field

private struct WizardField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(label)
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            content()
        }
    }
}
