
import SwiftUI
import AevonXCore

struct DockerComposeScaleView: View {
    let project: DockerComposeProject
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var services: [(name: String, current: Int, desired: Int)] = []
    @State private var isLoading = true
    @State private var isApplying = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var hasChanges: Bool {
        services.contains { $0.current != $0.desired }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.axAccentBlue)
                    Text("Scale: \(project.name)")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if isLoading {
                VStack { ProgressView(); Text("Loading services...").font(AXTypography.caption).foregroundColor(.axTextMuted) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.md) {
                        ForEach(services.indices, id: \.self) { i in
                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axAccentBlue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(services[i].name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.axTextPrimary)
                                    Text("Current: \(services[i].current) replica(s)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.axTextMuted)
                                }
                                
                                Spacer()
                                
                                // Scale controls
                                HStack(spacing: AXSpacing.sm) {
                                    Button(action: { if services[i].desired > 0 { services[i].desired -= 1 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(services[i].desired > 0 ? .axTextSecondary : .axTextMuted)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(services[i].desired == 0)
                                    
                                    Text("\(services[i].desired)")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(services[i].desired != services[i].current ? .axAccentBlue : .axTextPrimary)
                                        .frame(width: 30)
                                    
                                    Button(action: { services[i].desired += 1 }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.axAccentBlue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Change indicator
                                if services[i].desired != services[i].current {
                                    Image(systemName: services[i].desired > services[i].current ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(services[i].desired > services[i].current ? .axSuccess : .orange)
                                }
                            }
                            .padding(AXSpacing.md)
                            .background(Color.axSurface.opacity(services[i].desired != services[i].current ? 0.8 : 0.3))
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(services[i].desired != services[i].current ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                    .padding(AXSpacing.lg)
                }
                
                // Messages
                if let error = errorMessage {
                    HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                        .font(.system(size: 11)).foregroundColor(.axError)
                        .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axError.opacity(0.08))
                }
                if let success = successMessage {
                    HStack(spacing: 6) { Image(systemName: "checkmark.circle.fill"); Text(success) }
                        .font(.system(size: 11)).foregroundColor(.axSuccess)
                        .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axSuccess.opacity(0.08))
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Reset") {
                    for i in services.indices { services[i].desired = services[i].current }
                }
                .buttonStyle(AXSecondaryButtonStyle())
                .disabled(!hasChanges)
                
                Spacer()
                
                Button(action: applyScale) {
                    HStack(spacing: 4) {
                        if isApplying { ProgressView().controlSize(.small) }
                        Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 10))
                        Text("Apply Scale")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(!hasChanges || isApplying)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 500, height: 400)
        .background(Color.axBackground)
        .task { await loadServices() }
    }
    
    // MARK: - Actions
    
    private func loadServices() async {
        isLoading = true
        do {
            let result = try await DockerManager.shared.getComposeServices(workingDir: project.workingDir, serverId: serverId)
            await MainActor.run {
                services = result.map { (name: $0.name, current: $0.replicas, desired: $0.replicas) }
                isLoading = false
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
        }
    }
    
    private func applyScale() {
        isApplying = true; errorMessage = nil; successMessage = nil
        Task {
            do {
                for service in services where service.desired != service.current {
                    try await DockerManager.shared.composeScale(
                        service: service.name,
                        replicas: service.desired,
                        workingDir: project.workingDir,
                        serverId: serverId
                    )
                }
                await MainActor.run {
                    successMessage = "Scaled successfully"
                    for i in services.indices { services[i].current = services[i].desired }
                    isApplying = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isApplying = false }
            }
        }
    }
}
