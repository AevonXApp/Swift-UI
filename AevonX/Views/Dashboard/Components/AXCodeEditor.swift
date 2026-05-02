
import SwiftUI

public struct AXCodeEditor: View {
    @Binding var text: String
    var title: String?
    var isSaving: Bool = false
    var onSave: (() -> Void)?
    var originalText: String?

    @State private var lineNumbers: String = "1"
    
    private var hasChanges: Bool {
        guard let original = originalText else { return false }
        return text != original
    }

    public init(text: Binding<String>, title: String? = nil, isSaving: Bool = false, onSave: (() -> Void)? = nil, originalText: String? = nil) {
        self._text = text
        self.title = title
        self.isSaving = isSaving
        self.onSave = onSave
        self.originalText = originalText
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Editor Header
            if title != nil || onSave != nil {
                HStack {
                    if let title = title {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            if hasChanges {
                                Text(L10n.Dashboard.unsavedChanges)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axAccentBlue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if let onSave = onSave {
                        Button(action: onSave) {
                            HStack(spacing: AXSpacing.xs) {
                                if isSaving {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(isSaving ? "Saving..." : "Save Changes")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving || !hasChanges)
                    }
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface.opacity(0.5))
            }

            Divider()
                .background(Color.axBorder.opacity(0.3))

            // Editor Area
            HStack(alignment: .top, spacing: 0) {
                // Line Numbers Gutter
                VStack(alignment: .trailing, spacing: 0) {
                    Text(lineNumbers)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.axTextTertiary.opacity(0.6))
                        .multilineTextAlignment(.trailing)
                        .padding(.top, 8) // Match TextEditor default padding
                        .padding(.horizontal, AXSpacing.sm)
                }
                .frame(width: 40)
                .background(Color.axBackground.opacity(0.5))
                
                Divider()
                    .background(Color.axBorder.opacity(0.3))

                // The Editor
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, AXSpacing.sm)
                        .onChange(of: text) { _, _ in
                            updateLineNumbers()
                        }
                }
                .background(Color.axSurface.opacity(0.2))
            }
        }
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            updateLineNumbers()
        }
    }

    private func updateLineNumbers() {
        let lines = text.reduce(into: 1) { count, char in
            if char == "\n" { count += 1 }
        }
        
        // Cache or limit line numbers for very large files to prevent UI lag/crashes
        if lines > 1500 {
            lineNumbers = "1\n...\n\(lines)"
            return
        }
        
        lineNumbers = (1...max(1, lines)).map { "\($0)" }.joined(separator: "\n")
    }
}
