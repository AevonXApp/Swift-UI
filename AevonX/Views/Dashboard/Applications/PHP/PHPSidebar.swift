
import SwiftUI
import AevonXCore

struct PHPSidebar: View {
    let application: ApplicationInstance
    @Binding var selectedSection: PHPSection
    let onBack: () -> Void
    let onControl: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                        Text("Applications")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(.plain)

                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.blue.opacity(0.15))
                        
                        Image("php-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(application.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.axTextPrimary)
                        
                        if let version = application.version {
                            Text(version)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.axTextMuted)
                                .monospaced()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)

            Divider()
                .padding(.horizontal, AXSpacing.md)

            // Navigation
            ScrollView {
                VStack(spacing: AXSpacing.xs) {
                    ForEach(PHPSection.allCases) { section in
                        NavigationRow(
                            section: section,
                            isSelected: selectedSection == section,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedSection = section
                                }
                            }
                        )
                    }
                }
                .padding(AXSpacing.md)
            }

            Spacer()

            // Service Controls at Bottom
            VStack(spacing: AXSpacing.md) {
                Divider()
                
                HStack(spacing: AXSpacing.sm) {
                    Circle()
                        .fill(application.isRunning ? Color.axSuccess : Color.axError)
                        .frame(width: 6, height: 6)
                    
                    Text(application.isRunning ? "Running" : "Stopped")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.sm)

                HStack(spacing: AXSpacing.sm) {
                    ControlBtn(icon: "play.fill", color: .axSuccess, isEnabled: !application.isRunning) {
                        onControl("start")
                    }
                    
                    ControlBtn(icon: "stop.fill", color: .axError, isEnabled: application.isRunning) {
                        onControl("stop")
                    }
                    
                    ControlBtn(icon: "arrow.clockwise", color: .axAccentBlue, isEnabled: true) {
                        onControl("restart")
                    }
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface.opacity(0.3))
        }
    }
}

private struct NavigationRow: View {
    let section: PHPSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                    .frame(width: 20)
                
                Text(section.rawValue)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color.axAccentBlue)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ControlBtn: View {
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isEnabled ? color : .axTextMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isEnabled ? color.opacity(0.1) : Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(isEnabled ? color.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
