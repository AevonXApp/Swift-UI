//
//  DockerTerminalView.swift
//  AevonX
//
//  Created for Docker Interactive Terminal
//

import SwiftUI
import Combine
import AevonXCoreBridge

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

    private var containerId: String = ""
    private var serverId: String = ""

    func connect(containerId: String, serverId: String, workingDir: String? = nil) {
        self.containerId = containerId
        self.serverId = serverId

        self.lines.append(TerminalLine(content: "Connected to container \(containerId.prefix(12))"))
        self.lines.append(TerminalLine(content: "Type commands below. Each command runs via 'docker exec'."))
        self.isConnected = true
    }

    func disconnect() {
        self.isConnected = false
    }

    func sendCommand() {
        guard !inputCommand.isEmpty else { return }

        let cmd = inputCommand
        inputCommand = ""

        self.lines.append(TerminalLine(content: "> \(cmd)"))

        Task {
            do {
                let output = try await DockerService.shared.execInContainer(
                    id: containerId, command: cmd, serverId: serverId
                )
                let outputLines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                for line in outputLines {
                    self.lines.append(TerminalLine(content: line))
                }
                if outputLines.isEmpty {
                    self.lines.append(TerminalLine(content: "(no output)"))
                }
            } catch {
                self.lines.append(TerminalLine(content: "Error: \(error.localizedDescription)"))
            }

            // Keep buffer size reasonable
            if self.lines.count > 1000 {
                self.lines.removeFirst(self.lines.count - 1000)
            }
        }
    }
}
