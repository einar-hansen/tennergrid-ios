import SwiftUI

/// Settings view for configuring game preferences and app appearance
/// Provides toggles for gameplay options, theme selection, and notifications
// swiftlint:disable:next swiftui_view_body
struct SettingsView: View {
    // MARK: - Game Settings

    @AppStorage("autoCheckErrors") private var autoCheckErrors = true
    @AppStorage("showTimer") private var showTimer = true
    @AppStorage("highlightSameNumbers") private var highlightSameNumbers = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("soundEffects") private var soundEffects = true

    // MARK: - Appearance Settings

    @AppStorage("themePreference") private var themePreference = ThemePreference.system.rawValue
    @AppStorage("highContrastMode") private var highContrastMode = false

    // MARK: - Notification Settings

    @AppStorage("dailyReminder") private var dailyReminder = false

    // MARK: - Body

    var body: some View {
        List {
            gameSettingsSection
            appearanceSection
            notificationSection
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
    }

    // MARK: - Sections

    /// Game settings section with gameplay toggles
    private var gameSettingsSection: some View {
        Section {
            autoCheckErrorsToggle
            showTimerToggle
            highlightSameNumbersToggle
            hapticFeedbackToggle
            soundEffectsToggle
        } header: {
            Text("Game Settings")
        } footer: {
            Text("Customize your gameplay experience")
                .font(.caption)
        }
    }

    private var autoCheckErrorsToggle: some View {
        Toggle(isOn: $autoCheckErrors) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Auto-Check Errors")
                    .font(.system(size: 16, weight: .medium))
                Text("Automatically highlight invalid moves")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
    }

    private var showTimerToggle: some View {
        Toggle(isOn: $showTimer) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Show Timer")
                    .font(.system(size: 16, weight: .medium))
                Text("Display elapsed time during gameplay")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
    }

    private var highlightSameNumbersToggle: some View {
        Toggle(isOn: $highlightSameNumbers) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Highlight Same Numbers")
                    .font(.system(size: 16, weight: .medium))
                Text("Highlight all cells with the same number")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
    }

    private var hapticFeedbackToggle: some View {
        Toggle(isOn: $hapticFeedback) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Haptic Feedback")
                    .font(.system(size: 16, weight: .medium))
                Text("Vibrate on selections and actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
    }

    private var soundEffectsToggle: some View {
        Toggle(isOn: $soundEffects) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sound Effects")
                    .font(.system(size: 16, weight: .medium))
                Text("Play sounds for actions and events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
    }

    /// Appearance section with theme selector
    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $themePreference) {
                ForEach(ThemePreference.allCases) { theme in
                    HStack {
                        theme.icon
                        Text(theme.displayName)
                    }
                    .tag(theme.rawValue)
                }
            }
            .pickerStyle(.inline)

            highContrastModeToggle
        } header: {
            Text("Appearance")
        } footer: {
            Text("High contrast mode uses patterns and shapes in addition to colors for better visibility")
                .font(.caption)
        }
    }

    private var highContrastModeToggle: some View {
        Toggle(isOn: $highContrastMode) {
            VStack(alignment: .leading, spacing: 4) {
                Text("High Contrast Mode")
                    .font(.system(size: 16, weight: .medium))
                Text("Enhanced colors and visual patterns for better accessibility")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
    }

    /// Notification section with daily reminder toggle
    private var notificationSection: some View {
        Section {
            dailyReminderToggle
        } header: {
            Text("Notifications")
        } footer: {
            Text("Get reminded to play daily challenges")
                .font(.caption)
        }
    }

    private var dailyReminderToggle: some View {
        Toggle(isOn: $dailyReminder) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Reminder")
                    .font(.system(size: 16, weight: .medium))
                Text("Receive notification for daily puzzle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
    }
}

// MARK: - Theme Preference

/// Enumeration of available theme preferences
enum ThemePreference: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String {
        rawValue
    }

    /// Display name for the theme
    var displayName: String {
        switch self {
        case .light:
            "Light"
        case .dark:
            "Dark"
        case .system:
            "System"
        }
    }

    /// SF Symbol icon for the theme
    var icon: some View {
        Group {
            switch self {
            case .light:
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
            case .dark:
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
            case .system:
                Image(systemName: "gear")
                    .foregroundColor(.gray)
            }
        }
    }

    /// Color scheme corresponding to the theme preference
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        case .system:
            nil
        }
    }
}

// MARK: - Previews

#Preview("Settings View - Light Mode") {
    NavigationStack {
        SettingsView()
    }
}

#Preview("Settings View - Dark Mode") {
    NavigationStack {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}

#Preview("Settings with All Toggles On") {
    NavigationStack {
        SettingsView()
    }
}

#Preview("Settings with All Toggles Off") {
    NavigationStack {
        SettingsView()
    }
}
