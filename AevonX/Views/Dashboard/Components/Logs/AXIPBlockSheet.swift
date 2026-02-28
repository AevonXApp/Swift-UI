//
//  AXIPBlockSheet.swift
//  AevonX
//
//  Sheet for blocking an IP address with duration and reason.
//

import SwiftUI

struct AXIPBlockSheet: View {
    let ip: String
    let onBlock: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var reason: String = ""
    @State private var selectedDuration: AXBlockDuration = .permanent

    enum AXBlockDuration: String, CaseIterable {
        case oneHour = "1 Hour"
        case oneDay = "1 Day"
        case oneWeek = "1 Week"
        case permanent = "Permanent"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Block IP Address")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text(ip)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.axError)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            .background(Color.axSurface)

            Divider()

            // Form
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Duration")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(AXBlockDuration.allCases, id: \.self) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Reason (Optional)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    TextEditor(text: $reason)
                        .font(.system(size: 12))
                        .frame(height: 100)
                        .padding(AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }

                HStack(spacing: AXSpacing.md) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { onBlock(reason); dismiss() }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("Block IP")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axError)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AXSpacing.xl)
        }
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }
}
