//
//  ZoomInputView.swift
//  Film-Converter
//

import AppKit
import SwiftUI

struct ZoomInputView: NSViewRepresentable {
    let onScroll: (Double) -> Void
    let onMagnify: (Double) -> Void
    let onDoubleClick: () -> Void
    let onConfirm: () -> Void

    func makeNSView(context: Context) -> ZoomInputNSView {
        let view = ZoomInputNSView()
        view.onScroll = onScroll
        view.onMagnify = onMagnify
        view.onDoubleClick = onDoubleClick
        view.onConfirm = onConfirm
        return view
    }

    func updateNSView(_ nsView: ZoomInputNSView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onMagnify = onMagnify
        nsView.onDoubleClick = onDoubleClick
        nsView.onConfirm = onConfirm
    }
}

final class ZoomInputNSView: NSView {
    var onScroll: ((Double) -> Void)?
    var onMagnify: ((Double) -> Void)?
    var onDoubleClick: (() -> Void)?
    var onConfirm: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func scrollWheel(with event: NSEvent) {
        onScroll?(Double(event.scrollingDeltaY))
    }

    override func magnify(with event: NSEvent) {
        onMagnify?(Double(event.magnification))
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
        } else {
            super.mouseDown(with: event)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            onConfirm?()
        } else {
            super.keyDown(with: event)
        }
    }
}
