//
//  RightClickHandler.swift
//  AevonX
//
//  macOS right-click handler using NSViewRepresentable
//  Intercepts right-click events for custom context menus
//

import SwiftUI

// MARK: - Right Click Handler

struct RightClickHandler: NSViewRepresentable {
    let action: (CGPoint) -> Void
    
    func makeNSView(context: Context) -> RightClickNSView {
        let view = RightClickNSView()
        view.onRightClick = action
        return view
    }
    
    func updateNSView(_ nsView: RightClickNSView, context: Context) {
        nsView.onRightClick = action
    }
    
    class RightClickNSView: NSView {
        var onRightClick: ((CGPoint) -> Void)?
        
        // Allow left-click events to pass through to SwiftUI gestures underneath
        override func hitTest(_ point: NSPoint) -> NSView? {
            // Only intercept right-click events — let left-clicks pass through
            guard let event = NSApp.currentEvent, event.type == .rightMouseDown else {
                return nil
            }
            return super.hitTest(point)
        }
        
        override func rightMouseDown(with event: NSEvent) {
            // Convert to window coordinates then to SwiftUI coordinate space
            guard let window = self.window else { return }
            let windowPoint = event.locationInWindow
            // Convert from bottom-left origin to top-left origin
            let viewHeight = window.contentView?.frame.height ?? window.frame.height
            let flipped = CGPoint(
                x: windowPoint.x,
                y: viewHeight - windowPoint.y
            )
            onRightClick?(flipped)
        }
    }
}
