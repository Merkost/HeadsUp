//
//  MeetingWidgetView.swift
//  HeadsUp
//
//  Desktop widget view for displaying upcoming meetings
//

import SwiftUI
import EventKit

// MARK: - Meeting Widget View
struct MeetingWidgetView: View {
    @State private var nextEvent: EKEvent?
    @State private var upcomingEvents: [EKEvent] = []
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let calendarService = CalendarService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("HeadsUp")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(currentTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            Divider()

            // Next Event Section
            if let event = nextEvent {
                nextEventCard(event)
            } else {
                noEventsView
            }

            // Upcoming Events List
            if !upcomingEvents.isEmpty {
                Divider()
                upcomingEventsSection
            }
        }
        .padding(20)
        .frame(width: 350)
        .background(backgroundView)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear(perform: loadEvents)
        .onReceive(timer) { _ in
            currentTime = Date()
            loadEvents()
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
        }
    }

    // MARK: - Next Event Card
    @ViewBuilder
    private func nextEventCard(_ event: EKEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Meeting")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text(event.title ?? "No Title")
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(2)

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(TimeFormatter.formatTimeRange(startDate: event.startDate, endDate: event.endDate))
                    .font(.subheadline)
            }

            if let countdown = getCountdown(for: event) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text(countdown)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Meeting link button
            if MeetingLinkExtractor.shared.getMeetingLink(from: event) != nil {
                Button(action: {
                    joinMeeting(event)
                }) {
                    HStack {
                        Image(systemName: "video")
                        Text("Join Meeting")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - No Events View
    private var noEventsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No upcoming meetings")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Enjoy your free time!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Upcoming Events Section
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ForEach(upcomingEvents.prefix(3), id: \.eventIdentifier) { event in
                upcomingEventRow(event)
            }
        }
    }

    // MARK: - Upcoming Event Row
    @ViewBuilder
    private func upcomingEventRow(_ event: EKEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Text(event.startDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "No Title")
                    .font(.subheadline)
                    .lineLimit(1)

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper Methods
    private func loadEvents() {
        nextEvent = calendarService.getNextEvent()

        let eventsByDate = calendarService.fetchUpcomingEvents(daysAhead: 1)
        var allEvents: [EKEvent] = []
        for (_, events) in eventsByDate {
            allEvents.append(contentsOf: events)
        }
        upcomingEvents = allEvents.sorted { $0.startDate < $1.startDate }
            .filter { $0.startDate > Date() }
    }

    private func getCountdown(for event: EKEvent) -> String? {
        let now = Date()

        if now >= event.startDate && now <= event.endDate {
            // Meeting in progress
            let timeInterval = event.endDate.timeIntervalSince(now)
            return "Ends in \(TimeFormatter.formatTimeInterval(timeInterval))"
        } else if now < event.startDate {
            // Upcoming meeting
            let timeInterval = event.startDate.timeIntervalSince(now)
            return "Starts in \(TimeFormatter.formatTimeInterval(timeInterval))"
        }
        return nil
    }

    private func joinMeeting(_ event: EKEvent) {
        if let url = MeetingLinkExtractor.shared.getMeetingLink(from: event) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Visual Effect Blur
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview
#Preview {
    MeetingWidgetView()
        .frame(width: 350)
}
