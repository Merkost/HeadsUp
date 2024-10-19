//
//  AppDelegate.swift
//  InTheMeeting
//
//  Created by Konstantin Merenkov on 15.10.2024.
//


import Cocoa
import EventKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let eventStore = EKEventStore()
    var timer: Timer?
    var fullscreenWindow: NSWindow?
    var statusMenuController: StatusMenuController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaultSettings()
        requestCalendarAccess()
        setupStatusItem()
    }
    
    private func registerDefaultSettings() {
            let defaults: [String: Any] = [
                "AlwaysShowNextEvent": false,
                "ShowPastEventsForToday": false
            ]
            UserDefaults.standard.register(defaults: defaults)
        }
    
    func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents { (granted, error) in
            DispatchQueue.main.async {
                if granted {
                    print("Access granted to calendar")
                    self.setupStatusItem()
                    self.startMeetingAlertTimer()
                } else {
                    print("Access denied to calendar: \(error?.localizedDescription ?? "Unknown error")")
                    self.showAccessDeniedAlert(error: error)
                }
            }
        }
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
        }
        
        statusMenuController = StatusMenuController(statusItem: statusItem, eventStore: eventStore, appDelegate: self)
    }
    
    func showAccessDeniedAlert(error: Error?) {
        let alert = NSAlert()
        alert.messageText = "Calendar Access Required"
        alert.informativeText = "This application needs access to your calendar to display upcoming meetings. Please grant access in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Preferences
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                NSWorkspace.shared.open(url)
            }
        }
        NSApp.terminate(self)
    }
    
    func fetchUpcomingEvents() -> [Date: [EKEvent]] {
        var eventsByDate = [Date: [EKEvent]]()
        let calendars = eventStore.calendars(for: .event)
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            let eventDate = Calendar.current.startOfDay(for: event.startDate)
            if eventsByDate[eventDate] != nil {
                eventsByDate[eventDate]?.append(event)
            } else {
                eventsByDate[eventDate] = [event]
            }
        }
        return eventsByDate
    }
    
    @objc func checkForUpcomingMeetings() {
        let now = Date()
        let oneMinuteFromNow = now.addingTimeInterval(60)
        
        let predicate = eventStore.predicateForEvents(withStart: oneMinuteFromNow, end: oneMinuteFromNow.addingTimeInterval(1), calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        print("Checking for meetings starting at \(oneMinuteFromNow)")
        
        for event in events {
            let timeUntilStart = event.startDate.timeIntervalSince(now)
            if abs(timeUntilStart - 60) < 1 {
                print("Upcoming meeting found: \(event.title ?? "No Title") starting in 60 seconds")
                showFullscreenAlert(for: event)
            }
        }
    }
        
    func showFullscreenAlert(for event: EKEvent) {
        DispatchQueue.main.async {
            let screenFrame = NSScreen.main?.frame ?? NSRect.zero
            let window = NSWindow(contentRect: screenFrame,
                                  styleMask: [.borderless],
                                  backing: .buffered,
                                  defer: false)
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = NSColor.clear
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
            window.acceptsMouseMovedEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            
            // Create and assign the view controller
            let alertViewController = AlertViewController()
            alertViewController.event = event
            window.contentViewController = alertViewController
            
            // Retain the window
            self.fullscreenWindow = window
        }
    }
        
    func updateStatusItemTitle() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let nextEvent = self.getNextEvent() {
                let now = Date()
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: now)
                let eventDay = calendar.startOfDay(for: nextEvent.startDate)
                
                // Get user preference
                let alwaysShowNextEvent = UserDefaults.standard.bool(forKey: "AlwaysShowNextEvent")
                
                // Check if we should display the next event
                if alwaysShowNextEvent || eventDay == today {
                    if now >= nextEvent.startDate && now <= nextEvent.endDate {
                        // Meeting is currently in progress
                        let timeInterval = nextEvent.endDate.timeIntervalSince(now)
                        let formattedTime = self.formatTimeInterval(timeInterval)
                        let eventTitle = self.truncateEventTitle(nextEvent.title ?? "No Title")
                        self.statusItem.button?.title = "\(eventTitle) ends in \(formattedTime)"
                        self.statusItem.button?.image = nil
                    } else if now < nextEvent.startDate {
                        // Meeting is upcoming
                        let timeInterval = nextEvent.startDate.timeIntervalSince(now)
                        let formattedTime = self.formatTimeInterval(timeInterval)
                        let eventTitle = self.truncateEventTitle(nextEvent.title ?? "No Title")
                        self.statusItem.button?.title = "\(eventTitle) in \(formattedTime)"
                        self.statusItem.button?.image = nil
                    } else {
                        self.statusItem.button?.title = ""
                        self.statusItem.button?.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
                    }
                } else {
                    // Do not display the next event
                    self.statusItem.button?.title = ""
                    self.statusItem.button?.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
                }
            } else {
                // No upcoming events
                self.statusItem.button?.title = ""
                self.statusItem.button?.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
            }
        }
    }
        
        func truncateEventTitle(_ title: String, maxLength: Int = 10) -> String {
            if title.count > maxLength {
                let index = title.index(title.startIndex, offsetBy: maxLength - 1)
                return String(title[..<index]) + "…"
            } else {
                return title
            }
        }
        
    func getNextEvent() -> EKEvent? {
        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        return events.first { $0.startDate >= startDate }
    }
        
        func formatTimeInterval(_ interval: TimeInterval) -> String {
            let ti = Int(interval)
            let hours = ti / 3600
            let minutes = (ti % 3600) / 60
            
            var components = [String]()
            if hours > 0 {
                components.append("\(hours)h")
            }
            components.append("\(minutes)m")
            
            return components.joined(separator: " ")
        }
        
    func startMeetingAlertTimer() {
        timer?.invalidate()
        timer = nil
        
        updateTimerFired()
        
        let now = Date()
        let calendar = Calendar.current
        if let nextMinute = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .strict) {
            let timer = Timer(fireAt: nextMinute, interval: 60, target: self, selector: #selector(updateTimerFired), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
            print("Timer scheduled to start at \(nextMinute)")
        }
    }
        
        @objc func updateTimerFired() {
            checkForUpcomingMeetings()
            updateStatusItemTitle()
        }
        
    }

