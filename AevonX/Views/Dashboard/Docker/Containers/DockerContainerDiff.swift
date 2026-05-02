
import SwiftUI
import AevonXCoreBridge

struct DockerContainerDiff: View {
    let container: DockerContainer
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var changes: [(kind: String, path: String)] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var filterType: String = "all"
    
    var filteredChanges: [(kind: String, path: String)] {
        if filterType == "all" { return changes }
        return changes.filter { $0.kind == filterType }
    }
    
    var addedCount: Int { changes.filter { $0.kind == "A" }.count }
    var modifiedCount: Int { changes.filter { $0.kind == "C" }.count }
    var deletedCount: Int { changes.filter { $0.kind == "D" }.count }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.badge.plus")
                        .foregroundColor(.orange)
                    Text(L10n.Docker.containerFilesystemChanges)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Text(container.names)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.axSurface)
                    .cornerRadius(4)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            // Stats + Filters
            HStack(spacing: AXSpacing.md) {
                filterChip(label: "All (\(changes.count))", isActive: filterType == "all") { filterType = "all" }
                filterChip(label: "Added (\(addedCount))", isActive: filterType == "A", color: .axSuccess) { filterType = "A" }
                filterChip(label: "Modified (\(modifiedCount))", isActive: filterType == "C", color: .axWarning) { filterType = "C" }
                filterChip(label: "Deleted (\(deletedCount))", isActive: filterType == "D", color: .axError) { filterType = "D" }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface.opacity(0.5))
            
            Divider()
            
            // Changes list
            if isLoading {
                ProgressView("Analyzing filesystem changes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if changes.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.axSuccess)
                    Text(L10n.Docker.noFilesystemChanges)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextSecondary)
                    Text(L10n.Docker.containerMatchesItsBaseImage)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredChanges, id: \.path) { change in
                        HStack(spacing: AXSpacing.sm) {
                            Text(change.kind)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(kindColor(change.kind))
                                .frame(width: 16, height: 16)
                                .background(kindColor(change.kind).opacity(0.1))
                                .cornerRadius(3)
                            
                            Image(systemName: change.path.hasSuffix("/") ? "folder.fill" : "doc")
                                .font(.system(size: 11))
                                .foregroundColor(.axTextMuted)
                            
                            Text(change.path)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                        }
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
        .task { await loadDiff() }
    }
    
    private func filterChip(label: String, isActive: Bool, color: Color = .axAccentBlue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: isActive ? .bold : .regular))
                .foregroundColor(isActive ? color : .axTextMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? color.opacity(0.1) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
    
    private func kindColor(_ kind: String) -> Color {
        switch kind {
        case "A": return .axSuccess
        case "C": return .axWarning
        case "D": return .axError
        default: return .axTextMuted
        }
    }
    
    private func loadDiff() async {
        do {
            let result = try await DockerService.shared.diffContainer(id: container.id, serverId: serverId)
            let parsed = result.map { (kind: $0.kind, path: $0.path) }
            await MainActor.run { changes = parsed; isLoading = false }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
        }
    }
}
