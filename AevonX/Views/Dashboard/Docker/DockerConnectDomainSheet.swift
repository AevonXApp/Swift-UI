
import SwiftUI
import AevonXCoreBridge

struct DockerConnectDomainSheet: View {
    let container: DockerContainer
    let serverId: String
    var existingDomain: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var domain: String = ""
    @State private var selectedPort: String = ""
    @State private var detectedPorts: [(hostPort: String, containerPort: String)] = []
    @State private var enableSSL: Bool = true
    @State private var enableWebSocket: Bool = false
    @State private var isLoading: Bool = false
    @State private var isConnecting: Bool = false
    @State private var isDisconnecting: Bool = false
    @State private var progressSteps: [String] = []
    @State private var isComplete: Bool = false
    @State private var hasFailed: Bool = false
    @State private var errorMessage: String?
    @State private var showChangeForm: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .foregroundColor(existingDomain != nil && !showChangeForm ? .axSuccess : .axAccentBlue)
                            .font(.system(size: 16))
                        Text(existingDomain != nil && !showChangeForm ? "Manage Domain" : "Connect Domain")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    Text(existingDomain != nil && !showChangeForm ? "Domain connected to \(container.names)" : "Route a domain to \(container.names)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if isConnecting || isDisconnecting {
                // Progress / Result view
                VStack(spacing: AXSpacing.lg) {
                    Spacer()
                    
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.axSuccess)
                    } else if hasFailed {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.axError)
                    } else {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                    
                    // Progress steps log
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(progressSteps, id: \.self) { step in
                            HStack(spacing: 6) {
                                Image(systemName: step.contains("✅") ? "checkmark.circle.fill" : step.contains("❌") ? "xmark.circle.fill" : "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(step.contains("✅") ? .axSuccess : step.contains("❌") ? .axError : .axTextMuted)
                                Text(step.replacingOccurrences(of: "✅", with: "").replacingOccurrences(of: "❌", with: "").trimmingCharacters(in: .whitespaces))
                                    .font(.system(size: 12))
                                    .foregroundColor(step.contains("✅") ? .axSuccess : step.contains("❌") ? .axError : .axTextSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: 380, alignment: .leading)
                    
                    if isComplete {
                        VStack(spacing: AXSpacing.sm) {
                            Text("Your container is now accessible at:")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            Text(enableSSL ? "https://\(domain)" : "http://\(domain)")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.axAccentBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.axAccentBlue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .padding(.top, AXSpacing.sm)
                        
                        Button("Done") { dismiss() }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.axAccentBlue)
                            .foregroundColor(.white)
                            .cornerRadius(AXCornerRadius.md)
                            .padding(.top, AXSpacing.md)
                    }
                    
                    if hasFailed {
                        VStack(spacing: AXSpacing.md) {
                            if let error = errorMessage {
                                Text(error)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axError)
                                    .multilineTextAlignment(.center)
                                    .padding(AXSpacing.sm)
                                    .frame(maxWidth: 380)
                                    .background(Color.axError.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            
                            HStack(spacing: AXSpacing.md) {
                                Button("Back") {
                                    isConnecting = false
                                    hasFailed = false
                                    progressSteps.removeAll()
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.axTextSecondary)
                                
                                Button("Retry") {
                                    hasFailed = false
                                    errorMessage = nil
                                    progressSteps.removeAll()
                                    performConnect()
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.axAccentBlue)
                                .foregroundColor(.white)
                                .cornerRadius(AXCornerRadius.md)
                            }
                        }
                        .padding(.top, AXSpacing.sm)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(AXSpacing.xl)
            } else if let currentDomain = existingDomain, !showChangeForm {
                // Manage existing domain
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            // Current domain card
                            VStack(spacing: AXSpacing.md) {
                                HStack(spacing: AXSpacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.axSuccess.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "globe")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.axSuccess)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Active Domain")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.axSuccess)
                                            .tracking(0.5)
                                        Text(currentDomain)
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(.axTextPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Status badge
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.axSuccess)
                                            .frame(width: 6, height: 6)
                                        Text("Connected")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundColor(.axSuccess)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.axSuccess.opacity(0.1))
                                    .cornerRadius(20)
                                }
                                
                                // URL preview
                                HStack(spacing: 6) {
                                    Image(systemName: "link")
                                        .font(.system(size: 10))
                                        .foregroundColor(.axAccentBlue)
                                    Text("https://\(currentDomain)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.axAccentBlue)
                                    Spacer()
                                    Button {
                                        if let url = URL(string: "https://\(currentDomain)") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    } label: {
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 11))
                                            .foregroundColor(.axAccentBlue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(10)
                                .background(Color.axAccentBlue.opacity(0.05))
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.axAccentBlue.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .padding(AXSpacing.lg)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axSuccess.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Container info
                            AXCard {
                                HStack(spacing: AXSpacing.md) {
                                    Circle()
                                        .fill(container.isRunning ? Color.axSuccess : Color.axTextMuted)
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(container.names)
                                            .font(AXTypography.headline)
                                            .foregroundColor(.axTextPrimary)
                                        Text(container.image)
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextSecondary)
                                    }
                                    Spacer()
                                    if !container.ports.isEmpty {
                                        Text(container.ports)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.axTextMuted)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(AXSpacing.lg)
                    }
                    
                    Divider()
                    
                    // Actions footer
                    HStack(spacing: AXSpacing.md) {
                        // Disconnect button
                        Button {
                            isDisconnecting = true
                            performDisconnect(domain: currentDomain)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.axError)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.axError.opacity(0.1))
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Change domain button
                        Button {
                            showChangeForm = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Change Domain")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface)
                }
            } else {
                // Form (new connection or changing domain)
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        
                        // Container Info
                        AXCard {
                            HStack(spacing: AXSpacing.md) {
                                Circle()
                                    .fill(container.isRunning ? Color.axSuccess : Color.axTextMuted)
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(container.names)
                                        .font(AXTypography.headline)
                                        .foregroundColor(.axTextPrimary)
                                    Text(container.image)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                }
                                Spacer()
                                if !container.ports.isEmpty {
                                    Text(container.ports)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        // Port Selection
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Container Port")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextSecondary)
                            
                            if isLoading {
                                HStack {
                                    ProgressView().scaleEffect(0.7)
                                    Text("Detecting ports...")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                }
                            } else if detectedPorts.isEmpty {
                                HStack(spacing: AXSpacing.sm) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.axWarning)
                                        .font(.system(size: 12))
                                    Text("No exposed ports detected. Enter manually.")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axWarning)
                                }
                                
                                TextField("Port (e.g. 8080)", text: $selectedPort)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            } else {
                                HStack(spacing: AXSpacing.sm) {
                                    ForEach(detectedPorts, id: \.hostPort) { port in
                                        Button(action: { selectedPort = port.hostPort }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: selectedPort == port.hostPort ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 12))
                                                Text(":\(port.hostPort)")
                                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                Text("→ :\(port.containerPort)")
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(.axTextMuted)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(selectedPort == port.hostPort ? Color.axAccentBlue.opacity(0.1) : Color.axSurface)
                                            .foregroundColor(selectedPort == port.hostPort ? .axAccentBlue : .axTextSecondary)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(selectedPort == port.hostPort ? Color.axAccentBlue.opacity(0.5) : Color.axBorder, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Domain Input
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Domain Name")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextSecondary)
                            
                            TextField("example.com", text: $domain)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            
                            Text("Make sure DNS A record points to your server IP")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }
                        
                        // Options
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Options")
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextSecondary)
                            
                            Toggle(isOn: $enableSSL) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axSuccess)
                                    Text("Enable SSL (Let's Encrypt)")
                                        .font(AXTypography.caption)
                                }
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            
                            Toggle(isOn: $enableWebSocket) {
                                HStack(spacing: 6) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axAccentBlue)
                                    Text("Enable WebSocket Support")
                                        .font(AXTypography.caption)
                                }
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                    }
                    .padding(AXSpacing.lg)
                }
                
                Divider()
                
                // Footer
                HStack {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundColor(.axTextSecondary)
                    
                    Spacer()
                    
                    Button(action: {
                        isConnecting = true
                        performConnect()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                            Text("Connect Domain")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(canConnect ? Color.axAccentBlue : Color.axSurface)
                        .foregroundColor(canConnect ? .white : .axTextMuted)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canConnect)
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
            }
        }
        .frame(width: 520, height: 560)
        .background(Color.axBackground)
        .onAppear { detectPorts() }
    }
    
    private var canConnect: Bool {
        !domain.isEmpty && !selectedPort.isEmpty && domain.contains(".")
    }
    
    private func detectPorts() {
        isLoading = true
        Task {
            do {
                let portStrings = try await DockerService.shared.getContainerPorts(id: container.id, serverId: serverId)
                await MainActor.run {
                    // Parse "80/tcp -> 0.0.0.0:8080" format into tuples
                    detectedPorts = portStrings.compactMap { line in
                        let parts = line.components(separatedBy: " -> ")
                        guard parts.count >= 2 else {
                            // Simple format: just "8080"
                            let port = line.trimmingCharacters(in: .whitespaces)
                            return (hostPort: port, containerPort: port)
                        }
                        let containerPort = parts[0].components(separatedBy: "/").first ?? parts[0]
                        let hostPort = parts[1].components(separatedBy: ":").last ?? parts[1]
                        return (hostPort: hostPort.trimmingCharacters(in: .whitespaces),
                                containerPort: containerPort.trimmingCharacters(in: .whitespaces))
                    }
                    if let first = detectedPorts.first {
                        selectedPort = first.hostPort
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func performConnect() {
        errorMessage = nil
        progressSteps = ["Starting connection..."]
        
        Task {
            do {
                try await DockerService.shared.connectDomain(
                    domain: domain,
                    containerId: container.id,
                    containerPort: Int(selectedPort) ?? 80,
                    serverId: serverId,
                    progress: { text in
                        Task { @MainActor in
                            progressSteps.append(text)
                        }
                    }
                )
                // Mark as complete after successful return
                await MainActor.run {
                    progressSteps.append("Domain connected successfully ✅")
                    isComplete = true
                }
            } catch {
                await MainActor.run {
                    progressSteps.append("❌ Failed: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    hasFailed = true
                }
            }
        }
    }
    private func performDisconnect(domain: String) {
        errorMessage = nil
        progressSteps = ["Disconnecting domain \(domain)..."]
        
        Task {
            do {
                try await DockerService.shared.disconnectDomain(domain: domain, serverId: serverId)
                await MainActor.run {
                    progressSteps.append("Nginx configuration removed ✅")
                    progressSteps.append("Domain disconnected successfully ✅")
                    isComplete = true
                }
            } catch {
                await MainActor.run {
                    progressSteps.append("❌ Failed: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    hasFailed = true
                }
            }
        }
    }
}
