// StatusMenuController.swift

import Cocoa
import EventKit

class StatusMenuController: NSObject {
    private let statusItem: NSStatusItem
    private let eventStore: EKEventStore
    private weak var appDelegate: AppDelegate?
    
    init(statusItem: NSStatusItem, eventStore: EKEventStore, appDelegate: AppDelegate) {
        self.statusItem = statusItem
        self.eventStore = eventStore
        self.appDelegate = appDelegate
        super.init()
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        let eventsByDate = fetchUpcomingEvents()
        let sortedDates = eventsByDate.keys.sorted()
        
        if sortedDates.isEmpty {
            let noEventsItem = NSMenuItem(title: "No more events", action: nil, keyEquivalent: "")
            noEventsItem.isEnabled = false
            menu.addItem(noEventsItem)
        } else {
            for date in sortedDates {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .full
                let dateString = dateFormatter.string(from: date)
                
                let dateItem = NSMenuItem(title: dateString, action: nil, keyEquivalent: "")
                dateItem.isEnabled = false
                menu.addItem(dateItem)
                
                if let events = eventsByDate[date] {
                    for event in events {
                        let timeFormatter = DateFormatter()
                        timeFormatter.timeStyle = .short
                        let timeString = timeFormatter.string(from: event.startDate)
                        
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
        
        // Separator before Settings
        menu.addItem(NSMenuItem.separator())

        // Settings Menu Item with Submenu
        let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu(title: "Settings")

        // Toggle for always showing the next event
        let alwaysShowNextEvent = UserDefaults.standard.bool(forKey: "AlwaysShowNextEvent")
        let toggleTitle = "Always show next event"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleAlwaysShowNextEvent(_:)), keyEquivalent: "")
        toggleItem.state = alwaysShowNextEvent ? .on : .off
        toggleItem.target = self
        settingsSubmenu.addItem(toggleItem)

        // **Add the new setting: Show past events for today**
        let showPastEvents = UserDefaults.standard.bool(forKey: "ShowPastEventsForToday")
        let showPastEventsTitle = "Show past events for today"
        let showPastEventsItem = NSMenuItem(title: showPastEventsTitle, action: #selector(toggleShowPastEvents(_:)), keyEquivalent: "")
        showPastEventsItem.state = showPastEvents ? .on : .off
        showPastEventsItem.target = self
        settingsSubmenu.addItem(showPastEventsItem)

        // Assign the submenu to the Settings menu item
        settingsMenuItem.submenu = settingsSubmenu
        menu.addItem(settingsMenuItem)

        // Separator before About and Quit
        menu.addItem(NSMenuItem.separator())

        // About Menu Item
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAboutWindow), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit Menu Item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        // Attach the menu to the status item
        statusItem.menu = menu
    }

    // **Add the new toggle action**
    @objc func toggleShowPastEvents(_ sender: NSMenuItem) {
        let currentSetting = UserDefaults.standard.bool(forKey: "ShowPastEventsForToday")
        let newSetting = !currentSetting
        UserDefaults.standard.set(newSetting, forKey: "ShowPastEventsForToday")
        sender.state = newSetting ? .on : .off
        // Refresh the menu to show/hide past events
        setupMenu()
    }

    // **Existing methods: eventSelected(_:), toggleAlwaysShowNextEvent(_:), showAboutWindow()**

    @objc func eventSelected(_ sender: NSMenuItem) {
        if let event = sender.representedObject as? EKEvent {
            // Show the fullscreen alert for the selected event
            appDelegate?.showFullscreenAlert(for: event)
        }
    }
    
    @objc func toggleAlwaysShowNextEvent(_ sender: NSMenuItem) {
        let currentSetting = UserDefaults.standard.bool(forKey: "AlwaysShowNextEvent")
        let newSetting = !currentSetting
        UserDefaults.standard.set(newSetting, forKey: "AlwaysShowNextEvent")
        sender.state = newSetting ? .on : .off
        appDelegate?.updateStatusItemTitle()
    }
    
    @objc func showAboutWindow() {
            let alert = NSAlert()
            alert.messageText = "About InTheMeeting"
            alert.informativeText = "InTheMeeting is a free macOS application that displays your upcoming meetings and reminders.\n\nVersion 0.1.0"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
    private func fetchUpcomingEvents() -> [Date: [EKEvent]] {
        var eventsByDate = [Date: [EKEvent]]()
        let calendars = eventStore.calendars(for: .event)
        
        let startDate = Date()
        var endDate: Date
        let showPastEvents = UserDefaults.standard.bool(forKey: "ShowPastEventsForToday")
        
        if showPastEvents {
            // Include past events for today
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        } else {
            // Only upcoming events
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            // Determine if the event should be included based on the setting
            if !showPastEvents {
                if event.endDate < startDate {
                    continue // Skip past events
                }
            } else {
                // If showing past events, include all events from the start date
                // Optionally, you can further filter to only include past events from today
                // For now, include all
            }
            
            let eventDate = Calendar.current.startOfDay(for: event.startDate)
            if eventsByDate[eventDate] != nil {
                eventsByDate[eventDate]?.append(event)
            } else {
                eventsByDate[eventDate] = [event]
            }
        }
        return eventsByDate
    }
}
