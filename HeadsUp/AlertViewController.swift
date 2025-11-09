// AlertViewController.swift
// HeadsUp
//
// Fullscreen alert view for upcoming meetings

import Cocoa
import EventKit

// MARK: - Alert View Controller
class AlertViewController: NSViewController {

    // MARK: - Properties
    var event: EKEvent?
    weak var appDelegate: AppDelegate?
    private var timerLabel: NSTextField!
    private var updateTimer: Timer?
    
    // MARK: - View Lifecycle
    override func loadView() {
        self.view = NSView(frame: NSScreen.main?.frame ?? NSRect.zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.alphaValue = 0.0 // Start transparent
        setupUI()
        animateAppearance()
    }

    // MARK: - Animations
    private func animateAppearance() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.6
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.view.animator().alphaValue = 1.0
        }, completionHandler: nil)
    }

    // MARK: - UI Setup
    func setupUI() {
        guard let event = event else { return }
        let contentView = self.view

        // Enhanced Background with blur
        let backgroundView = NSVisualEffectView(frame: contentView.bounds)
        backgroundView.autoresizingMask = [.width, .height]
        backgroundView.blendingMode = .behindWindow
        backgroundView.material = .fullScreenUI
        backgroundView.state = .active
        contentView.addSubview(backgroundView)
        
        // Add click gesture recognizer to the background view
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(backgroundClicked))
        clickRecognizer.buttonMask = 0x1 // Left mouse button
        backgroundView.addGestureRecognizer(clickRecognizer)
        
        // Close Button
        let closeButton = NSButton(image: NSImage(named: NSImage.stopProgressTemplateName)!, target: self, action: #selector(closeDialog))
        closeButton.bezelStyle = .regularSquare
        closeButton.isBordered = false
        closeButton.contentTintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(closeButton)
        
        // Container for dialog content
        let dialogContainer = NSView()
        dialogContainer.wantsLayer = true
        dialogContainer.layer?.backgroundColor = NSColor.clear.cgColor
        dialogContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dialogContainer)
        
        // Title Label
        let titleLabel = NSTextField(labelWithString: event.title ?? "No Title")
        titleLabel.font = NSFont.systemFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dialogContainer.addSubview(titleLabel)
        
        // Time Label
        let timeRange = TimeFormatter.formatTimeRange(startDate: event.startDate, endDate: event.endDate)
        let timeLabel = NSTextField(labelWithString: timeRange)
        timeLabel.font = NSFont.systemFont(ofSize: 24)
        timeLabel.textColor = .white
        timeLabel.alignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        dialogContainer.addSubview(timeLabel)
        
        // Timer Label
        timerLabel = NSTextField(labelWithString: "")
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 36, weight: .medium)
        timerLabel.textColor = .white
        timerLabel.alignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        dialogContainer.addSubview(timerLabel)
        
        // Enhanced Buttons with better styling
        let buttonWidth: CGFloat = 220
        let buttonHeight: CGFloat = 56

        let joinButton = createStyledButton(
            title: "🎥 Join Meeting",
            backgroundColor: NSColor.systemBlue,
            width: buttonWidth,
            height: buttonHeight,
            action: #selector(joinMeeting)
        )

        let openCalendarButton = createStyledButton(
            title: "📅 Open in Calendar",
            backgroundColor: NSColor.systemOrange,
            width: buttonWidth,
            height: buttonHeight,
            action: #selector(openInCalendar)
        )

        let skipButtonWidth = (buttonWidth * 2) + 20
        let skipButton = createStyledButton(
            title: "Skip",
            backgroundColor: NSColor.systemGray,
            width: skipButtonWidth,
            height: buttonHeight,
            action: #selector(skipDialog)
        )
        
        // Button Stack for Join and Open Calendar Buttons
        let buttonStack = NSStackView(views: [joinButton, openCalendarButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 20
        buttonStack.alignment = .centerY
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Main Stack to hold buttons
        let mainButtonStack = NSStackView()
        mainButtonStack.orientation = .vertical
        mainButtonStack.spacing = 20
        mainButtonStack.alignment = .centerX
        mainButtonStack.translatesAutoresizingMaskIntoConstraints = false
        mainButtonStack.addArrangedSubview(buttonStack)
        mainButtonStack.addArrangedSubview(skipButton)
        dialogContainer.addSubview(mainButtonStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Close Button Constraints
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Dialog Container Constraints
            dialogContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dialogContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dialogContainer.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            dialogContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            // Title Label Constraints
            titleLabel.centerXAnchor.constraint(equalTo: dialogContainer.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: dialogContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: dialogContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: dialogContainer.trailingAnchor),
            
            // Time Label Constraints
            timeLabel.centerXAnchor.constraint(equalTo: dialogContainer.centerXAnchor),
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            
            // Timer Label Constraints
            timerLabel.centerXAnchor.constraint(equalTo: dialogContainer.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 40),
            
            // Main Button Stack Constraints
            mainButtonStack.centerXAnchor.constraint(equalTo: dialogContainer.centerXAnchor),
            mainButtonStack.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 60),
            mainButtonStack.bottomAnchor.constraint(equalTo: dialogContainer.bottomAnchor)
        ])
        
        // Handle keyboard events
        self.view.window?.makeFirstResponder(self)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key code
                self?.closeDialog()
                return nil
            }
            return event
        }
        
        startTimer()
    }
    
    @objc func backgroundClicked(_ sender: NSClickGestureRecognizer) {
        // Check if the click was outside the dialog container
        let clickLocation = sender.location(in: self.view)
        if let dialogContainer = self.view.subviews.first(where: { $0 != self.view.subviews[0] && $0 != self.view.subviews[1] }) {
            if !dialogContainer.frame.contains(clickLocation) {
                closeDialog()
            }
        }
    }
    
    // MARK: - UI Helpers
    private func createStyledButton(
        title: String,
        backgroundColor: NSColor,
        width: CGFloat,
        height: CGFloat,
        action: Selector
    ) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = backgroundColor.cgColor
        button.layer?.cornerRadius = 12
        button.contentTintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false

        // Add hover effect
        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: button,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)

        // Constraints
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        button.widthAnchor.constraint(equalToConstant: width).isActive = true

        return button
    }
    
    @objc func joinMeeting() {
        if let event = event, let url = MeetingLinkExtractor.shared.getMeetingLink(from: event) {
            NSWorkspace.shared.open(url)
        } else {
            // Handle the case where no meeting link is found
            let alert = NSAlert()
            alert.messageText = "No Meeting Link Found"
            alert.informativeText = "Could not find a meeting link in the event."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        closeDialog()
    }
    
    @objc func openInCalendar() {
        guard let event = event else { return }

        
    }
    
    @objc func skipDialog() {
        closeDialog()
    }
    
    @objc func closeDialog() {
        stopTimer()
        self.view.window?.close()
    }
    
    func startTimer() {
        updateTimerLabel() // Initial update
        updateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimerLabel), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Timer Updates
    @objc func updateTimerLabel() {
        guard let event = event else { return }
        let now = Date()

        if now < event.startDate {
            // Time until meeting starts
            let timeInterval = event.startDate.timeIntervalSince(now)
            let countdown = TimeFormatter.formatCountdown(timeInterval)
            timerLabel.stringValue = "Starts in \(countdown)"
        } else {
            // Time since meeting started
            let timeInterval = now.timeIntervalSince(event.startDate)
            let countdown = TimeFormatter.formatCountdown(timeInterval)
            timerLabel.stringValue = "Started \(countdown) ago"
        }
    }
}
