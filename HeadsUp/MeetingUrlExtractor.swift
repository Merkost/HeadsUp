//
//  MeetingLinkExtractor.swift
//  InTheMeeting
//
//  Created by Konstantin Merenkov on 15.10.2024.
//


// MeetingLinkExtractor.swift

import Foundation
import EventKit

class MeetingLinkExtractor {
    
    static let shared = MeetingLinkExtractor()
    
    private init() {}
    
    /// Extracts a meeting link from the given EKEvent.
    func getMeetingLink(from event: EKEvent) -> URL? {
        // Check event URL
        if let url = event.url {
            return url
        }
        // Check notes for a meeting link
        if let notes = event.notes {
            if let url = extractURL(from: notes) {
                return url
            }
        }
        return nil
    }
    
    /// Extracts a URL from the given text using predefined patterns.
    private func extractURL(from text: String) -> URL? {
        // Patterns for different meeting platforms
        let patterns = [
            "https?://[a-zA-Z0-9./?&=-]*zoom\\.us/[a-zA-Z0-9./?&=-]+",
            "https?://meet\\.google\\.com/[a-zA-Z0-9?&=-]+",
            "https?://teams\\.microsoft\\.com/l/meetup-join/[a-zA-Z0-9?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*webex\\.com/[a-zA-Z0-9./?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*gotomeeting\\.com/join/[a-zA-Z0-9?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*gotowebinar\\.com/join/[a-zA-Z0-9?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*bluejeans\\.com/[a-zA-Z0-9?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*chime\\.aws/[a-zA-Z0-9?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*ringcentral\\.com/[a-zA-Z0-9./?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*join\\.me/[a-zA-Z0-9./?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*cisco\\.com/[a-zA-Z0-9./?&=-]+",
            "https?://[a-zA-Z0-9./?&=-]*8x8\\.vc/[a-zA-Z0-9./?&=-]+"
            // Add more patterns as needed
        ]
        
        for pattern in patterns {
            if let url = matchPattern(in: text, pattern: pattern) {
                return url
            }
        }
        return nil
    }
    
    /// Helper method to perform regex matching.
    private func matchPattern(in text: String, pattern: String) -> URL? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            if let match = matches.first, let range = Range(match.range, in: text) {
                let urlString = String(text[range])
                return URL(string: urlString)
            }
        } catch {
            print("Invalid regex pattern: \(pattern)")
        }
        return nil
    }
}