
import SwiftUI
import AevonXCore

struct DockerDependencyGraphView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var dependencies: [DockerManager.ContainerDependency] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Unique container names
    private var containerNames: [String] {
        var names = Set<String>()
        for dep in dependencies {
            names.insert(dep.sourceContainer)
            names.insert(dep.targetContainer)
        }
        return names.sorted()
    }
    
    private let nodeColors: [Color] = [.axAccentBlue, .axSuccess, .purple, .orange, .cyan, .pink, .mint, .indigo, .red, .yellow]
    
    private func colorFor(_ name: String) -> Color {
        let idx = containerNames.firstIndex(of: name) ?? 0
        return nodeColors[idx % nodeColors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Container Dependencies", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                
                Button { loadDependencies() } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
                
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            
            Divider()
            
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    if isLoading {
                        ProgressView("Detecting dependencies...").padding(30)
                    } else if dependencies.isEmpty {
                        VStack(spacing: AXSpacing.sm) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 40))
                                .foregroundColor(.axTextMuted)
                            Text("No dependencies found")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                            Text("Containers sharing networks or volumes will appear here")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                        .padding(30)
                    } else {
                        // Container nodes
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Containers (\(containerNames.count))")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            // Nodes grid
                            let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(containerNames, id: \.self) { name in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(colorFor(name))
                                            .frame(width: 10, height: 10)
                                        Text(name)
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextPrimary)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(colorFor(name).opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                            .stroke(colorFor(name).opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Connections
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Connections (\(dependencies.count))")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            ForEach(Array(dependencies.enumerated()), id: \.offset) { _, dep in
                                AXCard {
                                    HStack(spacing: AXSpacing.sm) {
                                        // Source
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(colorFor(dep.sourceContainer))
                                                .frame(width: 8, height: 8)
                                            Text(dep.sourceContainer)
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextPrimary)
                                        }
                                        
                                        // Arrow with type
                                        VStack(spacing: 2) {
                                            Image(systemName: "arrow.left.and.right")
                                                .font(.system(size: 10))
                                                .foregroundColor(.axTextMuted)
                                            Text(dep.dependencyType)
                                                .font(AXTypography.caption2)
                                                .foregroundColor(dep.dependencyType.contains("network") ? .axAccentBlue : .purple)
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        // Target
                                        HStack(spacing: 4) {
                                            Text(dep.targetContainer)
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextPrimary)
                                            Circle()
                                                .fill(colorFor(dep.targetContainer))
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error).font(AXTypography.caption).foregroundColor(.axError)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, minHeight: 400)
        .background(Color.axBackground)
        .onAppear { loadDependencies() }
    }
    
    private func loadDependencies() {
        isLoading = true
        Task {
            do {
                let deps = try await DockerManager.shared.detectContainerDependencies(serverId: serverId)
                await MainActor.run { dependencies = deps; isLoading = false }
            } catch {
                await MainActor.run { isLoading = false; errorMessage = error.localizedDescription }
            }
        }
    }
}
