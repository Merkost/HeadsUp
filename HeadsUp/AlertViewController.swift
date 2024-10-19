// AlertViewController.swift

import Cocoa
import EventKit

class AlertViewController: NSViewController {
    var event: EKEvent?
    var timerLabel: NSTextField!
    var updateTimer: Timer?
    
    override func loadView() {
        self.view = NSView(frame: NSScreen.main?.frame ?? NSRect.zero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.alphaValue = 0.0 // Start transparent
        setupUI()
        animateAppearance()
    }
    
    func animateAppearance() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            self.view.animator().alphaValue = 1.0
        }, completionHandler: nil)
    }
    
    func setupUI() {
        guard let event = event else { return }
        let contentView = self.view
        
        // Background
        let backgroundView = NSVisualEffectView(frame: contentView.bounds)
        backgroundView.autoresizingMask = [.width, .height]
        backgroundView.blendingMode = .behindWindow
        backgroundView.material = .dark
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
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let startTime = timeFormatter.string(from: event.startDate)
        let endTime = timeFormatter.string(from: event.endDate)
        let timeLabel = NSTextField(labelWithString: "\(startTime) - \(endTime)")
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
        
        // Buttons
        let buttonWidth: CGFloat = 200
        
        let joinButton = NSButton(title: "Join Meeting", target: self, action: #selector(joinMeeting))
        styleButton(joinButton, backgroundColor: NSColor.systemBlue, width: buttonWidth)
        
        let openCalendarButton = NSButton(title: "Open in Calendar", target: self, action: #selector(openInCalendar))
        styleButton(openCalendarButton, backgroundColor: NSColor.systemOrange, width: buttonWidth)
        
        let skipButton = NSButton(title: "Skip", target: self, action: #selector(skipDialog))
        // The skip button's width will be the combined width of the two buttons above plus the spacing between them
        let skipButtonWidth = (buttonWidth * 2) + 20 // 20 is the spacing between the buttons in the stack
        styleButton(skipButton, backgroundColor: NSColor.systemGray, width: skipButtonWidth)
        
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
    
    func styleButton(_ button: NSButton, backgroundColor: NSColor, width: CGFloat) {
        button.font = NSFont.systemFont(ofSize: 24)
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = backgroundColor.cgColor
        button.layer?.cornerRadius = 8
        button.layer?.borderWidth = 0
        button.layer?.borderColor = NSColor.clear.cgColor
        button.contentTintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.widthAnchor.constraint(equalToConstant: width).isActive = true
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
    
    @objc func updateTimerLabel() {
        guard let event = event else { return }
        let now = Date()
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if now < event.startDate {
            // Time until meeting starts
            let timeInterval = event.startDate.timeIntervalSince(now)
            timerLabel.stringValue = "Starts in \(formatter.string(from: timeInterval) ?? "0s")"
        } else {
            // Time since meeting started
            let timeInterval = now.timeIntervalSince(event.startDate)
            timerLabel.stringValue = "Started \(formatter.string(from: timeInterval) ?? "0s") ago"
        }
    }
}
