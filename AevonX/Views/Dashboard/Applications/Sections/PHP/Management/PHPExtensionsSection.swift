//
//  PHPExtensionsSection.swift
//  AevonX
//
//  PHP modules & Zend extensions viewer.
//

import SwiftUI
import AevonXCoreBridge

struct PHPExtensionsSection: View {
    let serverId: String
    let modules: [BridgeModuleInfo]

    @State private var search = ""

    private var filtered: [BridgeModuleInfo] {
        search.isEmpty ? modules : modules.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.axTextMuted)
                TextField("Search extensions...", text: $search)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))
            Divider()
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filtered, id: \.name) { mod in
                        HStack {
                            Image(systemName: mod.enabled ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(mod.enabled ? .axSuccess : .axTextMuted)
                            Text(mod.name)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, AXSpacing.md).padding(.vertical, 6)
                        .background(Color.axSurface.opacity(0.2))
                    }
                }
            }
        }
    }
}
