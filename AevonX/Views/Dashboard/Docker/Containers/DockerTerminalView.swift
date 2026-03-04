//
//  DockerTerminalView.swift
//  AevonX
//
//  Created for Docker Interactive Terminal
//

import SwiftUI
import AevonXCore
import Combine

// MARK: - Docker Terminal View

struct DockerTerminalView: View {
    let containerId: String
    let containerName: String
    let serverId: String
    let workingDir: String?
    @Binding var isPresented: Bool
    
    @StateObject private var viewModel = DockerTerminalViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(.axTextSecondary)
                    Text("Terminal: \(containerName)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    
                    if viewModel.isConnected {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color.axError)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.disconnect()
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.axTextSecondary)
                        .padding(6)
                        .background(Color.axSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.md)
            .background(Color.axBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.axBorder),
                alignment: .bottom
            )
            
            // Terminal Output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.lines) { line in
                            Text(line.content)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(AXSpacing.md)
                }
                .background(Color.black)
                .onChange(of: viewModel.lines.count) { oldValue, newValue in
                    if let lastId = viewModel.lines.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            
            // Input Area
            HStack(spacing: AXSpacing.sm) {
                Text(">")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axSuccess)
                
                TextField("Type command...", text: $viewModel.inputCommand)
                    .font(.system(size: 12, design: .monospaced))
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.sendCommand()
                    }
                    .disabled(!viewModel.isConnected)
            }
            .padding(AXSpacing.sm)
            .background(Color.axSurface)
        }
        .frame(minWidth: 700, maxWidth: 800, minHeight: 500, maxHeight: 600)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.lg)
        .onAppear {
            viewModel.connect(containerId: containerId, serverId: serverId, workingDir: workingDir)
            isInputFocused = true
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}

// MARK: - Terminal Line Model

struct TerminalLine: Identifiable {
    let id = UUID()
    let content: String
}

// MARK: - View Model

@MainActor
class DockerTerminalViewModel: ObservableObject {
    @Published var lines: [TerminalLine] = []
    @Published var inputCommand: String = ""
    @Published var isConnected: Bool = false
    @Published var errorMessage: String?
    
    private var session: SSHInteractiveSession?
    
    func connect(containerId: String, serverId: String, workingDir: String? = nil) {
        let baseExec = "docker exec -it"
        var workdirFlag = ""
        if let workingDir = workingDir, !workingDir.isEmpty {
            workdirFlag = "-w \"\(workingDir)\""
        }
        
        let fullBase = "\(baseExec) \(workdirFlag) \(containerId)".replacingOccurrences(of: "  ", with: " ")
        // Fallback chain for different container environments
        let command = "\(fullBase) /bin/bash || \(fullBase) /bin/sh || \(fullBase) sh"
        
        print("Connecting to terminal: \(command)")
        
        Task {
            do {
                self.lines.append(TerminalLine(content: "Connecting to container \(containerId)..."))
                
                session = try await SSHService.shared.startInteractive(
                    command: command,
                    serverId: serverId,
                    onOutput: { [weak self] output in
                        Task { @MainActor [weak self] in
                            self?.handleOutput(output)
                        }
                    }
                )
                
                self.isConnected = true
                self.lines.append(TerminalLine(content: "Connected."))
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.lines.append(TerminalLine(content: "Error: \(error.localizedDescription)"))
            }
        }
    }
    
    func disconnect() {
        Task {
            try? await session?.close()
            self.isConnected = false
            self.session = nil
        }
    }
    
    func sendCommand() {
        guard !inputCommand.isEmpty, let session = session else { return }
        
        let commandToSend = inputCommand + "\n"
        inputCommand = ""
        
        Task {
            try? await session.write(commandToSend)
        }
    }
    
    private func handleOutput(_ output: String) {
        // ANSI escape code cleaning (strips most common terminal control sequences)
        let cleaned = output
            .replacingOccurrences(of: "\u{1B}\\[\\?[0-9]*[a-zA-Z]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\u{1B}\\[[0-9;]*[a-zA-Z]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\r", with: "")
        
        if cleaned.isEmpty { return }
        
        let newLines = cleaned.split(separator: "\n", omittingEmptySubsequences: false).map { TerminalLine(content: String($0)) }
        self.lines.append(contentsOf: newLines)
        
        // Keep buffer size reasonable
        if self.lines.count > 1000 {
            self.lines.removeFirst(self.lines.count - 1000)
        }
    }
}
