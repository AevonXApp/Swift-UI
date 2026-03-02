//
//  QuickInstallView.swift
//  AevonX
//
//  Full-screen package selection wizard for the Quick Environment Install.
//  Triggered from OverviewTab or auto-shown on fresh servers.
//
//  Layout: 3-column — Category sidebar | Package grid | Selection summary bar
//

import SwiftUI
import AevonXCore

// MARK: - Main View

struct QuickInstallView: View {

    @ObservedObject var viewModel: QuickInstallViewModel
    var onStartInstall: () -> Void
    var onDismiss: () -> Void

    @State private var presetScrollProxy: ScrollViewProxy? = nil
    @Namespace private var presetNS

    var body: some View {
        ZStack {
            // Background blur
            Color.axBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ────────────────────────────────────────────
                quickInstallHeader

                Divider().background(Color.axBorder.opacity(0.4))

                // ── Preset Bar ────────────────────────────────────────
                presetBar
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)

                Divider().background(Color.axBorder.opacity(0.2))

                // ── Main Content ──────────────────────────────────────
                HStack(spacing: 0) {
                    // Left: category sidebar
                    categorySidebar
                        .frame(width: 180)

                    Divider().background(Color.axBorder.opacity(0.3))

                    // Center: package grid
                    packageGrid
                        .frame(maxWidth: .infinity)
                }

                Divider().background(Color.axBorder.opacity(0.4))

                // ── Selection Footer ──────────────────────────────────
                selectionFooter
            }
        }
        .frame(minWidth: 880, minHeight: 600)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 40, x: 0, y: 20)
        .task {
            if viewModel.serverScan == nil && !viewModel.isScanning {
                await viewModel.scanServer()
            }
        }
    }

    // MARK: - Header

    private var quickInstallHeader: some View {
        HStack(spacing: AXSpacing.lg) {

            // Rocket icon
            ZStack {
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Quick Install")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text("Set up your server environment in one step")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            // Server OS badge
            serverBadge

            // Scan indicator
            if viewModel.isScanning {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Scanning...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }

            // Search
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                TextField("Search packages...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextPrimary)
                    .frame(width: 160)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
            )

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }

    @ViewBuilder
    private var serverBadge: some View {
        if let profile = viewModel.serverProfile {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.axSuccess)
                Text("\(profile.distro.displayName) \(profile.distroVersion ?? "") · \(profile.architecture ?? "x86_64")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextSecondary)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSuccess.opacity(0.08))
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axSuccess.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Preset Bar

    private var presetBar: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("QUICK PRESETS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextMuted)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AXSpacing.sm) {
                    ForEach(viewModel.presets) { preset in
                        QIPresetChip(preset: preset) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.applyPreset(preset)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Sidebar

    private var categorySidebar: some View {
        VStack(spacing: 0) {
            // "All" button
            QICategoryRow(
                title: "All",
                icon: "square.grid.2x2",
                count: viewModel.allPackages.count,
                isSelected: viewModel.selectedCategory == nil
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectedCategory = nil
                }
            }

            Divider()
                .background(Color.axBorder.opacity(0.2))
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)

            ForEach(QICategory.allCases, id: \.self) { cat in
                QICategoryRow(
                    title: cat.rawValue,
                    icon: cat.icon,
                    count: viewModel.allPackages.filter { $0.category == cat }.count,
                    isSelected: viewModel.selectedCategory == cat
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedCategory = cat
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.3))
    }

    // MARK: - Package Grid

    private var packageGrid: some View {
        ScrollView {
            if viewModel.filteredPackages.isEmpty {
                VStack(spacing: AXSpacing.lg) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.axTextMuted)
                    Text("No packages match '\(viewModel.searchText)'")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AXSpacing.md),
                        GridItem(.flexible(), spacing: AXSpacing.md),
                        GridItem(.flexible(), spacing: AXSpacing.md),
                    ],
                    spacing: AXSpacing.md
                ) {
                    ForEach(viewModel.filteredPackages) { pkg in
                        QIPackageCard(
                            package: pkg,
                            isSelected: viewModel.isSelected(pkg.id),
                            installedVersion: viewModel.installedVersion(for: pkg.id),
                            selectedVersionId: viewModel.selections.first(where: { $0.packageId == pkg.id })?.versionId,
                            onToggle: {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.togglePackage(pkg)
                                }
                            },
                            onVersionChange: { newVersionId in
                                viewModel.updateVersion(for: pkg.id, to: newVersionId)
                            }
                        )
                    }
                }
                .padding(AXSpacing.lg)
            }
        }
    }

    // MARK: - Selection Footer

    private var selectionFooter: some View {
        HStack(spacing: AXSpacing.lg) {

            // Selected chips
            if viewModel.selections.isEmpty {
                Text("Select packages above to begin")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AXSpacing.sm) {
                        ForEach(viewModel.selections) { sel in
                            QISelectionChip(label: "\(sel.packageName) \(sel.versionId)") {
                                withAnimation(.spring(response: 0.25)) {
                                    viewModel.removeSelection(sel.packageId)
                                }
                            }
                        }
                    }
                }
            }

            Spacer(minLength: AXSpacing.md)

            // Conflict warning
            if viewModel.hasConflicts {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.axWarning)
                    Text(viewModel.conflicts.first?.reason ?? "Conflict detected")
                        .font(.system(size: 11))
                        .foregroundColor(.axWarning)
                        .lineLimit(1)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axWarning.opacity(0.4), lineWidth: 1)
                )
            }

            // ETA
            if !viewModel.selections.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    Text("~\(viewModel.estimatedMinutes) min")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                }
            }

            // Install button
            Button(action: onStartInstall) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Install \(viewModel.selections.isEmpty ? "" : "(\(viewModel.selections.count))")")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    Group {
                        if viewModel.selections.isEmpty || viewModel.hasConflicts {
                            Color.axTextMuted
                        } else {
                            LinearGradient(
                                colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.selections.isEmpty || viewModel.hasConflicts)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axBackground)
    }
}

