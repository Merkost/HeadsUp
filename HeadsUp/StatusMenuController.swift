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
        let eventsByDate = calendarService.fetchUpcomingEvents()
        let sortedDates = eventsByDate.keys.sorted()

        // Add events section
        if sortedDates.isEmpty {
            addNoEventsItem(to: menu)
        } else {
            addEventItems(to: menu, eventsByDate: eventsByDate, sortedDates: sortedDates)
        }
        
        // Add settings section
        addSettingsSection(to: menu)

        // Add bottom section (About, Quit)
        addBottomSection(to: menu)

        // Attach menu to status item
        statusItem.menu = menu
    }

    // MARK: - Menu Building Helpers
    private func addNoEventsItem(to menu: NSMenu) {
        let noEventsItem = NSMenuItem(title: "No upcoming events", action: nil, keyEquivalent: "")
        noEventsItem.isEnabled = false
        menu.addItem(noEventsItem)
    }

    private func addEventItems(to menu: NSMenu, eventsByDate: [Date: [EKEvent]], sortedDates: [Date]) {
        for date in sortedDates {
            // Add date header
            let dateString = TimeFormatter.formatFullDate(date)
            let dateItem = NSMenuItem(title: dateString, action: nil, keyEquivalent: "")
            dateItem.isEnabled = false
            menu.addItem(dateItem)

            // Add events for this date
            if let events = eventsByDate[date] {
                for event in events {
                    let timeString = TimeFormatter.formatTime(event.startDate)
                    let eventTitle = "\(timeString) - \(event.title ?? "No Title")"
                    let eventItem = NSMenuItem(title: eventTitle, action: #selector(eventSelected(_:)), keyEquivalent: "")
                    eventItem.representedObject = event
                    eventItem.target = self
                    menu.addItem(eventItem)
                }
            }
            menu.addItem(NSMenuItem.separator())
        }
    }

    private func addSettingsSection(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())

        let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu(title: "Settings")

        // Always show next event toggle
        let alwaysShowNextEvent = UserDefaults.standard.bool(forKey: UserDefaultsKeys.alwaysShowNextEvent)
        let toggleItem = NSMenuItem(
            title: "Always show next event",
            action: #selector(toggleAlwaysShowNextEvent(_:)),
            keyEquivalent: ""
        )
        toggleItem.state = alwaysShowNextEvent ? .on : .off
        toggleItem.target = self
        settingsSubmenu.addItem(toggleItem)

        // Show past events for today toggle
        let showPastEvents = UserDefaults.standard.bool(forKey: UserDefaultsKeys.showPastEventsForToday)
        let showPastEventsItem = NSMenuItem(
            title: "Show past events for today",
            action: #selector(toggleShowPastEvents(_:)),
            keyEquivalent: ""
        )
        showPastEventsItem.state = showPastEvents ? .on : .off
        showPastEventsItem.target = self
        settingsSubmenu.addItem(showPastEventsItem)

        // Separator before reset onboarding
        settingsSubmenu.addItem(NSMenuItem.separator())

        // Reset onboarding item
        let resetOnboardingItem = NSMenuItem(
            title: "Show Welcome Guide...",
            action: #selector(resetOnboarding),
            keyEquivalent: ""
        )
        resetOnboardingItem.target = self
        settingsSubmenu.addItem(resetOnboardingItem)

        settingsMenuItem.submenu = settingsSubmenu
        menu.addItem(settingsMenuItem)
    }

    private func addBottomSection(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())

        // Show/Hide Widget menu item
        let widgetItem = NSMenuItem(title: "Toggle Desktop Widget", action: #selector(toggleWidget), keyEquivalent: "w")
        widgetItem.target = self
        menu.addItem(widgetItem)

        menu.addItem(NSMenuItem.separator())

        // About menu item
        let aboutItem = NSMenuItem(title: "About HeadsUp", action: #selector(showAboutWindow), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit menu item
        let quitItem = NSMenuItem(title: "Quit HeadsUp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
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

    @objc func showAboutWindow() {
        let alert = NSAlert()
        alert.messageText = "About HeadsUp"
        alert.informativeText = """
        HeadsUp helps you stay on top of your meetings by displaying them in your menu bar \
        and alerting you before they start.

        Version 0.2.0

        Features:
        • Menu bar countdown to next meeting
        • Fullscreen alerts before meetings start
        • Desktop widget for at-a-glance view
        • Meeting link detection and quick join

        Created by Konstantin Merenkov
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
