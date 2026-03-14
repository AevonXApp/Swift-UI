
import SwiftUI
import AevonXCoreBridge

struct DockerVolumeBrowser: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var volumes: [DockerVolume] = []
    @State private var selectedVolume: String = ""
    @State private var currentPath: String = "/"
    @State private var files: [(name: String, isDir: Bool, size: String)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.axAccentBlue)
                    Text("Volume Browser")
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
            
            // Volume picker + Path
            HStack(spacing: AXSpacing.sm) {
                Picker("Volume", selection: $selectedVolume) {
                    Text("Select volume...").tag("")
                    ForEach(volumes, id: \.name) { v in
                        Text(v.name).tag(v.name)
                    }
                }
                .frame(maxWidth: 200)
                .onChange(of: selectedVolume) { _, _ in
                    currentPath = "/"
                    loadFiles()
                }
                
                // Breadcrumb path
                HStack(spacing: 2) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.axTextMuted)
                    Text(currentPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                }
                
                Spacer()
                
                if currentPath != "/" {
                    Button(action: goUp) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up").font(.system(size: 10))
                            Text("Up").font(.system(size: 10))
                        }
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface.opacity(0.5))
            
            Divider()
            
            // File list
            if selectedVolume.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 40))
                        .foregroundColor(.axTextMuted)
                    Text("Select a volume to browse")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if files.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.axTextMuted)
                    Text("Empty directory")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(files, id: \.name) { file in
                        Button(action: {
                            if file.isDir {
                                let newPath = currentPath == "/" ? "/\(file.name)" : "\(currentPath)/\(file.name)"
                                currentPath = newPath
                                loadFiles()
                            }
                        }) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: file.isDir ? "folder.fill" : fileIcon(file.name))
                                    .font(.system(size: 14))
                                    .foregroundColor(file.isDir ? .axAccentBlue : .axTextSecondary)
                                    .frame(width: 20)
                                
                                Text(file.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Text(file.size)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axTextMuted)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
            
            if let error = errorMessage {
                HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                    .font(.system(size: 11)).foregroundColor(.axError)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axError.opacity(0.08))
            }
        }
        .frame(width: 550, height: 450)
        .background(Color.axBackground)
        .task {
            do {
                volumes = try await DockerService.shared.getVolumes(serverId: serverId)
            } catch {}
        }
    }
    
    private func loadFiles() {
        guard !selectedVolume.isEmpty else { return }
        isLoading = true; errorMessage = nil
        Task {
            do {
                let result = try await DockerService.shared.browseVolume(name: selectedVolume, path: currentPath, serverId: serverId)
                let parsed = result.map { (name: $0.name, isDir: $0.isDir, size: $0.size) }
                await MainActor.run { files = parsed; isLoading = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
            }
        }
    }
    
    private func goUp() {
        let components = currentPath.split(separator: "/")
        if components.count <= 1 {
            currentPath = "/"
        } else {
            currentPath = "/" + components.dropLast().joined(separator: "/")
        }
        loadFiles()
    }
    
    private func fileIcon(_ name: String) -> String {
        let ext = name.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "yml", "yaml", "json", "xml", "toml": return "doc.text"
        case "log", "txt": return "doc.plaintext"
        case "sh", "bash": return "terminal"
        case "conf", "cfg", "ini": return "gearshape"
        case "gz", "tar", "zip": return "archivebox"
        case "db", "sql", "sqlite": return "cylinder"
        default: return "doc"
        }
    }
}
