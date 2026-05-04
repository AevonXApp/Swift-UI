//
//  AddServerSteps.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

import UniformTypeIdentifiers

// MARK: - Identity Step
struct AddServerIdentityStep: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        GlassCard(icon: "tag.fill", title: L10n.Fleet.serverIdentity, iconColor: .axAccentBlue) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: L10n.Field.serverName,
                    text: $viewModel.name,
                    placeholder: "My Production Server",
                    icon: "text.cursor"
                )

                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                    Text(L10n.Fleet.serverNameHelp)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                .padding(.top, -AXSpacing.sm)

                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "app.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text(L10n.Field.icon)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.sm) {
                            ForEach(ServerIcon.allCases) { icon in
                                Button {
                                    viewModel.selectedIcon = icon
                                } label: {
                                    Image(systemName: icon.rawValue)
                                        .font(.system(size: 18))
                                        .foregroundColor(viewModel.selectedIcon == icon ? .white : .axTextSecondary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .fill(viewModel.selectedIcon == icon ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text(L10n.Field.color)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }

                    HStack(spacing: AXSpacing.sm) {
                        ForEach(ServerColor.allCases) { color in
                            Button {
                                viewModel.selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color.rawValue))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: viewModel.selectedColor == color ? 2 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                                    .overlay {
                                        if viewModel.selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                PremiumTextField(
                    title: "Tags",
                    text: $viewModel.tagsText,
                    placeholder: "production, web, database",
                    icon: "tag",
                    isOptional: true
                )
            }
        }
    }
}

// MARK: - Connection Step
struct AddServerConnectionStep: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        GlassCard(icon: "network", title: L10n.Fleet.connectionDetails, iconColor: .axAccentGreen) {
            VStack(spacing: AXSpacing.lg) {
                PremiumTextField(
                    title: L10n.Field.host,
                    text: $viewModel.host,
                    placeholder: L10n.Field.hostPlaceholder,
                    icon: "globe"
                )

                HStack(spacing: AXSpacing.md) {
                    PremiumTextField(
                        title: L10n.Field.port,
                        text: Binding(
                            get: { String(viewModel.port) },
                            set: { viewModel.port = Int($0) ?? 22 }
                        ),
                        placeholder: "22",
                        icon: "number"
                    )
                    .frame(maxWidth: 100)

                    PremiumTextField(
                        title: L10n.Field.username,
                        text: $viewModel.username,
                        placeholder: L10n.Field.usernamePlaceholder,
                        icon: "person"
                    )
                }
            }
        }
    }
}

// MARK: - Authentication Step
struct AddServerAuthStep: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        GlassCard(icon: "key.fill", title: L10n.Fleet.authentication, iconColor: .orange) {
            VStack(spacing: AXSpacing.lg) {
                AddServerKeyModePicker(selection: $viewModel.keyMode)

                switch viewModel.keyMode {
                case .usePassword:
                    AddServerPasswordSection(viewModel: viewModel)
                case .importKey:
                    AddServerImportKeySection(viewModel: viewModel)
                case .generateNew:
                    AddServerGenerateSection(viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Verify Step
struct AddServerVerifyStep: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        Group {
            switch viewModel.keyMode {
            case .usePassword, .importKey:
                AddServerLegacyVerifyCard(viewModel: viewModel)
            case .generateNew:
                AddServerGenerateInjectCard(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Sub-views: Auth Step Sections

private struct AddServerKeyModePicker: View {
    @Binding var selection: KeyAcquisitionMode

    var body: some View {
        VStack(spacing: AXSpacing.sm) {
            ForEach(KeyAcquisitionMode.allCases) { mode in
                row(for: mode)
            }
        }
    }

    private func row(for mode: KeyAcquisitionMode) -> some View {
        let isSelected = selection == mode
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selection = mode
            }
        } label: {
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.axAccentBlue : Color.axBackgroundTertiary)
                        .frame(width: 36, height: 36)
                    Image(systemName: mode.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .axTextSecondary)
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(mode.title)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text(mode.subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
            }
            .padding(AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.08) : Color.axBackgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AddServerPasswordSection: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        PremiumSecureField(
            title: L10n.Field.password,
            text: $viewModel.password,
            placeholder: "Enter SSH password",
            icon: "lock.fill"
        )
    }
}

private struct AddServerImportKeySection: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                Text(L10n.Field.privateKey)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)

                Spacer()

                Button {
                    viewModel.showSSHKeyFilePicker = true
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 11))
                        Text(viewModel.sshKeyFileName ?? "Import File")
                            .font(AXTypography.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxs)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }

            TextEditor(text: $viewModel.privateKey)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(AXSpacing.md)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .overlay(
                    Group {
                        if viewModel.privateKey.isEmpty {
                            VStack {
                                HStack {
                                    Text(L10n.Fleet.pasteYourPrivateKeyOrImportAFile)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                        .padding(.top, AXSpacing.md)
                                        .padding(.leading, AXSpacing.md + 5)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                    .allowsHitTesting(false)
                )
                .fileImporter(
                    isPresented: $viewModel.showSSHKeyFilePicker,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            viewModel.importSSHKeyFile(from: url)
                        }
                    case .failure(let error):
                        viewModel.errorMessage = "Failed to import key file: \(error.localizedDescription)"
                        viewModel.showError = true
                    }
                }

            PremiumSecureField(
                title: "Key Passphrase",
                text: $viewModel.keyPassphrase,
                placeholder: "Optional passphrase",
                icon: "lock.shield",
                isOptional: true
            )
        }
    }
}

private struct AddServerGenerateSection: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Algorithm picker
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Algorithm")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)

