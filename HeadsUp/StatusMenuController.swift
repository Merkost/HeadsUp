// StatusMenuController.swift
// HeadsUp
//
// Manages the status bar menu and user interactions

import Cocoa
import EventKit

// MARK: - Status Menu Controller
class StatusMenuController: NSObject {

    // MARK: - Properties
    private let statusItem: NSStatusItem
    private let calendarService: CalendarService
    private weak var appDelegate: AppDelegate?

    // MARK: - Initialization
    init(statusItem: NSStatusItem, calendarService: CalendarService, appDelegate: AppDelegate) {
        self.statusItem = statusItem
        self.calendarService = calendarService
        self.appDelegate = appDelegate
        super.init()
        setupMenu()
    }
    
    // MARK: - Menu Setup
    private func setupMenu() {
        let menu = NSMenu()
        menu.minimumWidth = 280
        menu.font = NSFont.systemFont(ofSize: 13)

        let eventsByDate = calendarService.fetchUpcomingEvents()
        let sortedDates = eventsByDate.keys.sorted()

        // Add clean header section
        addMinimalHeaderSection(to: menu)

        // Add events section
        if sortedDates.isEmpty {
            addMinimalNoEventsItem(to: menu)
        } else {
            addMinimalEventItems(to: menu, eventsByDate: eventsByDate, sortedDates: sortedDates)
        }

        // Add clean bottom section
        addMinimalBottomSection(to: menu)

        // Attach menu to status item
        statusItem.menu = menu
    }

    // MARK: - Menu Building Helpers (Minimal Design)

