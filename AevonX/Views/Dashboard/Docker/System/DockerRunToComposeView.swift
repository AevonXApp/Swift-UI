
import SwiftUI
import AevonXCore

struct DockerRunToComposeView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var runCommand = ""
    @State private var composeOutput = ""
    @State private var isCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Run → Compose Converter", systemImage: "arrow.right.arrow.left")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
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
            
            VStack(spacing: AXSpacing.md) {
                // Input
                VStack(alignment: .leading, spacing: 6) {
                    Label("docker run command", systemImage: "terminal")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    TextEditor(text: $runCommand)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 80)
                        .padding(AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    
                    Text("Paste your docker run command here")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                
                Button {
                    convert()
                } label: {
                    Label("Convert", systemImage: "arrow.right.arrow.left")
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding()
                .background(runCommand.isEmpty ? Color.axSurface : Color.axAccentBlue)
                .foregroundColor(runCommand.isEmpty ? .axTextMuted : .white)
                .cornerRadius(AXCornerRadius.md)
                .disabled(runCommand.isEmpty)
                
                // Output
                if !composeOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("docker-compose.yml", systemImage: "doc.text")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            Spacer()
                            
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(composeOutput, forType: .string)
                                isCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                            } label: {
                                Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(AXTypography.caption)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isCopied ? Color.axSuccess.opacity(0.15) : Color.axSurface)
                            .foregroundColor(isCopied ? .axSuccess : .axTextSecondary)
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        
                        ScrollView {
                            Text(composeOutput)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(AXSpacing.sm)
                        .frame(minHeight: 150)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axSuccess.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 550, minHeight: 500)
        .background(Color.axBackground)
    }
    
    private func convert() {
        composeOutput = DockerManager.shared.convertRunToCompose(runCommand: runCommand)
    }
}
