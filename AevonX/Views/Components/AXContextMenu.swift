//
//  AXContextMenu.swift
//  AevonX
//
//  Premium popover-based action menu component.
//  Uses .popover() to render outside parent bounds while
//  maintaining a fully custom glassmorphism design.
//

import SwiftUI

// MARK: - Menu Item Model

struct AXMenuItem: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let iconColor: Color
    let isDestructive: Bool
    let action: () -> Void
    
    init(_ label: String, icon: String, color: Color = .axAccentBlue, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.iconColor = color
        self.isDestructive = isDestructive
        self.action = action
    }
}

struct AXMenuSection: Identifiable {
    let id = UUID()
    let title: String?
    let items: [AXMenuItem]
    
    init(_ title: String? = nil, items: [AXMenuItem]) {
        self.title = title
        self.items = items
    }
}

// MARK: - Popover Menu View

struct AXActionMenu: View {
    let sections: [AXMenuSection]
    let triggerIcon: String
    let triggerSize: CGFloat
    
    @State private var isOpen = false
    
    init(
        sections: [AXMenuSection],
        triggerIcon: String = "ellipsis.circle.fill",
        triggerSize: CGFloat = 28
    ) {
        self.sections = sections
        self.triggerIcon = triggerIcon
        self.triggerSize = triggerSize
    }
    
    var body: some View {
        Button(action: {
            isOpen.toggle()
        }) {
            Image(systemName: triggerIcon)
                .font(.system(size: triggerSize * 0.55, weight: .semibold))
                .foregroundColor(isOpen ? .axAccentBlue : .axTextSecondary)
                .frame(width: triggerSize, height: triggerSize)
                .background(isOpen ? Color.axAccentBlue.opacity(0.12) : Color.clear)
                .cornerRadius(triggerSize * 0.28)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            AXMenuContent(sections: sections, isPresented: $isOpen)
        }
    }
}

// MARK: - Menu Content (rendered inside popover)

private struct AXMenuContent: View {
    let sections: [AXMenuSection]
    @Binding var isPresented: Bool
    @State private var hoveredId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                if index > 0 {
                    Rectangle()
                        .fill(Color.axBorder.opacity(0.4))
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                
                // Section header
                if let title = section.title {
                    Text(title.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.axTextMuted.opacity(0.6))
                        .tracking(1.2)
                        .padding(.horizontal, 16)
                        .padding(.top, index == 0 ? 6 : 2)
                        .padding(.bottom, 4)
                }
                
                // Items
                ForEach(section.items) { item in
                    AXMenuItemRow(
                        item: item,
                        isHovered: hoveredId == item.id,
                        onHover: { hovering in
                            withAnimation(.easeInOut(duration: 0.1)) {
                                hoveredId = hovering ? item.id : nil
                            }
                        },
                        onTap: {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                item.action()
                            }
                        }
                    )
                }
            }
        }
        .padding(.vertical, 6)
        .frame(width: 200)
        .background(Color.axSurface)
    }
}

// MARK: - Individual Menu Item

private struct AXMenuItemRow: View {
    let item: AXMenuItem
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onTap: () -> Void
    
    var foregroundColor: Color {
        if isHovered {
            return .white
        }
        return item.isDestructive ? .axError : .axTextPrimary
    }
    
    var iconFG: Color {
        if isHovered {
            return .white
        }
        return item.isDestructive ? .axError : item.iconColor
    }
    
    var bgColor: Color {
        if !isHovered { return .clear }
        return item.isDestructive ? .axError : .axAccentBlue
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Icon with subtle background
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? Color.white.opacity(0.15) : iconFG.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(iconFG)
                }
                
                Text(item.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(foregroundColor)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(bgColor)
            )
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
    }
}

// MARK: - Convenience Factory

extension AXActionMenu {
    /// Website row action menu
    static func websiteActions(
        onConfig: @escaping () -> Void,
        onSSL: @escaping () -> Void,
        onClone: @escaping () -> Void,
        onBackup: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> AXActionMenu {
        AXActionMenu(sections: [
            AXMenuSection("Configuration", items: [
                AXMenuItem("Edit Config", icon: "slider.horizontal.3", color: .axAccentBlue, action: onConfig),
                AXMenuItem("SSL Settings", icon: "lock.shield", color: .axSuccess, action: onSSL),
            ]),
            AXMenuSection("Management", items: [
                AXMenuItem("Clone Site", icon: "doc.on.doc", color: .axAccentPurple, action: onClone),
                AXMenuItem("Backup", icon: "archivebox", color: .orange, action: onBackup),
            ]),
            AXMenuSection(items: [
                AXMenuItem("Delete Website", icon: "trash", isDestructive: true, action: onDelete),
            ]),
        ])
    }
    
    /// Docker container row action menu
    static func dockerContainerActions(
        isRunning: Bool,
        hasDomain: Bool,
        onInspect: @escaping () -> Void,
        onAILog: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onLimits: @escaping () -> Void,
        onRestartPolicy: @escaping () -> Void,
        onDiff: @escaping () -> Void,
        onDomain: @escaping () -> Void,
        onRollback: @escaping () -> Void,
        onClone: @escaping () -> Void,
        onBackup: @escaping () -> Void,
        onRemove: (() -> Void)? = nil
    ) -> AXActionMenu {
        var sections: [AXMenuSection] = [
            AXMenuSection("Inspect", items: [
                AXMenuItem("Inspect", icon: "doc.text.magnifyingglass", color: .axAccentBlue, action: onInspect),
                AXMenuItem("AI Log Analyzer", icon: "sparkles", color: .purple, action: onAILog),
            ]),
            AXMenuSection("Configuration", items: [
                AXMenuItem("Rename", icon: "pencil", color: .axAccentBlue, action: onRename),
                AXMenuItem("Resource Limits", icon: "gauge.with.dots.needle.33percent", color: .orange, action: onLimits),
                AXMenuItem("Restart Policy", icon: "arrow.clockwise.circle", color: .cyan, action: onRestartPolicy),
                AXMenuItem("Filesystem Changes", icon: "doc.badge.plus", color: .mint, action: onDiff),
                AXMenuItem(hasDomain ? "Change Domain" : "Connect Domain", icon: "globe", color: .axSuccess, action: onDomain),
            ]),
            AXMenuSection("Management", items: [
                AXMenuItem("Rollback", icon: "arrow.uturn.backward", color: .indigo, action: onRollback),
                AXMenuItem("Clone", icon: "doc.on.doc", color: .axAccentPurple, action: onClone),
                AXMenuItem("Backup", icon: "externaldrive", color: .orange, action: onBackup),
            ]),
        ]
        
        if let onRemove = onRemove {
            sections.append(AXMenuSection(items: [
                AXMenuItem("Remove", icon: "trash", isDestructive: true, action: onRemove),
            ]))
        }
        
        return AXActionMenu(sections: sections, triggerIcon: "ellipsis", triggerSize: 32)
    }
}
