//
//  ModernAddDatabaseView.swift
//  AevonX
//
//  Premium "Create Database" sheet with glassmorphism,
//  animated engine selector, and step indicators.
//

import SwiftUI
import AevonXCoreBridge

struct ModernAddDatabaseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: AddDatabaseViewModel
    let onCreated: () -> Void

    init(serverId: String?, installationStates: [DatabaseInstallationState], onCreated: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddDatabaseViewModel(
            serverId: serverId,
            installationStates: installationStates
        ))
        self.onCreated = onCreated
    }

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.axBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: AXSpacing.xxl) {
                        engineSelector
                        databaseNameField
                        encodingRow
                        
                        if viewModel.selectedType?.supportsUserManagement == true {
                            userSection
                        }
                    }
                    .padding(.horizontal, AXSpacing.xxl)
                    .padding(.top, AXSpacing.xl)
                    .padding(.bottom, AXSpacing.xxl + 80)
                }

                footerBar
            }

            errorToast
        }
        .frame(width: 560)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { withAnimation(.spring(response: 0.5)) { appear = true } }
    }

    // MARK: - Header

    var headerBar: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentBlue.opacity(0.3), Color.axAccentBlue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)

                Image(systemName: "plus.circle.fill")
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Database.createDatabase)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text(viewModel.selectedType?.displayName ?? L10n.Database.selectEngine)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            stepIndicator

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(AXTypography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.full)
                    .overlay(
                        Circle()
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.lg)
        .background(
            Color.axSurface.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(Color.axBorder.opacity(0.5))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    var stepIndicator: some View {
        HStack(spacing: AXSpacing.xs) {
            stepDot(filled: true)
            stepDot(filled: !viewModel.databaseName.isEmpty)
            stepDot(filled: viewModel.shouldCreateUser && !viewModel.username.isEmpty)
        }
    }

    func stepDot(filled: Bool) -> some View {
        Circle()
            .fill(filled ? Color.axAccentBlue : Color.axBorder)
            .frame(width: 6, height: 6)
            .animation(.easeInOut(duration: 0.3), value: filled)
    }

    // MARK: - Engine Selector

    @ViewBuilder
    var engineSelector: some View {
        if viewModel.installedEngines.isEmpty {
            noEnginesView
        } else {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                sectionLabel(L10n.Database.databaseEngine, icon: "server.rack")

                HStack(spacing: AXSpacing.md) {
                    ForEach(viewModel.installedEngines) { engine in
                        enginePill(engine)
                    }
                }
            }
        }
    }

    func enginePill(_ engine: DatabaseInstallationState) -> some View {
        let isSelected = viewModel.selectedType == engine.type
        let color = engine.type.brandColor

        return Button { withAnimation(.spring(response: 0.3)) { viewModel.selectEngine(engine.type) } } label: {
            VStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(
                            isSelected
                            ? LinearGradient(colors: [color.opacity(0.25), color.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.axSurface, Color.axSurface], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(isSelected ? color.opacity(0.6) : Color.axBorder, lineWidth: isSelected ? 1.5 : 1)
                        )
                        .shadow(color: isSelected ? color.opacity(0.15) : .clear, radius: 8, y: 2)

                    Image(systemName: engine.type.iconName)
                        .font(AXTypography.title3)
                        .foregroundColor(isSelected ? color : .axTextMuted)
                }

                VStack(spacing: 1) {
                    Text(engine.type.displayName)
                        .font(AXTypography.caption2)
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundColor(isSelected ? color : .axTextSecondary)

                    if let v = engine.installedVersion, !v.isEmpty {
                        Text("v\(v)")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    var noEnginesView: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AXTypography.title3)
                .foregroundColor(.axWarning)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Database.noEngines)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Database.installEngineFirst)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axWarning.opacity(0.08))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axWarning.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Database Name

    var databaseNameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            sectionLabel(L10n.Database.databaseNameLabel, icon: "cylinder")

            styledTextField(
                placeholder: "my_database",
                text: $viewModel.databaseName,
                hasError: viewModel.nameError != nil
            )
            .onChange(of: viewModel.databaseName) { _, _ in viewModel.validateDatabaseName() }

            if let err = viewModel.nameError {
                errorHint(err)
            }
        }
    }

    // MARK: - Encoding Row

    var encodingRow: some View {
        HStack(spacing: AXSpacing.lg) {
            styledPicker(
                label: L10n.Database.encoding,
                icon: "textformat",
                selection: $viewModel.selectedCharset,
                options: viewModel.availableCharsets
            )
            .onChange(of: viewModel.selectedCharset) { _, _ in
                let collations = viewModel.availableCollations
                if !collations.contains(viewModel.selectedCollation) {
                    viewModel.selectedCollation = collations.first ?? "default"
                }
            }

            styledPicker(
                label: L10n.Database.collation,
                icon: "arrow.left.arrow.right",
                selection: $viewModel.selectedCollation,
                options: viewModel.availableCollations
            )
        }
    }

    // MARK: - User Section

    var userSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            Toggle(isOn: $viewModel.shouldCreateUser) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "person.badge.plus")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                    Text(L10n.Database.createUser)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                }
            }
            .toggleStyle(.switch)
            .tint(.axAccentBlue)

            if viewModel.shouldCreateUser {
                VStack(spacing: AXSpacing.lg) {
                    // Username
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        sectionLabel(L10n.Field.username, icon: "person")
                        styledTextField(
                            placeholder: "db_user",
                            text: $viewModel.username,
                            hasError: viewModel.usernameError != nil
                        )
                        .onChange(of: viewModel.username) { _, _ in viewModel.validateUsername() }
                        if let err = viewModel.usernameError { errorHint(err) }
                    }

                    // Password
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        sectionLabel(L10n.Field.password, icon: "lock")
                        passwordRow
                        if let err = viewModel.passwordError { errorHint(err) }
                    }

                    // Host + SSL
                    HStack(spacing: AXSpacing.lg) {
                        styledPicker(
                            label: L10n.Database.hostAccess,
                            icon: "network",
                            selection: $viewModel.host,
                            options: viewModel.hostOptions,
                            displayTransform: { $0 == "%" ? L10n.Database.anyHost : $0 }
                        )

                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            sectionLabel(L10n.Database.securityLabel, icon: "lock.shield")
                            Toggle(isOn: $viewModel.forceSSL) {
                                Text(L10n.Database.requireSSL)
                                    .font(AXTypography.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.axTextPrimary)
                            }
                            .toggleStyle(.switch)
                            .tint(.axAccentBlue)
                        }
                    }
                }
                .padding(AXSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(Color.axGlassBackground)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                .fill(.ultraThinMaterial)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [Color.axGlassBorder, Color.axBorder],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35), value: viewModel.shouldCreateUser)
    }

    var passwordRow: some View {
        HStack(spacing: AXSpacing.sm) {
            Group {
                if viewModel.showPassword {
                    TextField(L10n.Field.password, text: $viewModel.password)
                } else {
                    SecureField(L10n.Field.password, text: $viewModel.password)
                }
            }
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.axTextPrimary)
            .onChange(of: viewModel.password) { _, _ in viewModel.validatePassword() }

            Spacer()

            Button { viewModel.showPassword.toggle() } label: {
                Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.axBackground.opacity(0.5))
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)

            Button { viewModel.generatePassword() } label: {
                Image(systemName: "dice")
                    .font(AXTypography.caption)
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 28, height: 28)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm + 2)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(viewModel.passwordError != nil ? Color.axError.opacity(0.8) : Color.axBorder, lineWidth: 1)
        )
    }


    // Footer, error toast, reusable blocks → ModernAddDatabaseView+FormHelpers.swift
}
