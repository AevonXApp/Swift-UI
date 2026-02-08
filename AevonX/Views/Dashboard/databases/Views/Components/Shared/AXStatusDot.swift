//
//  AXStatusDot.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

public struct AXStatusDot: View {
    public let isActive: Bool
    
    public init(isActive: Bool) {
        self.isActive = isActive
    }
    
    public var body: some View {
        Circle()
            .fill(isActive ? Color.axSuccess : Color.axTextMuted)
            .frame(width: 8, height: 8)
    }
}
