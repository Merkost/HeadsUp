//
//  CalendarService.swift
//  HeadsUp
//
//  Service for managing calendar event access and queries
//

import Foundation
import EventKit

// MARK: - Calendar Service Protocol
protocol CalendarServiceProtocol {
    func requestAccess(completion: @escaping (Bool, Error?) -> Void)
    func fetchUpcomingEvents(daysAhead: Int) -> [Date: [EKEvent]]
    func getNextEvent() -> EKEvent?
    func getEventsStartingSoon(timeWindow: TimeInterval) -> [EKEvent]
}

// MARK: - Calendar Service Implementation
class CalendarService: CalendarServiceProtocol {

    // MARK: - Properties
    static let shared = CalendarService()
    private let eventStore = EKEventStore()

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Requests full access to calendar events
    /// - Parameter completion: Callback with grant status and optional error
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }

    /// Fetches upcoming events grouped by date
    /// - Parameter daysAhead: Number of days to look ahead (default: 7)
    /// - Returns: Dictionary of events grouped by date
    func fetchUpcomingEvents(daysAhead: Int = 7) -> [Date: [EKEvent]] {
        var eventsByDate = [Date: [EKEvent]]()
        let calendars = eventStore.calendars(for: .event)
        let now = Date()

        // Start from beginning of today to catch ongoing events
        let startOfToday = Calendar.current.startOfDay(for: now)
        guard let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: now) else {
            return eventsByDate
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfToday, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        // Get user preference for showing past events (only for today)
        let showPastEventsForToday = UserDefaults.standard.bool(forKey: UserDefaultsKeys.showPastEventsForToday)
        let calendar = Calendar.current

        for event in events {
            let isToday = calendar.isDateInToday(event.startDate)
            let isPast = event.endDate < now

            // Skip past events from previous days entirely
            if !isToday && isPast {
                continue
            }

            // For today's events: skip past events if setting is disabled
            if isToday && isPast && !showPastEventsForToday {
                continue
            }

            let eventDate = calendar.startOfDay(for: event.startDate)
            if eventsByDate[eventDate] != nil {
                eventsByDate[eventDate]?.append(event)
            } else {
                eventsByDate[eventDate] = [event]
            }
        }

        return eventsByDate
    }

    /// Gets the next upcoming event (or current ongoing event)
    /// - Returns: Next event or nil if none found
    func getNextEvent() -> EKEvent? {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        guard let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now) else {
            return nil
        }

        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        // Return first event that hasn't ended yet (includes ongoing events)
        return events.first { $0.endDate >= now }
    }

    /// Gets events starting within a specific time window
    /// - Parameter timeWindow: Time interval from now (e.g., 60 seconds)
    /// - Returns: Array of events starting within the time window
    func getEventsStartingSoon(timeWindow: TimeInterval = 60) -> [EKEvent] {
        let now = Date()
        let targetTime = now.addingTimeInterval(timeWindow)

        let predicate = eventStore.predicateForEvents(
            withStart: targetTime,
            end: targetTime.addingTimeInterval(1),
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        // Filter events that are starting very close to the target time
        return events.filter { event in
            let timeUntilStart = event.startDate.timeIntervalSince(now)
            return abs(timeUntilStart - timeWindow) < 1
        }
    }
}

// MARK: - User Defaults Keys
struct UserDefaultsKeys {
    static let alwaysShowNextEvent = "AlwaysShowNextEvent"
    static let showPastEventsForToday = "ShowPastEventsForToday"
    static let hasCompletedOnboarding = "HasCompletedOnboarding"
}
