
import SwiftUI
import AevonXCore

struct DockerLogsView: View {
    let container: DockerContainer
    let serverId: String
    @Binding var isPresented: Bool
    
    @State private var logs: String = ""
    @State private var isStreaming: Bool = false
    @State private var autoScroll: Bool = true
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Logs: \(container.names)")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text(container.id)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .monospaced()
                }
                
                Spacer()
                
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .font(AXTypography.caption)
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            .overlay(Rectangle().frame(height: 1).foregroundColor(.axBorder), alignment: .bottom)
            
            // Logs Content
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(logs)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .id("Bottom")
                    }
                    .background(Color.black)
                    .onChange(of: logs) { _ in
                        if autoScroll {
                            proxy.scrollTo("Bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .background(Color.axBackground)
        .onAppear {
            startStreaming()
        }
        .onDisappear {
            stopStreaming()
        }
    }
    
    private func startStreaming() {
        isStreaming = true
        logs = "Starting log stream...\n"
        
        task = Task {
            do {
                try await DockerManager.shared.getContainerLogs(
                    id: container.id,
                    tail: 100,
                    follow: true,
                    serverId: serverId
                ) { chunk in
                    Task { @MainActor in
                        logs += chunk
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        logs += "\n[Error] Stream disconnected: \(error.localizedDescription)"
                    }
                }
            }
            isStreaming = false
        }
    }
    
    private func stopStreaming() {
        task?.cancel()
        task = nil
        isStreaming = false
    }
}
