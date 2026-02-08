//
//  AXLabelValueItem.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

public struct AXLabelValueItem: View {
    public let icon: String
    public let value: String
    public let label: String
    
    public init(icon: String, value: String, label: String) {
        self.icon = icon
        self.value = value
        self.label = label
    }
    
    public var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.axTextMuted)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
        }
    }
}
