
import SwiftUI
import AevonXCoreBridge

struct PHPMessageBanner: View {
    let message: String
    let type: BannerType
    let onDismiss: () -> Void
    
    enum BannerType {
        case success, error
        
        var color: Color {
            switch self {
            case .success: return .axSuccess
            case .error: return .axError
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.md)
        .background(type.color.opacity(0.1))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.md)
    }
}
