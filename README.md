# HeadsUp

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/version-0.2.0-green.svg" alt="Version 0.2.0">
</p>

A beautiful macOS menu bar application that helps you stay on top of your meetings by displaying them in your menu bar, providing countdown timers, and alerting you before they start.

## Features

### 🎯 Core Features
- **Menu Bar Integration**: See your next meeting right in the menu bar with live countdown
- **Fullscreen Alerts**: Get notified 60 seconds before meetings with an elegant fullscreen alert
- **Desktop Widget**: Beautiful floating widget showing your upcoming meetings at a glance
- **One-Click Join**: Automatically detect and join meeting links from popular platforms
- **Calendar Integration**: Seamlessly integrates with macOS Calendar (EventKit)

### 🎨 Enhanced UI
- Modern, clean interface with visual effects and animations
- Dark mode support with adaptive materials
- Smooth transitions and hover effects
- Customizable display options

### 🔗 Supported Meeting Platforms
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

## Screenshots

### Menu Bar
The menu bar shows your next meeting with a countdown timer and provides quick access to all upcoming events.

### Fullscreen Alert
60 seconds before a meeting starts, a beautiful fullscreen alert appears with:
- Meeting title and time
- Live countdown timer
- Quick actions: Join Meeting, Open in Calendar, or Skip

### Desktop Widget
A floating widget that displays:
- Next meeting with countdown
- List of upcoming meetings
- Quick join buttons
- Always visible, never in the way

## Installation

### Requirements
- macOS 13.0 (Ventura) or later
- Calendar access permission

### Building from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/Merkost/HeadsUp.git
   cd HeadsUp
   ```

2. Open in Xcode:
   ```bash
   open HeadsUp.xcodeproj
   ```

3. Build and run (⌘R)

## Usage

### First Launch
1. Grant calendar access when prompted
2. The calendar icon will appear in your menu bar

### Menu Bar
- Click the menu bar icon to see all upcoming meetings
- The icon shows countdown to your next meeting (if enabled in settings)

### Settings
Access settings from the menu bar dropdown:
- **Always show next event**: Display the next meeting regardless of date
- **Show past events for today**: Include events that already happened today

### Desktop Widget
- Toggle the widget from the menu bar: `Toggle Desktop Widget` (⌘W)
- Drag to reposition anywhere on your screen
- Widget updates automatically every minute

### Meeting Alerts
- Alerts appear 60 seconds before meeting start time
- Press `ESC` or click outside to dismiss
- Click "Join Meeting" to open the meeting link
- Click "Open in Calendar" to view in Calendar.app

## Architecture

See [claude.md](claude.md) for detailed architecture documentation.

### Key Components

#### Services Layer
- **CalendarService**: Manages EventKit integration and event queries
- **MeetingLinkExtractor**: Detects and extracts meeting URLs from events

#### Utilities
- **TimeFormatter**: Handles all time and date formatting

#### Views
- **AppDelegate**: Core application logic and coordination
- **StatusMenuController**: Menu bar dropdown interface
- **AlertViewController**: Fullscreen meeting notification
- **MeetingWidgetView**: Desktop widget UI (SwiftUI)
- **WidgetWindowController**: Widget window management

## Development

### Project Structure
```
HeadsUp/
├── HeadsUpApp.swift              # App entry point
├── AppDelegate.swift             # Core application logic
├── StatusMenuController.swift    # Menu bar interface
├── AlertViewController.swift     # Fullscreen alert
├── Services/
│   └── CalendarService.swift    # Calendar integration
├── Utilities/
│   ├── TimeFormatter.swift      # Time formatting utilities
│   └── MeetingUrlExtractor.swift # URL extraction
└── Views/
    ├── MeetingWidgetView.swift  # Desktop widget (SwiftUI)
    └── WidgetWindowController.swift # Widget window
```

### Code Style
- MARK comments for organization
- Comprehensive documentation
- Separation of concerns
- Dependency injection where appropriate

### Recent Improvements (v0.2.0)
- ✅ Refactored code with service layer architecture
- ✅ Created CalendarService for better separation of concerns
- ✅ Added TimeFormatter utility for consistent formatting
- ✅ Enhanced UI with better styling and animations
- ✅ Created desktop widget for at-a-glance meeting view
- ✅ Improved error handling and user feedback
- ✅ Added comprehensive MARK comments and documentation
- ✅ Updated About dialog with feature list

## Privacy

HeadsUp respects your privacy:
- All data stays on your device
- No network requests (except opening meeting links)
- No analytics or tracking
- Calendar data is never stored permanently
- Only accesses calendar events when needed

## Permissions

HeadsUp requires the following permissions:
- **Calendar Access**: To read your upcoming meetings and events

## Roadmap

### Planned Features
- [ ] Custom alert timing (configurable warning intervals)
- [ ] Multiple alerts per meeting
- [ ] Meeting preparation checklist
- [ ] Focus Mode integration
- [ ] Meeting analytics and insights
- [ ] Multi-calendar filtering
- [ ] Custom meeting link patterns
- [ ] Keyboard shortcuts for common actions
- [ ] Export meeting data

### Code Quality
- [ ] Unit tests for services
- [ ] UI tests for critical flows
- [ ] Continuous integration
- [ ] Localization support
- [ ] Accessibility improvements

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Guidelines
1. Follow existing code style and conventions
2. Add MARK comments for organization
3. Update documentation for new features
4. Test thoroughly before submitting

## License

This project is available under the MIT License. See LICENSE file for details.

## Credits

Created by Konstantin Merenkov

## Support

If you find HeadsUp useful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs and issues
- 💡 Suggesting new features
- 🔀 Contributing code improvements

---

**Version**: 0.2.0
**Last Updated**: November 9, 2025
