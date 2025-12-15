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
        menu.minimumWidth = 300  // Set minimum width for better appearance
        menu.font = NSFont.systemFont(ofSize: 13)  // Consistent font size

        let eventsByDate = calendarService.fetchUpcomingEvents()
        let sortedDates = eventsByDate.keys.sorted()

        // Add header section with next event info
        addHeaderSection(to: menu)

        // Add events section
        if sortedDates.isEmpty {
            addNoEventsItem(to: menu)
        } else {
            addEventItems(to: menu, eventsByDate: eventsByDate, sortedDates: sortedDates)
        }

        // Add settings section
        addSettingsSection(to: menu)

        // Add bottom section (Widget, About, Quit)
        addBottomSection(to: menu)

        // Attach menu to status item
        statusItem.menu = menu
    }

    // MARK: - Menu Building Helpers

    private func addHeaderSection(to menu: NSMenu) {
        // Get next event for header
        if let nextEvent = calendarService.getNextEvent() {
            let now = Date()
            let timeInterval = nextEvent.startDate.timeIntervalSince(now)

            // Create header item with next event info
            let headerTitle: String
            let icon: NSImage?

            if now >= nextEvent.startDate && now <= nextEvent.endDate {
                // Meeting is currently in progress
                let formattedTime = TimeFormatter.formatCountdown(nextEvent.endDate.timeIntervalSince(now))
                headerTitle = "Current: \(nextEvent.title ?? "No Title")"
                icon = NSImage(systemSymbolName: "video.fill", accessibilityDescription: "Current meeting")
                icon?.isTemplate = true
            } else if timeInterval > 0 && timeInterval <= 3600 {
                // Meeting within next hour
                let formattedTime = TimeFormatter.formatCountdown(timeInterval)
                headerTitle = "Next: \(nextEvent.title ?? "No Title") in \(formattedTime)"
                icon = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "Next meeting")
                icon?.isTemplate = true
            } else {
                // Meeting is further away
                let timeString = TimeFormatter.formatTime(nextEvent.startDate)
                headerTitle = "Next: \(nextEvent.title ?? "No Title") at \(timeString)"
                icon = NSImage(systemSymbolName: "calendar.circle.fill", accessibilityDescription: "Upcoming meeting")
                icon?.isTemplate = true
            }

            let headerItem = NSMenuItem(title: headerTitle, action: nil, keyEquivalent: "")
            headerItem.image = icon
            headerItem.isEnabled = false

            // Use attributed string for better styling
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
            headerItem.attributedTitle = NSAttributedString(string: headerTitle, attributes: attributes)
            headerItem.image = icon

            menu.addItem(headerItem)
            menu.addItem(NSMenuItem.separator())
        }
    }

    private func addNoEventsItem(to menu: NSMenu) {
        let icon = NSImage(systemSymbolName: "calendar.badge.exclamationmark", accessibilityDescription: "No events")
        icon?.isTemplate = true

        let noEventsItem = NSMenuItem(title: "No upcoming events", action: nil, keyEquivalent: "")
        noEventsItem.image = icon
        noEventsItem.isEnabled = false

        // Add helpful subtext
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        noEventsItem.attributedTitle = NSAttributedString(string: "No upcoming events", attributes: attributes)

        menu.addItem(noEventsItem)

        // Add a tip
        let tipItem = NSMenuItem(title: "Open Calendar to add events", action: #selector(openCalendar), keyEquivalent: "")
        tipItem.target = self
        let tipAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        tipItem.attributedTitle = NSAttributedString(string: "  Open Calendar to add events", attributes: tipAttributes)
        menu.addItem(tipItem)
    }

    private func addEventItems(to menu: NSMenu, eventsByDate: [Date: [EKEvent]], sortedDates: [Date]) {
        let now = Date()
        let calendar = Calendar.current
        let maxEvents = 12  // Limit to prevent menu spanning entire screen
        var eventCount = 0
        var hasMoreEvents = false

        for (index, date) in sortedDates.enumerated() {
            // Add date header with icon
            let dateString = TimeFormatter.formatFullDate(date)
            let isToday = calendar.isDateInToday(date)
            let isTomorrow = calendar.isDateInTomorrow(date)

            let dateTitle: String
            if isToday {
                dateTitle = "Today, \(dateString)"
            } else if isTomorrow {
                dateTitle = "Tomorrow, \(dateString)"
            } else {
                dateTitle = dateString
            }

            let dateIcon = NSImage(systemSymbolName: isToday ? "calendar.circle.fill" : "calendar", accessibilityDescription: "Date")
            dateIcon?.isTemplate = true

            let dateItem = NSMenuItem(title: dateTitle, action: nil, keyEquivalent: "")
            dateItem.image = dateIcon
            dateItem.isEnabled = false

            // Style date header
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: isToday ? NSColor.systemBlue : NSColor.secondaryLabelColor
            ]
            dateItem.attributedTitle = NSAttributedString(string: dateTitle, attributes: dateAttributes)
            dateItem.image = dateIcon

            menu.addItem(dateItem)

            // Add events for this date
            if let events = eventsByDate[date] {
                for event in events {
                    // Check if we've reached the event limit
                    if eventCount >= maxEvents {
                        hasMoreEvents = true
                        break
                    }

                    let timeString = TimeFormatter.formatTime(event.startDate)
                    let eventTitle = event.title ?? "No Title"

                    // Determine event status and icon
                    let eventIcon: NSImage?
                    let isOngoing = now >= event.startDate && now <= event.endDate
                    let isPast = now > event.endDate
                    let isUpcomingSoon = event.startDate.timeIntervalSince(now) <= 3600 && event.startDate > now

                    if isOngoing {
                        eventIcon = NSImage(systemSymbolName: "video.circle.fill", accessibilityDescription: "Ongoing")
                    } else if isUpcomingSoon {
                        eventIcon = NSImage(systemSymbolName: "bell.circle.fill", accessibilityDescription: "Soon")
                    } else if isPast {
                        eventIcon = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Past")
                    } else {
                        eventIcon = NSImage(systemSymbolName: "circle", accessibilityDescription: "Upcoming")
                    }
                    eventIcon?.isTemplate = true

                    // Format event title with indentation
                    let displayTitle = "  \(timeString)  \(eventTitle)"
                    let eventItem = NSMenuItem(title: displayTitle, action: #selector(eventSelected(_:)), keyEquivalent: "")
                    eventItem.representedObject = event
                    eventItem.target = self
                    eventItem.image = eventIcon

                    // Style based on event status with professional colors
                    let eventAttributes: [NSAttributedString.Key: Any]
                    if isOngoing {
                        // Professional teal/cyan for ongoing (not bright green)
                        eventAttributes = [
                            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                            .foregroundColor: NSColor(calibratedRed: 0.0, green: 0.7, blue: 0.7, alpha: 1.0)
                        ]
                    } else if isUpcomingSoon {
                        // Amber/orange for upcoming soon
                        eventAttributes = [
                            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                            .foregroundColor: NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
                        ]
                    } else if isPast {
                        // Muted for past events
                        eventAttributes = [
                            .font: NSFont.systemFont(ofSize: 12),
                            .foregroundColor: NSColor.tertiaryLabelColor
                        ]
                    } else {
                        // Default label color
                        eventAttributes = [
                            .font: NSFont.systemFont(ofSize: 12),
                            .foregroundColor: NSColor.labelColor
                        ]
                    }
                    eventItem.attributedTitle = NSAttributedString(string: displayTitle, attributes: eventAttributes)

                    menu.addItem(eventItem)
                    eventCount += 1
                }
            }

            // Break out of date loop if we've hit the limit
            if hasMoreEvents {
                break
            }

            // Add separator after each date section (except the last one)
            if index < sortedDates.count - 1 && eventCount < maxEvents {
                menu.addItem(NSMenuItem.separator())
            }
        }

        // Show "more events" indicator if needed
        if hasMoreEvents {
            let moreItem = NSMenuItem(title: "  Show all events in Calendar...", action: #selector(openCalendar), keyEquivalent: "")
            moreItem.target = self
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            moreItem.attributedTitle = NSAttributedString(string: "  +more events... (open Calendar)", attributes: moreAttributes)
            menu.addItem(moreItem)
        }

        // Final separator before settings
        menu.addItem(NSMenuItem.separator())
    }

    private func addSettingsSection(to menu: NSMenu) {
        // Settings menu item with icon
        let settingsIcon = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: "Settings")
        settingsIcon?.isTemplate = true

        let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsMenuItem.image = settingsIcon
        let settingsSubmenu = NSMenu(title: "Settings")

        // Always show next event toggle
        let alwaysShowNextEvent = UserDefaults.standard.bool(forKey: UserDefaultsKeys.alwaysShowNextEvent)
        let toggleIcon = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "Menu bar")
        toggleIcon?.isTemplate = true

        let toggleItem = NSMenuItem(
            title: "Always show next event",
            action: #selector(toggleAlwaysShowNextEvent(_:)),
            keyEquivalent: ""
        )
        toggleItem.state = alwaysShowNextEvent ? .on : .off
        toggleItem.target = self
        toggleItem.image = toggleIcon
        settingsSubmenu.addItem(toggleItem)

        // Show past events for today toggle
        let showPastEvents = UserDefaults.standard.bool(forKey: UserDefaultsKeys.showPastEventsForToday)
        let pastEventsIcon = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: "Past events")
        pastEventsIcon?.isTemplate = true

        let showPastEventsItem = NSMenuItem(
            title: "Show past events for today",
            action: #selector(toggleShowPastEvents(_:)),
            keyEquivalent: ""
        )
        showPastEventsItem.state = showPastEvents ? .on : .off
        showPastEventsItem.target = self
        showPastEventsItem.image = pastEventsIcon
        settingsSubmenu.addItem(showPastEventsItem)

        // Separator before reset onboarding
        settingsSubmenu.addItem(NSMenuItem.separator())

        // Reset onboarding item
        let guideIcon = NSImage(systemSymbolName: "book.circle", accessibilityDescription: "Guide")
        guideIcon?.isTemplate = true

        let resetOnboardingItem = NSMenuItem(
            title: "Show Welcome Guide...",
            action: #selector(resetOnboarding),
            keyEquivalent: ""
        )
        resetOnboardingItem.target = self
        resetOnboardingItem.image = guideIcon
        settingsSubmenu.addItem(resetOnboardingItem)

        settingsMenuItem.submenu = settingsSubmenu
        menu.addItem(settingsMenuItem)
    }

    private func addBottomSection(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())

        // Refresh menu item
        let refreshIcon = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")
        refreshIcon?.isTemplate = true
        let refreshItem = NSMenuItem(title: "Refresh Events", action: #selector(refreshMenu), keyEquivalent: "r")
        refreshItem.target = self
        refreshItem.image = refreshIcon
        menu.addItem(refreshItem)

        // Show/Hide Widget menu item
        let widgetIcon = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Widget")
        widgetIcon?.isTemplate = true
        let widgetItem = NSMenuItem(title: "Toggle Desktop Widget", action: #selector(toggleWidget), keyEquivalent: "w")
        widgetItem.target = self
        widgetItem.image = widgetIcon
        menu.addItem(widgetItem)

        menu.addItem(NSMenuItem.separator())

        // Check for Updates menu item
        let updateIcon = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Update")
        updateIcon?.isTemplate = true
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        updateItem.image = updateIcon
        menu.addItem(updateItem)

        // About menu item
        let aboutIcon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")
        aboutIcon?.isTemplate = true
        let aboutItem = NSMenuItem(title: "About HeadsUp", action: #selector(showAboutWindow), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.image = aboutIcon
        menu.addItem(aboutItem)

        // Quit menu item
        let quitIcon = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")
        quitIcon?.isTemplate = true
        let quitItem = NSMenuItem(title: "Quit HeadsUp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = quitIcon
        menu.addItem(quitItem)
    }

    // MARK: - Action Handlers
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
