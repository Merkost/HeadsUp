//
//  MeetingMenuBarExtra.swift
//  InTheMeeting
//
//  Created by Konstantin Merenkov on 15.10.2024.
//


import SwiftUI

@available(macOS 13.0, *)
struct MeetingMenuBarExtra: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Meetings", systemImage: "calendar") {
            MeetingListView()
        }
    }
}

struct MeetingListView: View {
    let eventsByDate = AppDelegate().fetchUpcomingEvents()
    let sortedDates: [Date]

    init() {
        sortedDates = eventsByDate.keys.sorted()
    }

    var body: some View {
        ForEach(sortedDates, id: \.self) { date in
            Text(date, style: .date)
                .font(.headline)
            if let events = eventsByDate[date] {
                ForEach(events, id: \.eventIdentifier) { event in
                    Button(action: {
                        // Handle event selection
                    }) {
                        HStack {
                            Text(event.title ?? "No Title")
                            Spacer()
                            Text(event.startDate, style: .time)
                        }
                    }
                }
            }
            Divider()
        }
    }
}
