//
//  EditServerView.swift
//  AevonX
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

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
    
    // Original credentials loaded from encrypted payload
    @State private var originalPassword: String?
    @State private var originalPrivateKey: String?
    @State private var originalPassphrase: String?
    @State private var hasExistingPassword: Bool = false
    @State private var hasExistingPrivateKey: Bool = false
    @State private var isLoadingCredentials: Bool = true
    
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
                            
                            // Encryption notice for server name
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 10))
                                    .foregroundColor(.axAccentBlue)
                                Text("Server name is not encrypted, to allow easy identification in web purchases.")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextMuted)
                            }
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
                                HStack {
                                    Text("Password")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                    if hasExistingPassword && password.isEmpty {
                                        Text("• current password kept")
                                            .font(AXTypography.caption2)
                                            .foregroundColor(.axAccentGreen)
                                    }
                                }
                                SecureField(hasExistingPassword ? "Leave empty to keep current" : "Enter SSH password", text: $password)
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
                                HStack {
                                    Text("Private Key")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                    if hasExistingPrivateKey && privateKey.isEmpty {
                                        Text("• current key kept")
                                            .font(AXTypography.caption2)
                                            .foregroundColor(.axAccentGreen)
                                    }
                                }
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
                                password: password.isEmpty ? originalPassword : password,
                                privateKey: privateKey.isEmpty ? originalPrivateKey : privateKey,
                                keyPassphrase: keyPassphrase.isEmpty ? originalPassphrase : keyPassphrase,
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
            
            // Load existing credentials from encrypted payload via Go HTTP
            Task {
                do {
                    let token = await AuthService.shared.getToken() ?? ""
                    let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
                    let resultJSON = await APIBridge.shared.fetchServerAsync(baseURL: baseURL, token: token, serverID: server.id)
                    
                    guard let rawData = resultJSON.data(using: .utf8),
                          let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
                          result["success"] as? Bool == true,
                          let responseData = result["data"] as? [String: Any],
                          let encryptedPayload = responseData["encrypted_payload"] as? String,
                          let nonce = responseData["payload_nonce"] as? String,
                          let authTag = responseData["payload_auth_tag"] as? String,
                          let metadataDict = responseData["encryption_metadata"] as? [String: Any],
                          let metadataJSON = try? JSONSerialization.data(withJSONObject: metadataDict),
                          let metadata = try? JSONDecoder().decode(EncryptionMetadata.self, from: metadataJSON) else {
                        await MainActor.run { isLoadingCredentials = false }
                        return
                    }
                    
                    let payload = EncryptedServerPayload(
                        encryptedData: encryptedPayload,
                        nonce: nonce,
                        authTag: authTag,
                        metadata: metadata
                    )
                    let serverData = try await ServerEncryptionService.shared.decryptServer(
                        EncryptedServerData.self,
                        from: payload
                    )
                    
                    await MainActor.run {
                        originalPassword = serverData.authentication.password
                        originalPrivateKey = serverData.authentication.privateKey
                        originalPassphrase = serverData.authentication.keyPassphrase
                        authType = serverData.authentication.authType
                        hasExistingPassword = !(serverData.authentication.password ?? "").isEmpty
                        hasExistingPrivateKey = !(serverData.authentication.privateKey ?? "").isEmpty
                        isLoadingCredentials = false
                    }
                } catch {
                    await MainActor.run {
                        isLoadingCredentials = false
                    }
                }
            }
        }
    }
}