                HStack(spacing: AXSpacing.sm) {
                    ForEach(KeygenType.allCases, id: \.self) { type in
                        algorithmPill(type: type)
                    }
                }
            }

            PremiumTextField(
                title: "Comment",
                text: $viewModel.generateComment,
                placeholder: "user@device",
                icon: "text.bubble"
            )

            PremiumSecureField(
                title: "Key Passphrase",
                text: $viewModel.generatePassphrase,
                placeholder: "Optional — encrypts the private key on disk",
                icon: "lock.shield",
                isOptional: true
            )

            Divider().background(Color.axBorder).padding(.vertical, AXSpacing.xs)

            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundColor(.axAccentBlue)
                Text("Enter your current SSH password — used once to inject the new public key, then wiped.")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }

            PremiumSecureField(
                title: "One-time SSH Password",
                text: $viewModel.injectionPassword,
                placeholder: "Current password on this server",
                icon: "lock.rotation"
            )
        }
    }

    private func algorithmPill(type: KeygenType) -> some View {
        let selected = viewModel.generateKeyType == type
        return Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.generateKeyType = type
            }
        } label: {
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(type.displayName)
                    .font(AXTypography.headline)
                    .foregroundColor(selected ? .white : .axTextPrimary)
                Text(type.subtitle)
                    .font(AXTypography.caption2)
                    .foregroundColor(selected ? .white.opacity(0.85) : .axTextMuted)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(selected ? Color.axAccentBlue : Color.axBackgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(selected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sub-views: Verify Step Cards

private struct AddServerLegacyVerifyCard: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        GlassCard(icon: "wifi", title: "Connection Test", iconColor: .purple) {
            VStack(spacing: AXSpacing.md) {
                Button {
                    Task { await viewModel.testConnection() }
                } label: {
                    HStack(spacing: AXSpacing.sm) {
                        if viewModel.isTesting {
                            ProgressView().scaleEffect(0.8).tint(.white)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(viewModel.isTesting ? "Testing..." : "Test Connection")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.md)
                    .background(
                        Group {
                            if viewModel.canTest {
                                LinearGradient(colors: [.purple, .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            } else {
                                Color.axTextMuted
                            }
                        }
                    )
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isTesting || !viewModel.canTest)

                if let progress = viewModel.connectionProgress {
                    PremiumProgressView(progress: progress)
                }

                if let result = viewModel.testResult {
                    PremiumResultView(result: result)
                }
            }
        }
    }
}

private struct AddServerGenerateInjectCard: View {
    @ObservedObject var viewModel: AddServerViewModel

    var body: some View {
        GlassCard(icon: "key.fill", title: "Generate & Inject", iconColor: .axAccentBlue) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {

                Text("This will generate a new \(viewModel.generateKeyType.displayName) key on this device, inject the public half into the server, and verify a fresh login with the new key. Your one-time password is wiped on completion.")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)

                Button {
                    Task { await viewModel.runGenerateAndInject() }
                } label: {
                    HStack(spacing: AXSpacing.sm) {
                        if viewModel.injectStage.isInFlight {
                            ProgressView().scaleEffect(0.8).tint(.white)
                        } else {
                            Image(systemName: viewModel.injectStage == .success ? "checkmark.circle.fill" : "key.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(buttonTitle)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.md)
                    .background(
                        Group {
                            if viewModel.canTest && !viewModel.injectStage.isInFlight {
                                LinearGradient(colors: [.axAccentBlue, .axAccentGreen], startPoint: .leading, endPoint: .trailing)
                            } else {
                                Color.axTextMuted
                            }
                        }
                    )
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canTest || viewModel.injectStage.isInFlight)

                if viewModel.injectStage != .idle {
                    InjectProgressView(stage: viewModel.injectStage)
                }

                if let fp = viewModel.generatedFingerprint, viewModel.injectStage == .success {
                    GeneratedKeySummary(fingerprint: fp, type: viewModel.generatedKeyTypeAfterInject ?? .ed25519)
                }
            }
        }
    }

    private var buttonTitle: String {
        switch viewModel.injectStage {
        case .idle:    return "Generate & Inject"
        case .success: return "Done — Save Server"
        case .failed:  return "Retry"
        default:       return "Working…"
        }
    }
}

private struct InjectProgressView: View {
    let stage: GenerateInjectStage

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(tint)
                Text(stage.message)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Text("\(Int(stage.progress * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(tint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axBackgroundTertiary)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [tint, tint.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * stage.progress, height: 4)
                        .animation(.easeInOut(duration: 0.4), value: stage.progress)
                }
            }
            .frame(height: 4)
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axBackgroundTertiary.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        )
    }

    private var icon: String {
        switch stage {
        case .success: return "checkmark.seal.fill"
        case .failed:  return "xmark.octagon.fill"
        default:       return "gearshape.2.fill"
        }
    }

    private var tint: Color {
        switch stage {
        case .success: return .axSuccess
        case .failed:  return .axError
        default:       return .axAccentBlue
        }
    }
}

private struct GeneratedKeySummary: View {
    let fingerprint: String
    let type: KeygenType

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.axSuccess)
                Text("Stored in Keychain (Touch ID)")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }

            HStack(spacing: AXSpacing.sm) {
                Text(type.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(
                        Capsule().fill(Color.axAccentPurple.opacity(0.15))
                    )
                    .foregroundColor(.axAccentPurple)
                Text(fingerprint)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSuccess.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axSuccess.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
