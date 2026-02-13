//
//  RemoteFleetView.swift
//X
//
//   Aevon Remote Fleet UI - Connected to Core for real data
//

import SwiftUI
import AevonXCore

// MARK: - Edit Server View (Enhanced Version)
struct EditServerView: View {
    @Environment(\.dismiss) private var dismiss
    let server: ServerViewModel
    let onSave: (AddServerRequest) -> Void

    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = ""
    @State private var username: String = ""
    @State private var authType: AuthenticationType = .password
    @State private var password: String = ""
    @State private var privateKey: String = ""
    @State private var keyPassphrase: String = ""
    @State private var tagsText: String = ""
    @State private var selectedIcon: ServerIcon = .serverRack
    @State private var selectedColor: ServerColor = .blue
    @State private var hasChanges: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                // Header with enhanced styling
                HStack(spacing: AXSpacing.md) {
                    // Server Icon Preview
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: selectedColor.rawValue).opacity(0.25), Color(hex: selectedColor.rawValue).opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: selectedIcon.rawValue)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color(hex: selectedColor.rawValue))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Server")
                            .font(AXTypography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)

                        Text(server.name)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.axTextMuted)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.top, AXSpacing.xl)
                
                Divider()
                    .background(Color.axBorder)
                    .padding(.horizontal, AXSpacing.xl)
                
                // Server Identity Section
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Server Identity")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                    
                    VStack(spacing: AXSpacing.md) {
                        // Name
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Server Name")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            TextField("Server Name", text: $name)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.md)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                        }
                        
                        // Icon Picker
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Icon")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AXSpacing.sm) {
                                    ForEach(ServerIcon.allCases) { icon in
                                        Button {
                                            selectedIcon = icon
                                        } label: {
                                            Image(systemName: icon.rawValue)
                                                .font(.system(size: 18))
                                                .foregroundColor(selectedIcon == icon ? .white : .axTextSecondary)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                        .fill(selectedIcon == icon ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Color")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            HStack(spacing: AXSpacing.sm) {
                                ForEach(ServerColor.allCases) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color.rawValue))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                            .overlay {
                                                if selectedColor == color {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Tags with helper text
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            HStack(spacing: AXSpacing.xs) {
                                Text("Tags (optional)")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)

                                Image(systemName: "info.circle")
                                    .font(.system(size: 10))
                                    .foregroundColor(.axAccentBlue)
                                    .help("Add tags like 'production', 'staging', or 'development' to enable environment filters")
                            }

                            TextField("production, staging, web, database", text: $tagsText)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.md)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("💡 Environment Filter Tags:")
                                    .font(AXTypography.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axAccentBlue)

                                Group {
                                    Text("• Production: ") +
                                    Text("production, prod, live, prd, main").foregroundColor(.axTextTertiary)

                                    Text("• Staging: ") +
                                    Text("staging, stage, stg, uat, pre-prod").foregroundColor(.axTextTertiary)

                                    Text("• Development: ") +
                                    Text("development, dev, test, local, sandbox").foregroundColor(.axTextTertiary)
                                }
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextSecondary)
                            }
                            .padding(AXSpacing.sm)
                            .background(Color.axAccentBlue.opacity(0.05))
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, AXSpacing.lg)
                }
                
                // Connection Details Section
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Connection Details")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                    
                    VStack(spacing: AXSpacing.md) {
                        // Host
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Host")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            TextField("server.example.com", text: $host)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.md)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                        }
                        
                        HStack(spacing: AXSpacing.md) {
                            // Port
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("Port")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                TextField("22", text: $port)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                                    .frame(maxWidth: 100)
                            }
                            
                            // Username
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("Username")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                TextField("root", text: $username)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, AXSpacing.lg)
                }
                
                // Authentication Section
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Authentication")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                    
                    VStack(spacing: AXSpacing.md) {
                        // Auth Type Picker
                        HStack(spacing: AXSpacing.sm) {
                            ForEach([AuthenticationType.password, .privateKey], id: \.self) { type in
                                Button {
                                    authType = type
                                } label: {
                                    HStack(spacing: AXSpacing.xs) {
                                        Image(systemName: type == .password ? "lock.fill" : "key.fill")
                                            .font(.system(size: 12))
                                        Text(type == .password ? "Password" : "Private Key")
                                            .font(AXTypography.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(authType == type ? .white : .axTextSecondary)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .fill(authType == type ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Auth Fields
                        if authType == .password {
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("Password")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                SecureField("Enter SSH password", text: $password)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            }
                        } else {
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text("Private Key")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                TextEditor(text: $privateKey)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(minHeight: 100)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                                
                                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                    Text("Key Passphrase (optional)")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                    SecureField("Optional passphrase", text: $keyPassphrase)
                                        .font(AXTypography.body)
                                        .foregroundColor(.axTextPrimary)
                                        .padding(AXSpacing.md)
                                        .background(Color.axSurface)
                                        .cornerRadius(AXCornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .stroke(Color.axBorder, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, AXSpacing.lg)
                }
                
                // Action Buttons with enhanced styling
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.axBorder)

                    HStack(spacing: AXSpacing.md) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12))
                                Text("Cancel")
                            }
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.cancelAction)

                        Button {
                            let request = AddServerRequest(
                                name: name,
                                host: host,
                                port: Int(port) ?? 22,
                                username: username,
                                authType: authType,
                                password: password.isEmpty ? nil : password,
                                privateKey: privateKey.isEmpty ? nil : privateKey,
                                keyPassphrase: keyPassphrase.isEmpty ? nil : keyPassphrase,
                                tags: tagsText.isEmpty ? [] : tagsText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                                notes: nil,
                                iconName: selectedIcon.rawValue,
                                customColor: selectedColor.rawValue
                            )
                            onSave(request)
                            dismiss()
                        } label: {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Save Changes")
                            }
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(
                                LinearGradient(
                                    colors: (name.isEmpty || host.isEmpty || username.isEmpty)
                                        ? [Color.axTextMuted, Color.axTextMuted.opacity(0.8)]
                                        : [Color.axAccentBlue, Color.axAccentBlue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(AXCornerRadius.md)
                            .shadow(
                                color: (name.isEmpty || host.isEmpty || username.isEmpty) ? .clear : Color.axAccentBlue.opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(name.isEmpty || host.isEmpty || username.isEmpty)
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding(AXSpacing.xl)
                }
                
                Spacer(minLength: AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
        .preferredColorScheme(.dark)
        .onAppear {
            name = server.name
            host = server.host
            port = String(server.port)
            username = server.username
            tagsText = server.tags.joined(separator: ", ")
            selectedIcon = ServerIcon(rawValue: server.iconName) ?? .serverRack
            if let hex = server.customColor {
                selectedColor = ServerColor(rawValue: hex) ?? .blue
            }
        }
    }
}

#Preview {
    RemoteFleetView(
        viewModel: ServerListViewModel(),
        selectedServer: .constant(nil),
        showAddServer: .constant(false),
        showServerDashboard: .constant(false)
    )
    .frame(width: 1200, height: 800)
    .background(Color.axBackground)
}


struct RemoteFleetView: View {
    @ObservedObject var viewModel: ServerListViewModel
    @Binding var selectedServer: Server?
    @Binding var showAddServer: Bool
    @Binding var showServerDashboard: Bool
    
    @State private var searchText = ""
    @State private var selectedFilter: ServerEnvironment? = nil
    @State private var viewMode: ServerViewMode = .grid
    @State private var sortOption: ServerSortOption = .nameAsc
    @State private var serverToEdit: ServerViewModel?
    @State private var showEditServer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AXSpacing.lg) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        HStack(spacing: AXSpacing.md) {
                            Text("Remote Fleet")
                                .font(AXTypography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.axTextPrimary)

                            // Server count badge
                            if !viewModel.isLoading {
                                Text("\(viewModel.decryptedServers.count)")
                                    .font(AXTypography.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axAccentBlue)
                                    .padding(.horizontal, AXSpacing.sm)
                                    .padding(.vertical, AXSpacing.xxs)
                                    .background(Color.axAccentBlue.opacity(0.15))
                                    .cornerRadius(AXCornerRadius.full)
                            }
                        }

                        if !viewModel.isLoading {
                            HStack(spacing: AXSpacing.sm) {
                                HStack(spacing: AXSpacing.xs) {
                                    Circle()
                                        .fill(Color.axSuccess)
                                        .frame(width: 6, height: 6)
                                    Text("\(viewModel.decryptedServers.filter { isServerOnline($0) }.count) Online")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                }

                                Text("•")
                                    .foregroundColor(.axTextMuted)

                                HStack(spacing: AXSpacing.xs) {
                                    Circle()
                                        .fill(Color.axTextMuted)
                                        .frame(width: 6, height: 6)
                                    Text("\(viewModel.decryptedServers.count - viewModel.decryptedServers.filter { isServerOnline($0) }.count) Offline")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Add Server Button
                    Button(action: {
                        showAddServer = true
                    }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Add Server")
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(
                            LinearGradient(
                                colors: viewModel.canAddServer
                                    ? [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)]
                                    : [Color.axTextMuted, Color.axTextMuted.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .shadow(color: viewModel.canAddServer ? Color.axAccentBlue.opacity(0.3) : .clear, radius: 8, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!viewModel.canAddServer)
                }
                
                // Search, Filter, Sort, and View Mode Bar
                VStack(spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.md) {
                        // Search with enhanced styling
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.axTextMuted)

                            TextField("Search by name, host, or tags...", text: $searchText)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .textFieldStyle(PlainTextFieldStyle())

                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.axTextMuted)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(searchText.isEmpty ? Color.axBorder : Color.axAccentBlue.opacity(0.5), lineWidth: searchText.isEmpty ? 1 : 1.5)
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .frame(minWidth: 280)

                        Spacer()

                        // Sort Menu with better styling
                        Menu {
                            ForEach([ServerSortOption.nameAsc, .nameDesc, .dateAdded, .status], id: \.self) { option in
                                Button(action: { sortOption = option }) {
                                    HStack {
                                        Image(systemName: option.icon)
                                        Text(option.label)
                                        Spacer()
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.axAccentBlue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: sortOption.icon)
                                    .font(.system(size: 12))
                                Text(sortOption.label)
                                    .font(AXTypography.caption)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.md)
                        }

                        // View Mode Toggle with improved design
                        HStack(spacing: 2) {
                            Button(action: { viewMode = .grid }) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 13))
                                    .foregroundColor(viewMode == .grid ? .white : .axTextSecondary)
                                    .frame(width: 34, height: 34)
                                    .background(viewMode == .grid ? Color.axAccentBlue : Color.clear)
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { viewMode = .list }) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 13))
                                    .foregroundColor(viewMode == .list ? .white : .axTextSecondary)
                                    .frame(width: 34, height: 34)
                                    .background(viewMode == .list ? Color.axAccentBlue : Color.clear)
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(2)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)

                        // Refresh Button with animation
                        Button(action: {
                            Task {
                                await viewModel.refresh()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(viewModel.isLoading ? .axAccentBlue : .axTextSecondary)
                                .frame(width: 38, height: 38)
                                .background(Color.axSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                                .cornerRadius(AXCornerRadius.md)
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isLoading)
                    }

                    // Environment Filter Pills
                    HStack(spacing: AXSpacing.sm) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextMuted)
                            Text("Environment:")
                                .font(AXTypography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.axTextMuted)
                        }

                        FilterPill(
                            title: "All",
                            isSelected: selectedFilter == nil,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = nil
                                }
                            }
                        )

                        FilterPill(
                            title: "Production",
                            isSelected: selectedFilter == .production,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = .production
                                }
                            }
                        )

                        FilterPill(
                            title: "Staging",
                            isSelected: selectedFilter == .staging,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = .staging
                                }
                            }
                        )

                        FilterPill(
                            title: "Development",
                            isSelected: selectedFilter == .development,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = .development
                                }
                            }
                        )

                        if selectedFilter != nil || !searchText.isEmpty {
                            Divider()
                                .frame(height: 16)
                                .background(Color.axBorder)

                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.axAccentBlue)
                                Text("\(filteredServers.count) of \(viewModel.decryptedServers.count)")
                                    .font(AXTypography.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.axTextPrimary)
                            }
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xxs)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.full)
                        }

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.vertical, AXSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.axBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            )
            
            Divider()
                .background(Color.axBorder)
            
            // Server Content
            if viewModel.isLoading && viewModel.decryptedServers.isEmpty {
                LoadingServersView()
            } else if viewModel.decryptedServers.isEmpty {
                RemoteFleetEmptyStateView(showAddServer: $showAddServer)
            } else if filteredServers.isEmpty {
                // No results after filtering
                VStack(spacing: AXSpacing.xl) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.axTextMuted)

                    VStack(spacing: AXSpacing.sm) {
                        Text("No Servers Found")
                            .font(AXTypography.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)

                        if selectedFilter != nil {
                            Text("No servers match the '\(selectedFilter!.rawValue)' environment filter")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                                .multilineTextAlignment(.center)
                        } else if !searchText.isEmpty {
                            Text("No servers match '\(searchText)'")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }

                        Text("Try adjusting your filters or search criteria")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }

                    HStack(spacing: AXSpacing.md) {
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                HStack(spacing: AXSpacing.xs) {
                                    Image(systemName: "xmark.circle")
                                    Text("Clear Search")
                                }
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextPrimary)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.sm)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if selectedFilter != nil {
                            Button(action: { selectedFilter = nil }) {
                                HStack(spacing: AXSpacing.xs) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text("Clear Filter")
                                }
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextPrimary)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.sm)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.axBackground)
            } else {
                ScrollView {
                    if viewMode == .grid {
                        RemoteFleetGridView(
                            servers: filteredServers,
                            selectedServer: $selectedServer,
                            showServerDashboard: $showServerDashboard,
                            viewModel: viewModel,
                            onConnect: { server in
                                print("[RemoteFleet] Connect requested for server: \(server.name)")
                                
                                // Create full Server model with the SAME ID used for connection
                                let serverUUID = UUID(uuidString: server.id) ?? UUID()
                                let fullServer = Server(
                                    id: serverUUID,
                                    name: server.name,
                                    host: server.host,
                                    port: server.port,
                                    username: server.username,
                                    status: server.isAccessible ? .online : .offline,
                                    type: .remote,
                                    tags: server.tags,
                                    lastConnected: nil,
                                    os: server.osType,
                                    location: server.location,
                                    cpuUsage: nil,
                                    memoryUsage: nil,
                                    diskUsage: nil,
                                    uptime: nil
                                )
                                
                                // Store the server and open dashboard immediately
                                // Connection will happen in ServerDashboardView
                                selectedServer = fullServer
                                showServerDashboard = true
                                
                                print("[RemoteFleet] Opening dashboard for: \(server.name)")
                            },
                            onEdit: { server in
                                serverToEdit = server
                                showEditServer = true
                            },
                            onDelete: { server in
                                Task {
                                    await viewModel.deleteServer(id: server.id)
                                }
                            }
                        )
                    } else {
                        RemoteFleetListView(
                            servers: filteredServers,
                            selectedServer: $selectedServer,
                            showServerDashboard: $showServerDashboard,
                            viewModel: viewModel,
                            onConnect: { server in
                                print("[RemoteFleet] Connect requested for server (List): \(server.name)")

                                // Create full Server model with the SAME ID used for connection
                                let serverUUID = UUID(uuidString: server.id) ?? UUID()
                                let fullServer = Server(
                                    id: serverUUID,
                                    name: server.name,
                                    host: server.host,
                                    port: server.port,
                                    username: server.username,
                                    status: server.isAccessible ? .online : .offline,
                                    type: .remote,
                                    tags: server.tags,
                                    lastConnected: nil,
                                    os: server.osType,
                                    location: server.location,
                                    cpuUsage: nil,
                                    memoryUsage: nil,
                                    diskUsage: nil,
                                    uptime: nil
                                )

                                // Store the server and open dashboard immediately
                                // Connection will happen in ServerDashboardView
                                selectedServer = fullServer
                                showServerDashboard = true

                                print("[RemoteFleet] Opening dashboard for: \(server.name) (List)")
                            },
                            onEdit: { server in
                                serverToEdit = server
                                showEditServer = true
                            },
                            onDelete: { server in
                                Task {
                                    await viewModel.deleteServer(id: server.id)
                                }
                            }
                        )
                    }
                }
                .background(Color.axBackground)
            }
        }
        .background(Color.axBackground)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            // Initialize in background with proper actor isolation
            await viewModel.initialize()
        }
        .sheet(item: $serverToEdit) { server in
            EditServerView(server: server) { updatedRequest in
                Task {
                    // Delete old server and add updated one
                    await viewModel.deleteServer(id: server.id)
                    await viewModel.addServer(updatedRequest)
                    serverToEdit = nil
                }
            }
            .frame(minWidth: 600, minHeight: 700)
        }
        // Decryption error dialog
        .sheet(isPresented: $viewModel.showDecryptionError) {
            DecryptionErrorView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        // Note: Connection popup removed - connection now happens in ServerDashboardView
    }
    
    private var filteredServers: [ServerViewModel] {
        let filtered = viewModel.decryptedServers.filter { server in
            let matchesSearch = searchText.isEmpty ||
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.host.localizedCaseInsensitiveContains(searchText) ||
                server.username.localizedCaseInsensitiveContains(searchText) ||
                server.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })

            // Environment filter: flexible matching
            let matchesFilter: Bool
            if let filter = selectedFilter {
                // Check if any tag contains the filter keyword (case insensitive)
                // Also check common variations and keywords
                let filterKeyword = filter.rawValue.lowercased()
                matchesFilter = server.tags.contains(where: { tag in
                    let tagLower = tag.lowercased().trimmingCharacters(in: .whitespaces)

                    // Direct match
                    if tagLower.contains(filterKeyword) {
                        return true
                    }

                    // Check for common variations and synonyms
                    switch filter {
                    case .production:
                        return tagLower.contains("prod") || tagLower.contains("live") ||
                               tagLower == "prd" || tagLower == "main"
                    case .staging:
                        return tagLower.contains("stage") || tagLower.contains("stg") ||
                               tagLower == "uat" || tagLower == "pre-prod" || tagLower == "preprod"
                    case .development:
                        return tagLower.contains("dev") || tagLower.contains("test") ||
                               tagLower == "local" || tagLower == "sandbox"
                    }
                })
            } else {
                matchesFilter = true
            }

            return matchesSearch && matchesFilter
        }

        return filtered.sorted { s1, s2 in
            switch sortOption {
            case .nameAsc:
                return s1.name < s2.name
            case .nameDesc:
                return s1.name > s2.name
            case .dateAdded:
                return s1.createdAt > s2.createdAt
            case .status:
                // Online servers first
                if s1.isAccessible != s2.isAccessible {
                    return s1.isAccessible && !s2.isAccessible
                }
                return s1.name < s2.name
            }
        }
    }
    
    private func isServerOnline(_ server: ServerViewModel) -> Bool {
        return server.isAccessible
    }
}

