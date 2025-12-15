//
//  WidgetWindowController.swift
//  HeadsUp
//
//  Window controller for desktop widget
//

import Cocoa
import SwiftUI

// MARK: - Widget Window Controller
class WidgetWindowController: NSWindowController {

    // MARK: - Properties
    private var widgetWindow: NSWindow?

    // MARK: - Initialization
    convenience init() {
        // Create a floating window for the widget
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        window.title = "HeadsUp Widget"
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Create SwiftUI view
        let widgetView = MeetingWidgetView()
        let hostingView = NSHostingView(rootView: widgetView)
        window.contentView = hostingView

        // Position window in bottom-right corner
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - window.frame.width - 20
            let y = screenFrame.minY + 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.init(window: window)
        self.widgetWindow = window
    }

    // MARK: - Window Management
    func showWidget() {
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    func hideWidget() {
        window?.orderOut(nil)
    }

    func toggleWidget() {
        if window?.isVisible == true {
            hideWidget()
        } else {
            showWidget()
        }
    }
}
