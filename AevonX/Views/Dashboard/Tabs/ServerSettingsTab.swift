//
//  ServerSettingsTab.swift
//  AevonX
//
//  Server-level settings and SSH configuration
//

import SwiftUI

struct ServerSettingsTab: View {
    let server: Server
    @State private var sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7vbqaj..."
    @State private var selectedKeyType = 0
    @State private var autoConnect = true
    @State private var useKeyAuth = true
    @State private var portForwarding = false
    @State private var compression = true
    @State private var keepAlive = 60
    
    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Connection Settings
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Image(systemName: "network")
                                .font(.system(size: 18))
                                .foregroundColor(.axAccentBlue)
                            
                            Text("Connection")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        VStack(spacing: AXSpacing.md) {
                            SettingRow(icon: "link", title: "Host", value: server.host)
                            SettingRow(icon: "number", title: "Port", value: "\(server.port)")
                            SettingRow(icon: "person", title: "Username", value: server.username)
                            
                            HStack {
                                Image(systemName: "power")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 24)
                                
                                Text("Auto-connect")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $autoConnect)
                                    .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                                    .frame(width: 40)
                            }
                        }
                    }
                }
                
                // SSH Authentication
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.axAccentGreen)
                            
                            Text("SSH Authentication")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        VStack(spacing: AXSpacing.md) {
                            HStack {
                                Image(systemName: "key.horizontal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 24)
                                
                                Text("Use Key Authentication")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $useKeyAuth)
                                    .toggleStyle(SwitchToggleStyle(tint: .axAccentGreen))
                                    .frame(width: 40)
                            }
                            
                            if useKeyAuth {
                                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                    Text("SSH Private Key")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                    
                                    TextEditor(text: $sshKey)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .frame(height: 80)
                                        .padding(AXSpacing.sm)
                                        .background(Color.axBackgroundTertiary)
                                        .cornerRadius(AXCornerRadius.md)
                                    
                                    HStack {
                                        Button(action: {}) {
                                            Text("Generate New Key")
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axAccentBlue)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Spacer()
                                        
                                        Button(action: {}) {
                                            Text("Import Key")
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextSecondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Advanced Options
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Image(systemName: "gearshape.2")
                                .font(.system(size: 18))
                                .foregroundColor(.axWarning)
                            
                            Text("Advanced Options")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        VStack(spacing: AXSpacing.md) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 24)
                                
                                Text("Port Forwarding")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $portForwarding)
                                    .toggleStyle(SwitchToggleStyle(tint: .axWarning))
                                    .frame(width: 40)
                            }
                            
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 24)
                                
                                Text("Compression")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $compression)
                                    .toggleStyle(SwitchToggleStyle(tint: .axWarning))
                                    .frame(width: 40)
                            }
                            
                            HStack {
                                Image(systemName: "heart")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 24)
                                
                                Text("Keep Alive")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                HStack(spacing: AXSpacing.xs) {
                                    Text("\(keepAlive)s")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                    
                                    Slider(value: .init(
                                        get: { Double(keepAlive) },
                                        set: { keepAlive = Int($0) }
                                    ), in: 0...300, step: 10)
                                    .frame(width: 100)
                                }
                            }
                        }
                    }
                }
                
                // Danger Zone
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 18))
                                .foregroundColor(.axError)
                            
                            Text("Danger Zone")
                                .font(AXTypography.headline)
                                .foregroundColor(.axError)
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        VStack(spacing: AXSpacing.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                    Text("Remove Server")
                                        .font(AXTypography.body)
                                        .foregroundColor(.axTextPrimary)
                                    
                                    Text("Permanently remove this server from your fleet")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextTertiary)
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Remove")
                                        .font(AXTypography.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.axError)
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.sm)
                                        .background(Color.axError.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .stroke(Color.axError.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(AXCornerRadius.md)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.axTextMuted)
                .frame(width: 24)
            
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            Text(value)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .monospaced()
        }
    }
}

#Preview {
    ServerSettingsTab(server: Server.placeholder(name: "Preview Server"))
        .padding()
        .background(Color.axBackground)
}
