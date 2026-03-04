//
//  HostKeyChangeAlertView.swift
//  AevonX
//
//  Alert view for SSH host key changes (potential MITM attack)
//

import SwiftUI
import AevonXCore

struct HostKeyChangeAlertView: View {
    let serverName: String
    let expectedFingerprint: String
    let actualFingerprint: String
    
    var onAccept: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
                .symbolEffect(.pulse)
            
            // Title
            Text("Security Alert")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Host Key Changed")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
            
            // Description
            Text("The server's identity has changed since your last connection. This could indicate a man-in-the-middle attack, or the server may have been reinstalled.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            // Server info
            VStack(alignment: .leading, spacing: 12) {
                Text("Server: \(serverName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expected Fingerprint:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expectedFingerprint)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Actual Fingerprint:")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(actualFingerprint)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Warning
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Only accept if you trust this change")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button {
                    onCancel()
                } label: {
                    Text("Cancel Connection")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Button {
                    onAccept()
                } label: {
                    Text("Accept New Key")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 500)
    }
}

// MARK: - Modal Presentation

struct HostKeyChangeModifier: ViewModifier {
    @Binding var isPresented: Bool
    let serverName: String
    let expectedFingerprint: String
    let actualFingerprint: String
    let onAccept: () -> Void
    let onCancel: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    HostKeyChangeAlertView(
                        serverName: serverName,
                        expectedFingerprint: expectedFingerprint,
                        actualFingerprint: actualFingerprint,
                        onAccept: {
                            isPresented = false
                            onAccept()
                        },
                        onCancel: {
                            isPresented = false
                            onCancel()
                        }
                    )
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: isPresented)
    }
}

extension View {
    func hostKeyChangeAlert(
        isPresented: Binding<Bool>,
        serverName: String,
        expectedFingerprint: String,
        actualFingerprint: String,
        onAccept: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        modifier(HostKeyChangeModifier(
            isPresented: isPresented,
            serverName: serverName,
            expectedFingerprint: expectedFingerprint,
            actualFingerprint: actualFingerprint,
            onAccept: onAccept,
            onCancel: onCancel
        ))
    }
}

// MARK: - Preview

#Preview {
    HostKeyChangeAlertView(
        serverName: "Production Server",
        expectedFingerprint: "SHA256:abc123def456ghi789jkl012mno345pqr678stu901vwx234yz",
        actualFingerprint: "SHA256:xyz987wvu654tsr321qpo876nml543kji210hgf987edc654ba",
        onAccept: {},
        onCancel: {}
    )
}
