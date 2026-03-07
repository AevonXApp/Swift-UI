//
//  LineNumberRulerView.swift
//  AevonX
//
//  Custom NSRulerView showing line numbers — uses EditorTheme colors
//  to match the app's #121212 dark theme.
//

import AppKit

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    private weak var associatedTextView: NSTextView?

    init(textView: NSTextView) {
        self.associatedTextView = textView
        let scrollView = textView.enclosingScrollView ?? NSScrollView()
        super.init(scrollView: scrollView, orientation: .verticalRuler)

        self.ruleThickness = 44
        self.clientView    = textView

        NotificationCenter.default.addObserver(
            self, selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification, object: textView
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: textView.enclosingScrollView?.contentView
        )
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func textDidChange(_ n: Notification) { needsDisplay = true }
    @objc private func boundsDidChange(_ n: Notification) { needsDisplay = true }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView     = associatedTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        // Gutter background
        EditorTheme.gutter.setFill()
        rect.fill()

        let visibleRect = textView.visibleRect
        let glyphRange  = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange   = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let text = textView.string as NSString
        var lineNumber = 1

        // Count lines before visible range
        text.substring(to: charRange.location).enumerateLines { _, _ in lineNumber += 1 }
        lineNumber -= 1
        if lineNumber < 1 { lineNumber = 1 }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: EditorTheme.lineNumbers
        ]

        var index = charRange.location
        while index < NSMaxRange(charRange) {
            let lineRange = text.lineRange(for: NSRange(location: index, length: 0))
            let glyphR    = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            var lineRect  = layoutManager.lineFragmentRect(forGlyphAt: glyphR.location, effectiveRange: nil)
            lineRect.origin.y -= visibleRect.origin.y

            let numStr  = "\(lineNumber)" as NSString
            let strSize = numStr.size(withAttributes: attrs)
            let drawPt  = NSPoint(
                x: ruleThickness - strSize.width - 8,
                y: lineRect.origin.y + (lineRect.height - strSize.height) / 2
            )
            numStr.draw(at: drawPt, withAttributes: attrs)

            lineNumber += 1
            index = NSMaxRange(lineRange)
        }

        // Separator
        EditorTheme.gutterLine.setStroke()
        let sep = NSBezierPath()
        sep.move(to: NSPoint(x: ruleThickness - 1, y: rect.minY))
        sep.line(to: NSPoint(x: ruleThickness - 1, y: rect.maxY))
        sep.lineWidth = 1
        sep.stroke()
    }
}