    private func addMinimalHeaderSection(to menu: NSMenu) {
        // Show next event in a clean, minimal way
        if let nextEvent = calendarService.getNextEvent() {
            let now = Date()

            // Event title
            let titleItem = NSMenuItem(title: nextEvent.title ?? "No Title", action: #selector(eventSelectedFromHeader), keyEquivalent: "")
            titleItem.representedObject = nextEvent
            titleItem.target = self

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            titleItem.attributedTitle = NSAttributedString(string: nextEvent.title ?? "No Title", attributes: titleAttributes)
            menu.addItem(titleItem)

            // Time info (subtle)
            let timeString: String
            if now >= nextEvent.startDate && now <= nextEvent.endDate {
                let remaining = TimeFormatter.formatCountdown(nextEvent.endDate.timeIntervalSince(now))
                timeString = "Ends in \(remaining)"
            } else {
                let starts = TimeFormatter.formatTime(nextEvent.startDate)
                timeString = starts
            }

            let timeItem = NSMenuItem(title: timeString, action: nil, keyEquivalent: "")
            timeItem.isEnabled = false
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            timeItem.attributedTitle = NSAttributedString(string: timeString, attributes: timeAttributes)
            menu.addItem(timeItem)

            menu.addItem(NSMenuItem.separator())
        }
    }

    private func addMinimalNoEventsItem(to menu: NSMenu) {
        let noEventsItem = NSMenuItem(title: "No upcoming events", action: nil, keyEquivalent: "")
        noEventsItem.isEnabled = false

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        noEventsItem.attributedTitle = NSAttributedString(string: "No upcoming events", attributes: attributes)
        menu.addItem(noEventsItem)

        menu.addItem(NSMenuItem.separator())
    }

    private func addMinimalEventItems(to menu: NSMenu, eventsByDate: [Date: [EKEvent]], sortedDates: [Date]) {
        let now = Date()
        let calendar = Calendar.current
        let maxEvents = 8  // Show fewer events for cleaner look
        var eventCount = 0
        var hasMoreEvents = false

        for date in sortedDates {
            // Skip if we've shown enough
            if eventCount >= maxEvents {
                hasMoreEvents = true
                break
            }

            let isToday = calendar.isDateInToday(date)

            // Only show date header if not today (today's events are obvious)
            if !isToday {
                let dateString = TimeFormatter.formatFullDate(date)
                let dateItem = NSMenuItem(title: dateString, action: nil, keyEquivalent: "")
                dateItem.isEnabled = false

                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: NSColor.tertiaryLabelColor
                ]
                dateItem.attributedTitle = NSAttributedString(string: dateString.uppercased(), attributes: dateAttributes)
                menu.addItem(dateItem)
            }

            // Add events for this date
            if let events = eventsByDate[date] {
                for event in events {
                    if eventCount >= maxEvents {
                        hasMoreEvents = true
                        break
                    }

                    let timeString = TimeFormatter.formatTime(event.startDate)
                    let eventTitle = event.title ?? "No Title"

                    // Simple format: just time and title
                    let displayTitle = "\(timeString)   \(eventTitle)"
                    let eventItem = NSMenuItem(title: displayTitle, action: #selector(eventSelected(_:)), keyEquivalent: "")
                    eventItem.representedObject = event
                    eventItem.target = self

                    // Minimal styling - just subtle emphasis for current event
                    let isOngoing = now >= event.startDate && now <= event.endDate

                    let eventAttributes: [NSAttributedString.Key: Any]
                    if isOngoing {
                        eventAttributes = [
                            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                            .foregroundColor: NSColor.labelColor
                        ]
                    } else {
                        eventAttributes = [
                            .font: NSFont.systemFont(ofSize: 13),
                            .foregroundColor: NSColor.secondaryLabelColor
                        ]
                    }
                    eventItem.attributedTitle = NSAttributedString(string: displayTitle, attributes: eventAttributes)

                    menu.addItem(eventItem)
                    eventCount += 1
                }
            }
        }

        // Show more indicator if needed
        if hasMoreEvents {
            let moreItem = NSMenuItem(title: "View all in Calendar...", action: #selector(openCalendar), keyEquivalent: "")
            moreItem.target = self
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.tertiaryLabelColor
            ]
            moreItem.attributedTitle = NSAttributedString(string: "View all in Calendar...", attributes: moreAttributes)
            menu.addItem(moreItem)
        }

        menu.addItem(NSMenuItem.separator())
    }

    private func addMinimalBottomSection(to menu: NSMenu) {
        // Widget toggle
        let widgetItem = NSMenuItem(title: "Desktop Widget", action: #selector(toggleWidget), keyEquivalent: "w")
        widgetItem.target = self
        menu.addItem(widgetItem)

        menu.addItem(NSMenuItem.separator())

        // Settings submenu (collapsed for minimalism)
        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: ",")
        let settingsSubmenu = NSMenu()

        // Always show next event
        let alwaysShowNextEvent = UserDefaults.standard.bool(forKey: UserDefaultsKeys.alwaysShowNextEvent)
        let showNextItem = NSMenuItem(
            title: "Always show next event",
            action: #selector(toggleAlwaysShowNextEvent(_:)),
            keyEquivalent: ""
        )
        showNextItem.state = alwaysShowNextEvent ? .on : .off
        showNextItem.target = self
        settingsSubmenu.addItem(showNextItem)

        // Show past events
        let showPastEvents = UserDefaults.standard.bool(forKey: UserDefaultsKeys.showPastEventsForToday)
        let pastEventsItem = NSMenuItem(
            title: "Show past events for today",
            action: #selector(toggleShowPastEvents(_:)),
            keyEquivalent: ""
        )
        pastEventsItem.state = showPastEvents ? .on : .off
        pastEventsItem.target = self
        settingsSubmenu.addItem(pastEventsItem)

        settingsSubmenu.addItem(NSMenuItem.separator())

        // Welcome guide
        let guideItem = NSMenuItem(title: "Show Welcome Guide...", action: #selector(resetOnboarding), keyEquivalent: "")
        guideItem.target = self
        settingsSubmenu.addItem(guideItem)

        settingsItem.submenu = settingsSubmenu
        menu.addItem(settingsItem)

        // Check for updates
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit HeadsUp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    // MARK: - Action Handlers

    @objc func eventSelectedFromHeader(_ sender: NSMenuItem) {
        guard let event = sender.representedObject as? EKEvent else { return }
        appDelegate?.showFullscreenAlert(for: event)
    }

    @objc func eventSelected(_ sender: NSMenuItem) {
        guard let event = sender.representedObject as? EKEvent else { return }
        appDelegate?.showFullscreenAlert(for: event)
    }

    @objc func toggleAlwaysShowNextEvent(_ sender: NSMenuItem) {
        let currentSetting = UserDefaults.standard.bool(forKey: UserDefaultsKeys.alwaysShowNextEvent)
        let newSetting = !currentSetting
        UserDefaults.standard.set(newSetting, forKey: UserDefaultsKeys.alwaysShowNextEvent)
        sender.state = newSetting ? .on : .off
        appDelegate?.updateStatusItemTitle()
    }

    @objc func toggleShowPastEvents(_ sender: NSMenuItem) {
        let currentSetting = UserDefaults.standard.bool(forKey: UserDefaultsKeys.showPastEventsForToday)
        let newSetting = !currentSetting
        UserDefaults.standard.set(newSetting, forKey: UserDefaultsKeys.showPastEventsForToday)
        sender.state = newSetting ? .on : .off
        setupMenu() // Refresh menu to show/hide past events
    }

    @objc func toggleWidget() {
        appDelegate?.toggleWidget()
    }

    @objc func resetOnboarding() {
        // Reset onboarding flag and show welcome guide
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.hasCompletedOnboarding)
        appDelegate?.checkOnboardingStatus()
    }

    @objc func refreshMenu() {
        setupMenu()
        appDelegate?.updateStatusItemTitle()
    }

    @objc func openCalendar() {
        // Open the system Calendar app
        NSWorkspace.shared.open(URL(string: "x-apple-eventkit://")!)
    }

    @objc func checkForUpdates() {
        UpdateService.shared.checkForUpdatesManually()
    }

    @objc func showAboutWindow() {
        let alert = NSAlert()
        alert.messageText = "HeadsUp"
        alert.informativeText = """
        Never miss a meeting again.

        HeadsUp helps you stay on top of your meetings by displaying them in your menu bar \
        and alerting you before they start.

        Version 0.2.0

        ✨ Features:
        • Smart menu bar countdown to next meeting
        • Fullscreen alerts 60 seconds before meetings
        • Beautiful desktop widget for at-a-glance view
        • Automatic meeting link detection and quick join
        • Support for Zoom, Google Meet, Teams & more

        🔒 Privacy:
        • Your calendar data never leaves your device
        • No network requests except opening meeting links
        • No tracking or analytics

        Created with ❤️ by Konstantin Merenkov
        """
        alert.alertStyle = .informational

        // Set app icon if available
        if let appIcon = NSImage(named: "AppIcon") {
            alert.icon = appIcon
        }

        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
