//
//  ToastDetailSheet.swift
//  AevonX
//
//  Developer-facing payload viewer presented from a toast's "View Details"
//  button. Pretty-prints JSON when possible, falls back to raw text. Includes
//  copy-to-clipboard for fast bug reporting.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct ToastDetailSheet: View {
    let title: String
    let tint: Color
    let payload: String

    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var prettyPayload: String {
        guard let data = payload.data(using: .utf8) else { return payload }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) else {
            return payload
        }
        guard let pretty = try? JSONSerialization.data(
            withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]
        ), let s = String(data: pretty, encoding: .utf8) else {
            return payload
        }
        return s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                Text(title)
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)

                Spacer()

                Button {
                    copyToClipboard(prettyPayload)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .semibold))
                        Text(copied ? "Copied" : "Copy")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(tint)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 26, height: 26)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axBackgroundTertiary)

            Divider().background(Color.axBorder)

            // Body — scrollable monospaced payload
            ScrollView {
                Text(prettyPayload)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AXSpacing.lg)
            }
            .background(Color.axBackground)
        }
        .frame(minWidth: 520, idealWidth: 640, minHeight: 360, idealHeight: 480)
        .background(Color.axBackground)
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #elseif canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

#Preview {
    ToastDetailSheet(
        title: "Webhook registered successfully",
        tint: .axEmerald,
        payload: """
        {
          "status": "ok",
          "webhook_url": "https://212.47.73.102:8443/webhook/abc123",
          "public_host": "212.47.73.102",
          "cert": "/var/lib/aevonx/axghost/webhook.crt",
          "message": "Webhook registered successfully. Restart daemon to apply."
        }
        """
    )
}
