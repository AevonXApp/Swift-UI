
import SwiftUI
import AevonXCore

struct DockerNetworkInspector: View {
    let network: DockerNetwork
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var connectedContainers: [(name: String, ip: String, mac: String)] = []
    @State private var subnet: String = ""
    @State private var gateway: String = ""
    @State private var scope: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "network")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(network.name)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("Driver: \(network.driver)")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextSecondary)
                    }
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
                VStack { ProgressView(); Text("Inspecting network...").font(AXTypography.caption).foregroundColor(.axTextMuted) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        // Network info
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Network Configuration")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.axTextPrimary)
                            
                            HStack(spacing: AXSpacing.xl) {
                                infoBox("Subnet", subnet.isEmpty ? "—" : subnet)
                                infoBox("Gateway", gateway.isEmpty ? "—" : gateway)
                                infoBox("Scope", scope.isEmpty ? "—" : scope)
                                infoBox("Driver", network.driver)
                            }
                        }
                        
                        Divider()
                        
                        // Connected containers
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            HStack {
                                Text("Connected Containers")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.axTextPrimary)
                                Text("\(connectedContainers.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.axAccentBlue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.md)
                            }
                            
                            if connectedContainers.isEmpty {
                                Text("No containers connected")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                    .padding(.vertical, AXSpacing.lg)
                                    .frame(maxWidth: .infinity)
                            } else {
                                // Header
                                HStack {
                                    Text("Container").frame(maxWidth: .infinity, alignment: .leading)
                                    Text("IP Address").frame(width: 140, alignment: .leading)
                                    Text("MAC Address").frame(width: 160, alignment: .leading)
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.axTextSecondary)
                                .padding(.horizontal, AXSpacing.sm)
                                
                                ForEach(connectedContainers.indices, id: \.self) { i in
                                    HStack {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color.axSuccess)
                                                .frame(width: 6, height: 6)
                                            Text(connectedContainers[i].name)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.axTextPrimary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(connectedContainers[i].ip)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.axAccentBlue)
                                            .frame(width: 140, alignment: .leading)
                                        
                                        Text(connectedContainers[i].mac)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.axTextMuted)
                                            .frame(width: 160, alignment: .leading)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, AXSpacing.sm)
                                    .background(i % 2 == 0 ? Color.axSurface.opacity(0.3) : Color.clear)
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
            
            if let error = errorMessage {
                HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                    .font(.system(size: 11)).foregroundColor(.axError)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axError.opacity(0.08))
            }
        }
        .frame(width: 600, height: 420)
        .background(Color.axBackground)
        .task { await loadDetails() }
    }
    
    private func infoBox(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.axTextMuted)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
        .padding(AXSpacing.sm)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    // MARK: - Load
    
    private func loadDetails() async {
        isLoading = true
        do {
            let inspection = try await DockerManager.shared.inspectNetwork(id: network.id, serverId: serverId)
            
            await MainActor.run {
                subnet = inspection.subnet
                gateway = inspection.gateway
                scope = inspection.scope
                connectedContainers = inspection.connectedContainers
                isLoading = false
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
        }
    }
}
