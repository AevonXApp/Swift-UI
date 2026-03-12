
import SwiftUI
import AevonXCoreBridge

struct PHPFPMPoolsTab: View {
    let application: ApplicationInstance
    @Binding var phpConfig: PHPConfigData
    let serverId: String
    
    @State private var isCreating = false
    @State private var editingPool: PHPFPMPool?
    @State private var isDeleting: String?
    @State private var pendingDeletePoolName: String?
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FPM Pools")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    
                    Text("\(phpConfig.fpmPools.count) pools configured")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                
                Spacer()
                
                Button(action: { isCreating = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New Pool")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }
            
            if phpConfig.fpmPools.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundColor(.axTextTertiary)
                    Text("No FPM pools configured")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.md) {
                        ForEach(phpConfig.fpmPools) { pool in
                            PoolCard(
                                pool: pool,
                                isDeleting: isDeleting == pool.name,
                                onEdit: { editingPool = pool },
                                onDelete: { pendingDeletePoolName = pool.name }
                            )
                        }
                    }
                }
            }
            }

            if isCreating || editingPool != nil {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isCreating = false
                        editingPool = nil
                    }

                PoolEditorSheet(
                    pool: editingPool,
                    serverId: serverId,
                    onSave: { pool in
                        Task { await savePool(pool) }
                        isCreating = false
                        editingPool = nil
                    },
                    onCancel: {
                        isCreating = false
                        editingPool = nil
                    }
                )
                .frame(maxWidth: 560, maxHeight: 560)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
            }
        }
        .alert("Delete FPM Pool?", isPresented: Binding(
            get: { pendingDeletePoolName != nil },
            set: { if !$0 { pendingDeletePoolName = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let poolName = pendingDeletePoolName {
                    Task { await deletePool(poolName) }
                }
                pendingDeletePoolName = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeletePoolName = nil
            }
        } message: {
            Text("This will permanently delete pool '\(pendingDeletePoolName ?? "")'.")
        }
    }
    
    private func savePool(_ pool: PHPFPMPool) async {
        do {
            if editingPool != nil {
                try await GoApplicationService.shared.updatePHPFPMPool(pool, serverId: serverId)
                GlobalToastManager.shared.showSuccess("FPM pool '\(pool.name)' updated successfully.")
            } else {
                try await GoApplicationService.shared.createPHPFPMPool(pool, serverId: serverId)
                GlobalToastManager.shared.showSuccess("FPM pool '\(pool.name)' created successfully.")
            }
            let pools = try await GoApplicationService.shared.getPHPFPMPools(serverId: serverId)
            phpConfig.fpmPools = pools
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }
    
    private func deletePool(_ name: String) async {
        isDeleting = name
        
        do {
            try await GoApplicationService.shared.deletePHPFPMPool(name: name, serverId: serverId)
            phpConfig.fpmPools.removeAll { $0.name == name }
            GlobalToastManager.shared.showSuccess("FPM pool '\(name)' deleted.")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        
        isDeleting = nil
    }
}

private struct PoolCard: View {
    let pool: PHPFPMPool
    let isDeleting: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                // Pool Name
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "server.rack")
                        .foregroundColor(.axAccentBlue)
                        .font(.system(size: 18))
                    
                    Text(pool.name)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: AXSpacing.xs) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.axSurface.opacity(0.5))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        if isDeleting {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.axError)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .background(Color.axError.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                    .buttonStyle(.plain)
                    .disabled(isDeleting)
                }
            }
            
            Divider()
            
            // Pool Configuration
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.sm) {
                PoolInfo(label: "User", value: pool.user)
                PoolInfo(label: "Group", value: pool.group)
                PoolInfo(label: "Listen", value: pool.listenAddress)
                PoolInfo(label: "PM", value: pool.pm.rawValue)
                PoolInfo(label: "Max Children", value: "\(pool.pmMaxChildren)")
                if let startServers = pool.pmStartServers {
                    PoolInfo(label: "Start Servers", value: "\(startServers)")
                }
            }
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

private struct PoolInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            Spacer()
            Text(value)
                .font(AXTypography.caption)
                .foregroundColor(.axTextPrimary)
                .monospaced()
        }
    }
}

private struct PoolEditorSheet: View {
    let pool: PHPFPMPool?
    let serverId: String
    let onSave: (PHPFPMPool) -> Void
    let onCancel: () -> Void
    
    @State private var name = ""
    @State private var user = "www-data"
    @State private var group = "www-data"
    @State private var listenAddress = ""
    @State private var pmMode = PHPFPMPool.PMMode.dynamic
    @State private var maxChildren = "50"
    @State private var hasResolvedSocket = false

    init(pool: PHPFPMPool?, serverId: String, onSave: @escaping (PHPFPMPool) -> Void, onCancel: @escaping () -> Void) {
        self.pool = pool
        self.serverId = serverId
        self.onSave = onSave
        self.onCancel = onCancel

        _name = State(initialValue: pool?.name ?? "")
        _user = State(initialValue: pool?.user ?? "www-data")
        _group = State(initialValue: pool?.group ?? "www-data")
        _listenAddress = State(initialValue: pool?.listenAddress ?? "")
        _pmMode = State(initialValue: pool?.pm ?? .dynamic)
        _maxChildren = State(initialValue: String(pool?.pmMaxChildren ?? 50))
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text(pool == nil ? "Create FPM Pool" : "Edit FPM Pool")
                .font(.system(size: 20, weight: .bold))
            
            Form {
                TextField("Pool Name", text: $name)
                TextField("User", text: $user)
                TextField("Group", text: $group)
                TextField("Listen Address", text: $listenAddress)
                Picker("Process Manager", selection: $pmMode) {
                    Text("Dynamic").tag(PHPFPMPool.PMMode.dynamic)
                    Text("Static").tag(PHPFPMPool.PMMode.`static`)
                    Text("On Demand").tag(PHPFPMPool.PMMode.ondemand)
                }
                TextField("Max Children", text: $maxChildren)
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                
                Button(pool == nil ? "Create" : "Save") {
                    let newPool = PHPFPMPool(
                        name: name,
                        user: user,
                        group: group,
                        listenAddress: listenAddress,
                        pm: pmMode,
                        pmMaxChildren: Int(maxChildren) ?? 50
                    )
                    onSave(newPool)
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            // Dynamically resolve socket path for new pools
            if pool == nil && listenAddress.isEmpty {
                Task {
                    let resolved = "/run/php/php-fpm.sock"
                    if !resolved.isEmpty {
                        await MainActor.run { listenAddress = resolved }
                    }
                }
            }
        }
    }
}
