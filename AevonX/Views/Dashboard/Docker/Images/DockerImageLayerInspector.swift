
import SwiftUI
import AevonXCoreBridge

struct DockerImageLayerInspector: View {
    let image: DockerImage
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var layers: [(created: String, createdBy: String, size: String)] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var totalSize: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.down.right.fill")
                        .foregroundColor(.axAccentBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Image Layers")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("\(image.repository):\(image.tag)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
                
                if !totalSize.isEmpty {
                    Text(totalSize)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Loading image layers...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.axError)
                    Text(error).font(AXTypography.caption).foregroundColor(.axError)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Layer list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(layers.indices, id: \.self) { i in
                            let layer = layers[i]
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    // Layer number
                                    Text("Layer \(layers.count - i)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.axAccentBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.axAccentBlue.opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    // Size
                                    Text(layer.size)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(layerSizeColor(layer.size))
                                    
                                    // Size bar
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(layerSizeColor(layer.size).opacity(0.3))
                                        .frame(width: sizeBarWidth(layer.size), height: 4)
                                }
                                
                                // Command
                                Text(cleanCommand(layer.createdBy))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(3)
                                
                                Text(layer.created)
                                    .font(.system(size: 9))
                                    .foregroundColor(.axTextMuted)
                            }
                            .padding(AXSpacing.sm)
                            .background(i % 2 == 0 ? Color.axSurface.opacity(0.3) : Color.clear)
                        }
                    }
                    .padding(AXSpacing.md)
                }
            }
        }
        .frame(width: 650, height: 480)
        .background(Color.axBackground)
        .task { await loadLayers() }
    }
    
    // MARK: - Helpers
    
    private func cleanCommand(_ cmd: String) -> String {
        var c = cmd
        c = c.replacingOccurrences(of: "/bin/sh -c #(nop) ", with: "")
        c = c.replacingOccurrences(of: "/bin/sh -c ", with: "RUN ")
        return c.trimmingCharacters(in: .whitespaces)
    }
    
    private func layerSizeColor(_ size: String) -> Color {
        if size.contains("MB") {
            let val = Double(size.replacingOccurrences(of: "MB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            if val > 100 { return .red }
            if val > 10 { return .orange }
        }
        if size.contains("GB") { return .red }
        return .axAccentBlue
    }
    
    private func sizeBarWidth(_ size: String) -> CGFloat {
        var bytes: Double = 0
        if size.contains("GB") { bytes = (Double(size.replacingOccurrences(of: "GB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0) * 1024 }
        else if size.contains("MB") { bytes = Double(size.replacingOccurrences(of: "MB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0 }
        else if size.contains("KB") || size.contains("kB") { bytes = (Double(size.replacingOccurrences(of: "KB", with: "").replacingOccurrences(of: "kB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0) / 1024 }
        else { bytes = 0.1 }
        return CGFloat(min(max(bytes / 5, 4), 80))
    }
    
    // MARK: - Load
    
    private func loadLayers() async {
        isLoading = true
        do {
            let result = try await DockerService.shared.getImageLayers(id: image.id, serverId: serverId)
            await MainActor.run {
                layers = result.map { (created: $0.created, createdBy: $0.createdBy, size: $0.size) }
                totalSize = image.size
                isLoading = false
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
        }
    }
}