// MARK: - Loading View
struct LoadingServersView: View {
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading servers...")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - Empty State View
struct RemoteFleetEmptyStateView: View {
    @Binding var showAddServer: Bool
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            Text("No Servers Yet")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)
            
            Text("Add your first server to get started")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
            
            Button(action: {
                showAddServer = true
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Server")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - Grid View
struct RemoteFleetGridView: View {
    let servers: [ServerViewModel]
    @Binding var selectedServer: Server?
    @Binding var showServerDashboard: Bool
    @ObservedObject var viewModel: ServerListViewModel
    let onConnect: (ServerViewModel) -> Void
    let onEdit: (ServerViewModel) -> Void
    let onDelete: (ServerViewModel) -> Void

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AXSpacing.lg),
            GridItem(.flexible(), spacing: AXSpacing.lg),
            GridItem(.flexible(), spacing: AXSpacing.lg)
        ], spacing: AXSpacing.lg) {
            ForEach(servers) { server in
                RemoteServerCard(
                    server: server,
                    connectionProgress: viewModel.connectionProgress[server.id],
                    onTap: {
                        print("[RemoteFleetGridView] Card tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onConnect: {
                        print("[RemoteFleetGridView] Connect tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onEdit: { onEdit(server) },
                    onDelete: { onDelete(server) }
                )
            }
        }
        .padding(AXSpacing.xxl)
    }
    
    private func navigateToServer(_ server: ServerViewModel) async {
        print("[RemoteFleet] navigateToServer called for: \(server.name)")
        
        // Create full Server model from decrypted info
        let fullServer = Server(
            name: server.name,
            host: server.host,
            port: server.port,
            username: server.username,
            status: server.isAccessible ? .online : .offline,
            type: .remote,
            tags: server.tags,
            lastConnected: nil,
            os: server.osType,
            location: server.location,
            cpuUsage: nil,
            memoryUsage: nil,
            diskUsage: nil,
            uptime: nil
        )
        
        print("[RemoteFleet] Created Server model: id=\(fullServer.id), name=\(fullServer.name)")
        
        await MainActor.run {
            print("[RemoteFleet] Setting selectedServer and showServerDashboard=true")
            selectedServer = fullServer
            showServerDashboard = true
            print("[RemoteFleet] showServerDashboard is now: \(showServerDashboard)")
        }
    }
}

// MARK: - List View
struct RemoteFleetListView: View {
    let servers: [ServerViewModel]
    @Binding var selectedServer: Server?
    @Binding var showServerDashboard: Bool
    @ObservedObject var viewModel: ServerListViewModel
    let onConnect: (ServerViewModel) -> Void
    let onEdit: (ServerViewModel) -> Void
    let onDelete: (ServerViewModel) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(servers.enumerated()), id: \.element.id) { index, server in
                RemoteServerRow(
                    server: server,
                    connectionProgress: viewModel.connectionProgress[server.id],
                    onTap: {
                        print("[RemoteFleetListView] Row tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onConnect: {
                        print("[RemoteFleetListView] Connect tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onEdit: {
                        onEdit(server)
                    },
                    onDelete: {
                        onDelete(server)
                    }
                )

                if index < servers.count - 1 {
                    Divider()
                        .background(Color.axBorder.opacity(0.5))
                        .padding(.horizontal, AXSpacing.xxl)
                }
            }
        }
        .padding(.vertical, AXSpacing.lg)
    }
    
    private func navigateToServer(_ server: ServerViewModel) async {
        let fullServer = Server(
            name: server.name,
            host: server.host,
            port: server.port,
            username: server.username,
            status: server.isAccessible ? .online : .offline,
            type: .remote,
            tags: server.tags,
            lastConnected: nil,
            os: server.osType,
            location: server.location,
            cpuUsage: nil,
            memoryUsage: nil,
            diskUsage: nil,
            uptime: nil
        )
        
        await MainActor.run {
            selectedServer = fullServer
            showServerDashboard = true
        }
    }
}

// MARK: - Server Card (Grid View)
struct RemoteServerCard: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showContextMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Header Row
                HStack(spacing: AXSpacing.md) {
                    // Server Icon with enhanced glow
                    ZStack {
                        // Animated glow for online servers
                        if server.isAccessible {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.axSuccess.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                        }

                        // Icon background with gradient
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [customColor.opacity(0.25), customColor.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                    .stroke(customColor.opacity(0.3), lineWidth: 1)
                            )

                        Image(systemName: server.iconName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(customColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(AXTypography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)

                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "network")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextTertiary)
                            Text(server.host)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Status Badge with enhanced design
                    VStack(spacing: 4) {
                        Circle()
                            .fill(server.isAccessible ? Color.axSuccess : Color.axTextMuted)
                            .frame(width: 8, height: 8)
                            .shadow(color: server.isAccessible ? Color.axSuccess.opacity(0.5) : .clear, radius: 4)

                        Text(server.isAccessible ? "Online" : "Offline")
                            .font(AXTypography.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(server.isAccessible ? .axSuccess : .axTextMuted)
                    }
                }

                // Divider
                Divider()
                    .background(Color.axBorder.opacity(0.5))

                // Server Details Grid
                VStack(spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.md) {
                        // OS Info
                        DetailChip(
                            icon: osIcon,
                            text: server.osType ?? "Linux",
                            color: .axTextSecondary
                        )

                        // User
                        DetailChip(
                            icon: "person.fill",
                            text: server.username,
                            color: .axTextSecondary
                        )

                        Spacer()
                    }

                    // Location and Port
                    HStack(spacing: AXSpacing.md) {
                        if let location = server.location {
                            DetailChip(
                                icon: "mappin.circle.fill",
                                text: location,
                                color: .axAccentBlue
                            )
                        }

                        DetailChip(
                            icon: "point.3.connected.trianglepath.dotted",
                            text: ":\(server.port)",
                            color: .axTextMuted
                        )

                        Spacer()
                    }
                }

                // Tags Row
                if !server.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.xs) {
                            ForEach(server.tags.prefix(3), id: \.self) { tag in
                                TagChip(text: tag, color: customColor)
                            }

                            if server.tags.count > 3 {
                                Text("+\(server.tags.count - 3)")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextMuted)
                                    .padding(.horizontal, AXSpacing.sm)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.lg)
            
