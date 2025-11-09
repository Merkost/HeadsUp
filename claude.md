# HeadsUp - Application Architecture

## Overview
HeadsUp is a macOS menu bar application that helps users stay on top of their calendar events by displaying upcoming meetings, providing countdown timers, and showing fullscreen alerts before meetings start. The app integrates with macOS Calendar (EventKit) and can automatically extract meeting links from various platforms.

## Technology Stack
- **Language**: Swift
- **UI Framework**: SwiftUI + AppKit (Hybrid)
- **Platform**: macOS 13.0+
- **Key Frameworks**:
  - EventKit (Calendar integration)
  - Cocoa/AppKit (Menu bar and alerts)
  - SwiftUI (Modern UI components)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        HeadsUp App                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐        ┌──────────────────────────┐      │
│  │ HeadsUpApp   │───────▶│     AppDelegate          │      │
│  │  (Entry)     │        │  - Calendar Access       │      │
│  └──────────────┘        │  - Timer Management      │      │
│                          │  - Event Monitoring      │      │
│                          └────────┬─────────────────┘      │
│                                   │                         │
│         ┌─────────────────────────┼────────────────┐        │
│         │                         │                │        │
│         ▼                         ▼                ▼        │
│  ┌──────────────┐      ┌──────────────┐  ┌─────────────┐   │
│  │StatusMenu    │      │AlertView     │  │EventKit     │   │
│  │Controller    │      │Controller    │  │Integration  │   │
│  │- Menu Items  │      │- Fullscreen  │  │             │   │
│  │- Settings    │      │- Countdown   │  │             │   │
│  └──────┬───────┘      └──────────────┘  └─────────────┘   │
│         │                      │                            │
│         ▼                      ▼                            │
│  ┌──────────────────────────────────────┐                  │
│  │     MeetingLinkExtractor             │                  │
│  │  - URL Pattern Matching              │                  │
│  │  - Multi-platform Support            │                  │
│  └──────────────────────────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. HeadsUpApp (`HeadsUpApp.swift`)
**Responsibility**: Application entry point
- SwiftUI-based `@main` app structure
- Delegates to `AppDelegate` for core functionality
- Minimal Settings scene (currently empty)

### 2. AppDelegate (`AppDelegate.swift`)
**Responsibility**: Core application logic and orchestration
- **Calendar Access**: Requests and manages EventKit permissions
- **Timer Management**:
  - Updates menu bar every minute
  - Checks for upcoming meetings
  - Triggers alerts 60 seconds before meetings
- **Event Monitoring**: Fetches and tracks upcoming events
- **UI Coordination**: Manages status bar item and fullscreen alerts

**Key Methods**:
- `requestCalendarAccess()`: Handles EventKit authorization
- `fetchUpcomingEvents()`: Retrieves events for next 7 days
- `checkForUpcomingMeetings()`: Monitors for meetings starting soon
- `showFullscreenAlert(for:)`: Displays meeting alerts
- `updateStatusItemTitle()`: Updates menu bar text with next event info

**User Preferences**:
- `AlwaysShowNextEvent`: Show next event regardless of date
- `ShowPastEventsForToday`: Include past events from today

### 3. StatusMenuController (`StatusMenuController.swift`)
**Responsibility**: Menu bar dropdown UI
- Displays upcoming events grouped by date
- Provides settings submenu with toggles
- Shows About dialog
- Handles event selection to trigger alerts

**Features**:
- Date-grouped event list
- Time display for each event
- Settings toggles (checkboxes)
- Event click handling

### 4. AlertViewController (`AlertViewController.swift`)
**Responsibility**: Fullscreen meeting notification
- Borderless, fullscreen window at screen saver level
- Dark visual effect background
- Real-time countdown timer
- Meeting action buttons

**UI Elements**:
- Event title (48pt, bold)
- Time range (24pt)
- Countdown/elapsed timer (36pt, monospaced)
- Action buttons:
  - **Join Meeting**: Opens meeting link
  - **Open in Calendar**: Opens event in Calendar.app
  - **Skip**: Dismisses alert

**Interactions**:
- Click outside dialog to dismiss
- ESC key to close
- Fade-in animation on appearance

### 5. MeetingLinkExtractor (`MeetingLinkExtractor.swift`)
**Responsibility**: Extract meeting URLs from calendar events
- Singleton pattern for shared access
- Regex-based URL extraction
- Multi-platform support

**Supported Platforms**:
- Zoom
- Google Meet
- Microsoft Teams
- Webex
- GoToMeeting/GoToWebinar
- BlueJeans
- Amazon Chime
- RingCentral
- Join.me
- Cisco
- 8x8

**Strategy**:
1. Check event URL field first
2. Fall back to notes field
3. Match against platform-specific regex patterns

### 6. EventButton (`EventButton.swift`)
**Responsibility**: Custom button with event reference
- Simple `NSButton` subclass
- Holds reference to associated `EKEvent`
- Currently minimal implementation

### 7. MeetingMenuBarExtra (`MeetingMenuBarExtra.swift`)
**Responsibility**: Alternative menu bar implementation
- SwiftUI-based MenuBarExtra (macOS 13+)
- Alternative to AppDelegate approach
- **Note**: Not currently used in app

## Data Flow

### Event Fetching Flow
```
User Opens Menu
      │
      ▼
StatusMenuController.setupMenu()
      │
      ▼
fetchUpcomingEvents()
      │
      ▼
EventStore.events(matching: predicate)
      │
      ▼
Group by date → Display in menu
```

