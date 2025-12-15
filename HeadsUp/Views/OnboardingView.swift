//
//  OnboardingView.swift
//  HeadsUp
//
//  Multi-page onboarding flow for first-time users
//

import SwiftUI
import EventKit

// MARK: - Onboarding View
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var calendarAccessGranted = false
    @State private var showWidget = true
    @State private var alwaysShowNextEvent = false

    let onComplete: (OnboardingSettings) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Add top padding for title bar
            Spacer()
                .frame(height: 30)

            // Page content
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)

                calendarPermissionPage
                    .tag(1)

                settingsConfigurationPage
                    .tag(2)

                widgetIntroductionPage
                    .tag(3)

                completionPage
                    .tag(4)
            }
            .tabViewStyle(.automatic)

            // Navigation buttons
            navigationButtons
                .padding()
                .background(
                    Rectangle()
                        .fill(Material.bar)
                )
        }
        .frame(minWidth: 700, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Welcome to HeadsUp")
                .font(.system(size: 36, weight: .bold))

            Text("Never miss a meeting again")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "bell.fill",
                          title: "Smart Alerts",
                          description: "Get notified 60 seconds before meetings")

                FeatureRow(icon: "menubar.rectangle",
                          title: "Menu Bar Integration",
                          description: "See your next meeting at a glance")

                FeatureRow(icon: "macwindow",
                          title: "Desktop Widget",
                          description: "Beautiful floating widget for quick access")

                FeatureRow(icon: "link",
                          title: "Quick Join",
                          description: "One-click to join Zoom, Meet, Teams & more")
            }
            .padding(.horizontal, 60)

            Spacer()
        }
        .padding()
    }

    private var calendarPermissionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: calendarAccessGranted ? "checkmark.circle.fill" : "calendar.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(calendarAccessGranted ? .green : .orange)

            Text("Calendar Access")
                .font(.system(size: 36, weight: .bold))

            Text("HeadsUp needs access to your calendar to show upcoming meetings")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)

            VStack(alignment: .leading, spacing: 12) {
                PrivacyRow(icon: "lock.shield.fill", text: "Your data stays on your device")
                PrivacyRow(icon: "eye.slash.fill", text: "We never read or store your calendar data")
                PrivacyRow(icon: "network.slash", text: "No network requests except opening meeting links")
            }
            .padding(.horizontal, 80)

            if calendarAccessGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Calendar access granted!")
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: requestCalendarAccess) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Grant Calendar Access")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding()
    }

    private var settingsConfigurationPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Customize Your Experience")
                .font(.system(size: 36, weight: .bold))

            Text("Configure HeadsUp to match your workflow")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(spacing: 20) {
                SettingToggle(
                    icon: "calendar.badge.clock",
                    title: "Always Show Next Event",
                    description: "Display upcoming meetings in menu bar even if they're not today",
                    isOn: $alwaysShowNextEvent
                )

                SettingToggle(
                    icon: "macwindow",
                    title: "Show Desktop Widget",
                    description: "Display the floating widget on your desktop",
                    isOn: $showWidget
                )
            }
            .padding(.horizontal, 60)

            Spacer()
        }
        .padding()
    }

    private var widgetIntroductionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            HStack(spacing: 20) {
                Image(systemName: "macwindow")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Desktop Widget")
                        .font(.system(size: 36, weight: .bold))
                    Text("Your meetings, always visible")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                WidgetFeatureRow(
                    icon: "clock.fill",
                    text: "Live countdown to next meeting"
                )

                WidgetFeatureRow(
                    icon: "list.bullet",
                    text: "See all upcoming events at a glance"
                )

                WidgetFeatureRow(
                    icon: "hand.point.up.left.fill",
                    text: "Drag to position anywhere on screen"
                )

                WidgetFeatureRow(
                    icon: "command",
                    text: "Toggle with ⌘W from menu bar"
                )
            }
            .padding(.horizontal, 80)

            Text("Tip: The widget stays on top of all windows but won't interfere with your work")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)

            Spacer()
        }
        .padding()
    }

    private var completionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.system(size: 36, weight: .bold))

            Text("HeadsUp is ready to help you stay on top of your meetings")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)

            VStack(spacing: 16) {
                QuickTipRow(
                    icon: "bell.fill",
                    text: "You'll get alerts 60 seconds before meetings start"
                )

                QuickTipRow(
                    icon: "menubar.rectangle",
                    text: "Click the menu bar icon to see all upcoming meetings"
                )

                QuickTipRow(
                    icon: "gearshape.fill",
                    text: "Access settings anytime from the menu bar"
                )
            }
            .padding(.horizontal, 80)

            Button(action: completeOnboarding) {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            if currentPage > 0 && currentPage < 4 {
                Button(action: previousPage) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            if currentPage < 4 {
                Button(action: nextPage) {
                    HStack {
                        Text(currentPage == 1 ? (calendarAccessGranted ? "Next" : "Skip for Now") : "Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func nextPage() {
        withAnimation {
            if currentPage < 4 {
                currentPage += 1
            }
        }
    }

    private func previousPage() {
        withAnimation {
            if currentPage > 0 {
                currentPage -= 1
            }
        }
    }

    private func requestCalendarAccess() {
        let service = CalendarService.shared
        service.requestAccess { granted, error in
            DispatchQueue.main.async {
                calendarAccessGranted = granted
                if granted {
                    // Auto-advance after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        nextPage()
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        let settings = OnboardingSettings(
            calendarAccessGranted: calendarAccessGranted,
            showWidget: showWidget,
            alwaysShowNextEvent: alwaysShowNextEvent
        )
        onComplete(settings)
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct PrivacyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct SettingToggle: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct WidgetFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct QuickTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Onboarding Settings

struct OnboardingSettings {
    let calendarAccessGranted: Bool
    let showWidget: Bool
    let alwaysShowNextEvent: Bool
}

// MARK: - Preview

#Preview {
    OnboardingView { settings in
        print("Onboarding completed with settings: \(settings)")
    }
}
