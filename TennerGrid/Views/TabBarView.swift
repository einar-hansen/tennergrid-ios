import SwiftUI

/// The main tab bar view that provides navigation between primary app sections
/// Implements a 3-tab structure: Main, Daily Challenges, and Profile
struct TabBarView: View {
    // MARK: - Properties

    /// Currently selected tab
    @State private var selectedTab: Tab = .main

    /// Puzzle manager shared across tabs
    @StateObject private var puzzleManager = PuzzleManager()

    // MARK: - Tab Enumeration

    /// Available tabs in the app
    enum Tab: Int, CaseIterable {
        case main
        case dailyChallenges
        case profile

        /// Display title for each tab
        var title: String {
            switch self {
            case .main:
                "Main"
            case .dailyChallenges:
                "Daily"
            case .profile:
                "Me"
            }
        }

        /// SF Symbol icon for each tab
        var icon: String {
            switch self {
            case .main:
                "house.fill"
            case .dailyChallenges:
                "calendar"
            case .profile:
                "person.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            mainTab
            dailyChallengesTab
            profileTab
        }
    }

    // MARK: - Tab Views

    /// Main tab containing the home screen and game flow
    private var mainTab: some View {
        ContentView()
            .tabItem {
                Label(Tab.main.title, systemImage: Tab.main.icon)
            }
            .tag(Tab.main)
    }

    /// Daily challenges tab showing calendar and streak tracking
    private var dailyChallengesTab: some View {
        DailyChallengesPlaceholderView()
            .tabItem {
                Label(Tab.dailyChallenges.title, systemImage: Tab.dailyChallenges.icon)
            }
            .tag(Tab.dailyChallenges)
    }

    /// Profile/Me tab with settings, stats, and achievements
    private var profileTab: some View {
        ProfilePlaceholderView()
            .tabItem {
                Label(Tab.profile.title, systemImage: Tab.profile.icon)
            }
            .tag(Tab.profile)
    }
}

// MARK: - Placeholder Views

/// Placeholder view for Daily Challenges tab (to be implemented in Phase 5.4)
// swiftlint:disable:next swiftui_view_body
private struct DailyChallengesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                iconView

                titleView

                subtitleView

                descriptionView
            }
            .navigationTitle("Daily Challenges")
        }
    }

    private var iconView: some View {
        Image(systemName: "calendar.badge.clock")
            .font(.system(size: 64))
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var titleView: some View {
        Text("Daily Challenges")
            .font(.system(size: 28, weight: .bold, design: .rounded))
    }

    private var subtitleView: some View {
        Text("Coming Soon")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
    }

    private var descriptionView: some View {
        Text("Track your daily puzzle streak and compete with yourself!")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
}

/// Placeholder view for Profile/Me tab (to be implemented in Phase 5.5)
// swiftlint:disable:next swiftui_view_body
private struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                iconView

                titleView

                subtitleView

                descriptionView
            }
            .navigationTitle("Me")
        }
    }

    private var iconView: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var titleView: some View {
        Text("Profile")
            .font(.system(size: 28, weight: .bold, design: .rounded))
    }

    private var subtitleView: some View {
        Text("Coming Soon")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
    }

    private var descriptionView: some View {
        Text("View your statistics, achievements, and customize settings!")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
}

// MARK: - Previews

#Preview("Tab Bar - Main Tab") {
    TabBarView()
}

#Preview("Tab Bar - Dark Mode") {
    TabBarView()
        .preferredColorScheme(.dark)
}
