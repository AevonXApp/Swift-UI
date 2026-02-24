
import SwiftUI
import AevonXCore

struct DockerBulkActionsBar: View {
    let selectedContainers: Set<String>
    let serverId: String
    let onComplete: () -> Void
    
    @State private var isActing = false
    @State private var errorMessage: String?
    
    var count: Int { selectedContainers.count }
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Text("\(count) selected")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.axTextPrimary)
            
            Divider().frame(height: 16)
            
            bulkButton(icon: "play.fill", label: "Start All", color: .axSuccess) {
                await bulkAction("start")
            }
            
            bulkButton(icon: "stop.fill", label: "Stop All", color: .orange) {
                await bulkAction("stop")
            }
            
            bulkButton(icon: "arrow.clockwise", label: "Restart All", color: .axWarning) {
                await bulkAction("restart")
            }
            
            Divider().frame(height: 16)
            
            bulkButton(icon: "trash", label: "Remove All", color: .axError) {
                await bulkAction("remove")
            }
            
            Spacer()
            
            if isActing {
                ProgressView().controlSize(.small)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundColor(.axError)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axAccentBlue.opacity(0.08))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
    }
    
    private func bulkButton(icon: String, label: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button(action: {
            Task { await action() }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.08))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isActing)
    }
    
    private func bulkAction(_ action: String) async {
        isActing = true
        errorMessage = nil
        
        do {
            for id in selectedContainers {
                switch action {
                case "start":
                    try await DockerManager.shared.startContainer(id: id, serverId: serverId)
                case "stop":
                    try await DockerManager.shared.stopContainer(id: id, serverId: serverId)
                case "restart":
                    try await DockerManager.shared.restartContainer(id: id, serverId: serverId)
                case "remove":
                    try await DockerManager.shared.removeContainer(id: id, force: false, serverId: serverId)
                default: break
                }
            }
            await MainActor.run { isActing = false; onComplete() }
        } catch {
            await MainActor.run { isActing = false; errorMessage = error.localizedDescription }
        }
    }
}