            // Action Footer with enhanced styling
            VStack(spacing: 0) {
                Divider()
                    .background(Color.axBorder.opacity(0.5))

                HStack(spacing: AXSpacing.sm) {
                    // Connect Button (Primary) - Full width with hover effect
                    Button(action: {
                        print("[RemoteServerCard] Connect button tapped for: \(server.name)")
                        onConnect()
                    }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                            Text("Connect Now")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: isHovered ? Color.axAccentBlue.opacity(0.4) : .clear, radius: 8, y: 4)
                        )
                    }
                    .buttonStyle(.plain)

                    // Context Menu Button - Compact
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Server", systemImage: "pencil")
                        }

                        Button(action: {
                            // Duplicate action placeholder
                        }) {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Server", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.md)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(Color.axSurface)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .strokeBorder(
                    LinearGradient(
                        colors: isHovered
                            ? [customColor.opacity(0.6), customColor.opacity(0.3)]
                            : [Color.axBorder.opacity(0.5), Color.axBorder.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .shadow(
            color: isHovered ? customColor.opacity(0.25) : Color.black.opacity(0.03),
            radius: isHovered ? 16 : 4,
            y: isHovered ? 8 : 2
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Server", systemImage: "pencil")
            }

            Button(action: {
                // Duplicate placeholder
            }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var customColor: Color {
        if let hex = server.customColor {
            return Color(hex: hex)
        }
        return .axAccentBlue
    }
    
    private var osIcon: String {
        let os = server.osType?.lowercased() ?? ""
        if os.contains("ubuntu") || os.contains("debian") || os.contains("linux") {
            return "terminal"
        } else if os.contains("windows") {
            return "desktopcomputer"
        } else if os.contains("mac") || os.contains("darwin") {
            return "apple.terminal"
        }
        return "server.rack"
    }
    
    private var statusColor: Color {
        server.isAccessible ? .axSuccess : .axTextMuted
    }
    
    private var statusText: String {
        server.isAccessible ? "Online" : "Offline"
    }
}

// MARK: - Server Row (List View)
struct RemoteServerRow: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            // Server Icon
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(customColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: server.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(customColor)
            }

            // Server Info
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(server.name)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)

                HStack(spacing: AXSpacing.sm) {
                    Text("\(server.username)@\(server.host)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)

                    // Status
                    HStack(spacing: AXSpacing.xs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }

                    // Access Level
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: accessLevelIcon)
                            .font(.caption2)
                        Text(accessLevelText)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }

            Spacer()

            // Tags
            if !server.tags.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    ForEach(server.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xxs)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.full)
                    }
                    if server.tags.count > 2 {
                        Text("+\(server.tags.count - 2)")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            // Created Date
            Text(formattedDate(server.createdAt))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 80)

            // Connect Button
            Button(action: {
                print("[RemoteServerRow] Connect button tapped for: \(server.name)")
                onConnect()
            }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("Connect")
                        .font(AXTypography.caption2)
                }
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)

            // Actions Menu
            Menu {
                Button(action: {
                    print("[RemoteServerRow] Menu Connect tapped for: \(server.name)")
                    onConnect()
                }) {
                    Label("Connect", systemImage: "bolt.fill")
                }

                Button(action: onEdit) {
                    Label("Edit Server", systemImage: "pencil")
                }

                Button(action: {
                    // Duplicate action placeholder
                }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete Server", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.md)
        .contentShape(Rectangle())
    }
    
    private var customColor: Color {
        if let hex = server.customColor {
            return Color(hex: hex)
        }
        return .axAccentBlue
    }
    
    private var statusColor: Color {
        server.isAccessible ? .axSuccess : .axTextMuted
    }
    
    private var statusText: String {
        server.isAccessible ? "Online" : "Offline"
    }
    
    private var accessLevelIcon: String {
        switch server.accessLevel {
        case .full: return "lock.open"
        case .readOnly: return "eye"
        case .none: return "lock"
        }
    }
    
    private var accessLevelText: String {
        switch server.accessLevel {
        case .full: return "Full"
        case .readOnly: return "Read"
        case .none: return "None"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Components

/// Detail chip for displaying server metadata
struct DetailChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color.opacity(0.7))
            Text(text)
                .font(AXTypography.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }
}

/// Tag chip for displaying server tags
struct TagChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AXTypography.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.full)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.full)
                            .stroke(color.opacity(0.25), lineWidth: 0.5)
                    )
            )
    }
}