// MARK: - Preset Chip

private struct QIPresetChip: View {
    let preset: QIPreset
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: preset.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colorFromHex(preset.accentHex))

                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Text(preset.packageVersionPairs.map { $0.packageId.capitalized }.joined(separator: " · "))
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(isHovered ? colorFromHex(preset.accentHex).opacity(0.1) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(colorFromHex(preset.accentHex).opacity(isHovered ? 0.5 : 0.25), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Category Row

private struct QICategoryRow: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(4)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                isSelected
                    ? Color.axAccentBlue.opacity(0.1)
                    : Color.clear
            )
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                isSelected ? RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, AXSpacing.sm)
    }
}

// MARK: - Package Card

private struct QIPackageCard: View {
    let package: QIPackage
    let isSelected: Bool
    let installedVersion: String?
    let selectedVersionId: String?
    let onToggle: () -> Void
    let onVersionChange: (String) -> Void

    @State private var isHovered = false
    @State private var showVersionPicker = false

    private var accentColor: Color { colorFromHex(package.accentHex) }

    var body: some View {
        VStack(spacing: 0) {
            // Top: icon + name + toggle
            HStack(spacing: AXSpacing.sm) {
                // Package icon circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 38, height: 38)
                    Image(systemName: package.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(package.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)

                    Text(package.tagline)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }

                Spacer()

                // Installed badge OR selection toggle
                if let installed = installedVersion {
                    VStack(spacing: 1) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axSuccess)
                        Text("v\(installed)")
                            .font(.system(size: 9))
                            .foregroundColor(.axSuccess)
                    }
                } else {
                    // Toggle button
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? accentColor : Color.axBackgroundTertiary)
                            .frame(width: 22, height: 22)
                        Image(systemName: isSelected ? "checkmark" : "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? .white : .axTextMuted)
                    }
                    .onTapGesture(perform: onToggle)
                }
            }
            .padding(AXSpacing.md)

            // Bottom: version picker (only when selected)
            if isSelected && installedVersion == nil {
                Divider()
                    .background(accentColor.opacity(0.2))

                HStack {
                    Text("Version")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)

                    Spacer()

                    Menu {
                        ForEach(package.versions) { ver in
                            Button(action: { onVersionChange(ver.id) }) {
                                HStack {
                                    Text(ver.label)
                                    if ver.isRecommended {
                                        Image(systemName: "star.fill")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            let currentLabel = package.versions.first(where: { $0.id == selectedVersionId })?.label
                                ?? package.versions.first?.label ?? "Select"
                            Text(currentLabel)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(accentColor)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isSelected ? accentColor.opacity(0.06) : (isHovered ? Color.axSurface : Color.axBackgroundTertiary))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(
                    isSelected ? accentColor.opacity(0.5) : (isHovered ? Color.axBorder : Color.axBorder.opacity(0.4)),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.spring(response: 0.3), value: isSelected)
        .onHover { isHovered = $0 }
        .onTapGesture {
            if installedVersion == nil {
                onToggle()
            }
        }
    }
}

// MARK: - Selection Chip

private struct QISelectionChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.axAccentBlue)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 4)
        .background(Color.axAccentBlue.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Color Helper

private func colorFromHex(_ hex: String) -> Color {
    var h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
    guard h.count == 6, let val = UInt64(h, radix: 16) else { return .axAccentBlue }
    let r = Double((val >> 16) & 0xFF) / 255
    let g = Double((val >> 8) & 0xFF) / 255
    let b = Double(val & 0xFF) / 255
    return Color(red: r, green: g, blue: b)
}
