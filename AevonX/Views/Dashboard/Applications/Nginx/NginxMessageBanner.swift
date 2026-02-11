
import SwiftUI

public struct NginxMessageBanner: View {
    let message: String
    let type: MessageType
    let onDismiss: () -> Void

    public enum MessageType {
        case success
        case error
    }

    public init(message: String, type: MessageType, onDismiss: @escaping () -> Void) {
        self.message = message
        self.type = type
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack {
            Image(systemName: type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(type == .success ? .axSuccess : .axError)

            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.md)
        .background(type == .success ? Color.axSuccess.opacity(0.1) : Color.axError.opacity(0.1))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(type == .success ? Color.axSuccess.opacity(0.3) : Color.axError.opacity(0.3), lineWidth: 1)
        )
    }
}
