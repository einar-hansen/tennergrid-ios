import SwiftUI

/// The main tab bar view that provides navigation between primary app sections
/// Implements a 3-tab structure: Main, Daily Challenges, and Profile
struct TabBarView: View {
    // MARK: - Properties

    /// Currently selected tab with scene-level persistence across app launches
    @SceneStorage("selectedTab") private var selectedTab: Tab = .main

    /// Puzzle manager shared across tabs for state preservation
    @StateObject private var puzzleManager = PuzzleManager()

    // MARK: - Tab Enumeration

    /// Available tabs in the app
    /// Conforms to RawRepresentable for SceneStorage persistence
    enum Tab: Int, CaseIterable, Identifiable {
        case main
        case dailyChallenges
        case profile

        var id: Int { rawValue }

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
    /// Shares the puzzle manager to ensure state preservation across tab switches
    private var mainTab: some View {
        ContentView(puzzleManager: puzzleManager)
            .tabItem {
                Label(Tab.main.title, systemImage: Tab.main.icon)
            }
            .tag(Tab.main)
    }

    /// Daily challenges tab showing calendar and streak tracking
    private var dailyChallengesTab: some View {
        DailyChallengesView()
            .tabItem {
                Label(Tab.dailyChallenges.title, systemImage: Tab.dailyChallenges.icon)
            }
            .tag(Tab.dailyChallenges)
    }

    /// Profile/Me tab with settings, stats, and achievements
    private var profileTab: some View {
        ProfileView()
            .tabItem {
                Label(Tab.profile.title, systemImage: Tab.profile.icon)
            }
            .tag(Tab.profile)
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