### Alert Trigger Flow
```
Timer fires every minute
      │
      ▼
checkForUpcomingMeetings()
      │
      ▼
Find events starting in ~60s
      │
      ▼
showFullscreenAlert(for: event)
      │
      ▼
AlertViewController displays
      │
      ▼
User action (Join/Open/Skip)
```

### Meeting Join Flow
```
User clicks "Join Meeting"
      │
      ▼
MeetingLinkExtractor.getMeetingLink(from: event)
      │
      ├─▶ Check event.url
      │
      └─▶ Check event.notes for URL
      │
      ▼
NSWorkspace.shared.open(url)
```

## File Structure
```
HeadsUp/
├── HeadsUpApp.swift              # App entry point
├── AppDelegate.swift             # Core logic & coordination
├── StatusMenuController.swift    # Menu bar UI
├── AlertViewController.swift     # Fullscreen alert UI
├── MeetingLinkExtractor.swift   # URL extraction utility
├── EventButton.swift             # Custom button component
├── MeetingMenuBarExtra.swift    # Unused alternative menu bar
├── ContentView.swift             # Unused default SwiftUI view
└── Assets.xcassets/             # App icons and colors
```

## State Management

### Application State
- **Status Bar**: Dynamically updated with next event countdown
- **Timer State**: 60-second interval timer for monitoring
- **Window State**: Fullscreen alert window (retained reference)
- **User Preferences**: UserDefaults for settings persistence

### Event State
- **Fetched on demand**: No persistent event cache
- **7-day window**: Events from now to +7 days
- **Sorted by date**: Grouped by day for display

## UI/UX Patterns

### Menu Bar Icon States
1. **Calendar icon only**: No upcoming events or outside display window
2. **Event title + countdown**: Shows next event timing

### Alert Display Logic
- Triggered 60 seconds before event start
- Remains visible until user action
- Can be dismissed by:
  - Clicking action buttons
  - Pressing ESC key
  - Clicking outside dialog

### Settings Persistence
- Boolean toggles stored in UserDefaults
- Default values registered on app launch
- Changes take effect immediately

## Key Design Decisions

### Why AppDelegate Pattern?
- Required for menu bar app (NSStatusItem)
- Better control over lifecycle
- SwiftUI `MenuBarExtra` available but not used (alternative in codebase)

### Why Hybrid SwiftUI/AppKit?
- SwiftUI for modern app structure
- AppKit for mature menu bar and window APIs
- Cocoa for EventKit integration

### Why Fullscreen Alerts?
- Impossible to miss important meetings
- Distraction-free notification
- Quick actions readily available

### Why 60-second Warning?
- Balance between notice and annoyance
- Enough time to prepare/join
- Not so early that users forget

## Extension Points

### Adding New Meeting Platforms
1. Add regex pattern to `MeetingLinkExtractor.patterns`
2. Test with sample event notes
3. Pattern should match platform-specific URL structure

### Adding New Settings
1. Register default in `AppDelegate.registerDefaultSettings()`
2. Add menu item in `StatusMenuController.setupMenu()`
3. Add toggle handler method
4. Update relevant logic to check setting

### Customizing Alert UI
- Modify `AlertViewController.setupUI()` for layout changes
- Adjust colors, fonts, or button styles
- Add new action buttons as needed

## Performance Considerations

### Timer Efficiency
- Updates only on minute boundaries (not every second)
- Invalidates and recreates on app lifecycle events
- Synchronized to system clock

### Event Fetching
- Limited 7-day window
- No continuous polling (event-driven updates)
- Fetches on menu open (lazy loading)

### Memory Management
- Weak references to avoid retain cycles
- Windows released when closed
- Timer invalidation on cleanup

## Security & Privacy

### Calendar Permissions
- Requests full access to events
- Graceful degradation if denied
- Guides user to System Preferences

### Data Handling
- No event data stored persistently
- No network requests (local calendar only)
- Meeting links opened in default browser

## Future Enhancements

### Potential Features
1. **Widget Support**: macOS desktop widget for at-a-glance view
2. **Custom Alert Times**: User-configurable warning intervals
3. **Multiple Alerts**: Support for multiple time-based alerts
4. **Meeting Preparation**: Show event notes/attachments
5. **Quick Actions**: Snooze, reschedule from alert
6. **Focus Mode Integration**: Auto-enable Do Not Disturb
7. **Meeting Analytics**: Track meeting time/frequency
8. **Multi-Calendar Support**: Filter by specific calendars

### Code Quality Improvements
1. **Separation of Concerns**: Extract EventStore into separate service
2. **Dependency Injection**: Make dependencies explicit
3. **Testing**: Add unit tests for link extraction, formatting
4. **Error Handling**: More robust error states and recovery
5. **Localization**: Support multiple languages
6. **Accessibility**: VoiceOver support, keyboard navigation

## Development Guidelines

### Code Style
- Swift naming conventions (camelCase, PascalCase for types)
- Explicit types for public APIs
- Comments for complex logic
- `// MARK:` sections for organization

### Testing Approach
- Test link extraction with various URL formats
- Verify timer accuracy
- Check permission edge cases
- Validate UI across different screen sizes

### Debugging
- Print statements for timer events
- Check UserDefaults for setting issues
- Verify EventKit authorization status
- Monitor console for regex errors

## Dependencies
- **System Frameworks Only**: No third-party dependencies
- **Minimum macOS Version**: 13.0 (Ventura)
- **Swift Version**: Swift 5.x (Xcode default)

## Build Configuration
- **Target**: macOS application
- **Bundle ID**: com.konstantin.HeadsUp
- **Deployment Target**: macOS 13.0+
- **Architecture**: Universal (Apple Silicon + Intel)

---

**Last Updated**: 2025-11-09
**Version**: 0.1.0
**Author**: Konstantin Merenkov
