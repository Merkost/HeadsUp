//
//  AppDelegate.swift
//  HeadsUp
//
//  Created by Konstantin Merenkov on 15.10.2024.
//  Refactored: 2025-11-09
//

import Cocoa
import EventKit

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    var statusItem: NSStatusItem!
    private let calendarService = CalendarService.shared
    private var timer: Timer?
    var fullscreenWindow: NSWindow?
    var statusMenuController: StatusMenuController?
    var widgetWindowController: WidgetWindowController?

    // MARK: - Application Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaultSettings()
        requestCalendarAccess()
        setupStatusItem()
    }

    // MARK: - Settings
    private func registerDefaultSettings() {
        let defaults: [String: Any] = [
            UserDefaultsKeys.alwaysShowNextEvent: false,
            UserDefaultsKeys.showPastEventsForToday: false
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    // MARK: - Calendar Access
    func requestCalendarAccess() {
        calendarService.requestAccess { [weak self] granted, error in
            guard let self = self else { return }

            if granted {
                print("✓ Calendar access granted")
                self.setupStatusItem()
                self.startMeetingAlertTimer()
            } else {
                print("✗ Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                self.showAccessDeniedAlert(error: error)
            }
        }
    }

    // MARK: - Status Bar Setup
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
        }

        statusMenuController = StatusMenuController(
            statusItem: statusItem,
            calendarService: calendarService,
            appDelegate: self
        )
    }
    
    // MARK: - Alert Dialogs
    func showAccessDeniedAlert(error: Error?) {
        let alert = NSAlert()
        alert.messageText = "Calendar Access Required"
        alert.informativeText = "HeadsUp needs access to your calendar to display upcoming meetings. Please grant access in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                NSWorkspace.shared.open(url)
            }
        }
        NSApp.terminate(self)
    }

    // MARK: - Event Fetching (Compatibility)
    /// Legacy method for compatibility with StatusMenuController
    func fetchUpcomingEvents() -> [Date: [EKEvent]] {
        return calendarService.fetchUpcomingEvents()
    }

    // MARK: - Meeting Monitoring
    @objc func checkForUpcomingMeetings() {
        let events = calendarService.getEventsStartingSoon(timeWindow: 60)

        if !events.isEmpty {
            print("⏰ Found \(events.count) meeting(s) starting in 60 seconds")
        }

        for event in events {
            print("📅 Upcoming meeting: \(event.title ?? "No Title")")
            showFullscreenAlert(for: event)
        }
    }
        
    // MARK: - Fullscreen Alert
    func showFullscreenAlert(for event: EKEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let screenFrame = NSScreen.main?.frame ?? NSRect.zero
            let window = NSWindow(
                contentRect: screenFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            // Window configuration
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = .clear
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
            window.acceptsMouseMovedEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false

            // Create and configure alert view controller
            let alertViewController = AlertViewController()
            alertViewController.event = event
            alertViewController.appDelegate = self
            window.contentViewController = alertViewController

            // Retain window reference
            self.fullscreenWindow = window
        }
    }
        
    // MARK: - Status Item Updates
    func updateStatusItemTitle() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            guard let nextEvent = self.calendarService.getNextEvent() else {
                self.setDefaultStatusIcon()
                return
            }

            let now = Date()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            let eventDay = calendar.startOfDay(for: nextEvent.startDate)

            // Get user preference
            let alwaysShowNextEvent = UserDefaults.standard.bool(forKey: UserDefaultsKeys.alwaysShowNextEvent)

            // Check if we should display the next event
            guard alwaysShowNextEvent || eventDay == today else {
                self.setDefaultStatusIcon()
                return
            }

            // Update title based on event status
            if now >= nextEvent.startDate && now <= nextEvent.endDate {
                // Meeting is currently in progress
                let timeInterval = nextEvent.endDate.timeIntervalSince(now)
                let formattedTime = TimeFormatter.formatTimeInterval(timeInterval)
                let eventTitle = TimeFormatter.truncateText(nextEvent.title ?? "No Title")
                self.statusItem.button?.title = "\(eventTitle) ends in \(formattedTime)"
                self.statusItem.button?.image = nil
            } else if now < nextEvent.startDate {
                // Meeting is upcoming
                let timeInterval = nextEvent.startDate.timeIntervalSince(now)
                let formattedTime = TimeFormatter.formatTimeInterval(timeInterval)
                let eventTitle = TimeFormatter.truncateText(nextEvent.title ?? "No Title")
                self.statusItem.button?.title = "\(eventTitle) in \(formattedTime)"
                self.statusItem.button?.image = nil
            } else {
                self.setDefaultStatusIcon()
            }
        }
    }

    private func setDefaultStatusIcon() {
        statusItem.button?.title = ""
        statusItem.button?.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
    }
        
    // MARK: - Timer Management
    func startMeetingAlertTimer() {
        // Invalidate existing timer
        timer?.invalidate()
        timer = nil

        // Fire immediately on start
        updateTimerFired()

        // Schedule timer to fire on minute boundaries
        let now = Date()
        let calendar = Calendar.current

        if let nextMinute = calendar.nextDate(
            after: now,
            matching: DateComponents(second: 0),
            matchingPolicy: .strict
        ) {
            let newTimer = Timer(
                fireAt: nextMinute,
                interval: 60,
                target: self,
                selector: #selector(updateTimerFired),
                userInfo: nil,
                repeats: true
            )
            RunLoop.main.add(newTimer, forMode: .common)
            self.timer = newTimer
            print("⏱ Timer scheduled to start at \(nextMinute)")
        }
    }

    @objc func updateTimerFired() {
        checkForUpcomingMeetings()
        updateStatusItemTitle()
    }

    // MARK: - Widget Management
    func toggleWidget() {
        if widgetWindowController == nil {
            widgetWindowController = WidgetWindowController()
        }
        widgetWindowController?.toggleWidget()
    }

    func showWidget() {
        if widgetWindowController == nil {
            widgetWindowController = WidgetWindowController()
        }
        widgetWindowController?.showWidget()
    }

    func hideWidget() {
        widgetWindowController?.hideWidget()
    }
}

