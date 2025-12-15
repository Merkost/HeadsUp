//
//  OnboardingWindowController.swift
//  HeadsUp
//
//  Window controller for onboarding flow
//

import Cocoa
import SwiftUI

// MARK: - Onboarding Window Controller
class OnboardingWindowController: NSWindowController {

    // MARK: - Properties
    private var onComplete: ((OnboardingSettings) -> Void)?

    // MARK: - Initialization
    convenience init(onComplete: @escaping (OnboardingSettings) -> Void) {
        // Create a centered window for onboarding
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        window.title = "Welcome to HeadsUp"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor
        window.center()
        window.isReleasedWhenClosed = false

        // Prevent window from closing during onboarding
        window.standardWindowButton(.closeButton)?.isEnabled = false

        self.init(window: window)
        self.onComplete = onComplete
        setupContent()
    }

    // MARK: - Setup

    private func setupContent() {
        guard let window = window else { return }

        // Create SwiftUI onboarding view
        let onboardingView = OnboardingView { [weak self] settings in
            self?.completeOnboarding(with: settings)
        }

        // Create hosting view
        let hostingView = NSHostingView(rootView: onboardingView)
        window.contentView = hostingView
    }

    // MARK: - Actions

    private func completeOnboarding(with settings: OnboardingSettings) {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)

        // Apply settings
        UserDefaults.standard.set(settings.alwaysShowNextEvent, forKey: UserDefaultsKeys.alwaysShowNextEvent)

        // Notify completion
        onComplete?(settings)

        // Close window with animation
        window?.animator().alphaValue = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.close()
        }
    }

    // MARK: - Window Management

    func show() {
        window?.makeKeyAndOrderFront(nil)
        window?.center()

        // Fade in animation
        window?.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window?.animator().alphaValue = 1.0
        })
    }
}
