//
//  AXLaunchStep4Domain.swift
//  AevonX
//
//  Step 4: Domain configuration (new, existing, or skip).
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep4Domain: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                AXLaunchStepHeader(
                    stepIndex: 4, totalSteps: viewModel.totalWizardSteps,
                    title: L10n.AXLaunch.stepDomain
                )
                modeSelector
                domainInput
                webServerSelector
                sslOptions
            }
        }
    }

    // MARK: - Mode

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            domainModeRow(.newDomain, L10n.AXLaunch.addNewDomain, "plus.circle")
            domainModeRow(.existingDomain, L10n.AXLaunch.useExistingDomain, "link")
            domainModeRow(.skip, L10n.AXLaunch.skipDomain, "forward.fill")
        }
    }

    private func domainModeRow(_ mode: AXLaunchWizardViewModel.DomainMode, _ title: String, _ icon: String) -> some View {
        let isSelected = viewModel.domainMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.domainMode = mode }
        } label: {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 20)
                Text(title)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                Spacer()
            }
            .padding(AXSpacing.md)
            .background(isSelected ? Color.axAccentBlue.opacity(0.08) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Domain Input

    @ViewBuilder
    private var domainInput: some View {
        if viewModel.domainMode != .skip {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                TextField("myapp.example.com", text: $viewModel.domainName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Web Server

    @ViewBuilder
    private var webServerSelector: some View {
        if viewModel.domainMode != .skip {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text(L10n.AXLaunch.webServer)
                    .font(AXTypography.subheadline.weight(.medium))
                    .foregroundColor(.axTextPrimary)

                HStack(spacing: AXSpacing.sm) {
                    webServerButton("nginx", "Nginx")
                    webServerButton("apache", "Apache")
                    webServerButton("openlitespeed", "OpenLiteSpeed")
                }
            }
        }
    }

    private func webServerButton(_ value: String, _ label: String) -> some View {
        let isSelected = viewModel.webServer == value
        return Button {
            viewModel.webServer = value
        } label: {
            Text(label)
                .font(AXTypography.caption.weight(.medium))
                .foregroundColor(isSelected ? .axBackground : .axTextPrimary)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(isSelected ? Color.axAccentBlue : Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - SSL

    @ViewBuilder
    private var sslOptions: some View {
        if viewModel.domainMode != .skip {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Toggle(isOn: $viewModel.useSSL) {
                    Text(L10n.AXLaunch.enableSSL)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextPrimary)
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $viewModel.forceHTTPS) {
                    Text(L10n.AXLaunch.forceHTTPS)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextPrimary)
                }
                .toggleStyle(.checkbox)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        }
    }
}
