//
//  TimeFormatter.swift
//  HeadsUp
//
//  Utility for formatting time intervals and dates
//

import Foundation

// MARK: - Time Formatter Utility
struct TimeFormatter {

    // MARK: - Public Methods

    /// Formats a time interval into a human-readable string (e.g., "2h 30m")
    /// - Parameter interval: Time interval in seconds
    /// - Returns: Formatted string
    static func formatTimeInterval(_ interval: TimeInterval) -> String {
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

    /// Formats a time interval for countdown display (e.g., "00:15:30")
    /// - Parameter interval: Time interval in seconds
    /// - Returns: Formatted countdown string
    static func formatCountdown(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: interval) ?? "00:00:00"
    }

    /// Truncates text to a maximum length with ellipsis
    /// - Parameters:
    ///   - text: Text to truncate
    ///   - maxLength: Maximum length (default: 10)
    /// - Returns: Truncated string
    static func truncateText(_ text: String, maxLength: Int = 10) -> String {
        if text.count > maxLength {
            let index = text.index(text.startIndex, offsetBy: maxLength - 1)
            return String(text[..<index]) + "…"
        }
        return text
    }

    /// Formats a date range as a string (e.g., "10:00 AM - 11:00 AM")
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Formatted time range string
    static func formatTimeRange(startDate: Date, endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startTime = formatter.string(from: startDate)
        let endTime = formatter.string(from: endDate)
        return "\(startTime) - \(endTime)"
    }

    /// Formats a date as a full date string (e.g., "Monday, November 9, 2025")
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string
    static func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    /// Formats a date as a short time string (e.g., "10:00 AM")
    /// - Parameter date: Date to format
    /// - Returns: Formatted time string
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
