//
//  Achievement.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation
import SwiftUI

/// Represents an achievement that can be unlocked by the player
struct Achievement: Equatable, Codable, Identifiable {
    /// Unique identifier for the achievement
    let id: String

    /// Display title of the achievement
    let title: String

    /// Detailed description explaining how to unlock it
    let description: String

    /// Current progress toward unlocking (0.0 to 1.0)
    var progress: Double

    /// Whether the achievement has been unlocked
    var isUnlocked: Bool

    /// Date when the achievement was unlocked (nil if not unlocked)
    var unlockedAt: Date?

    /// Category of the achievement for grouping
    let category: AchievementCategory

    /// Icon name (SF Symbol) for visual representation
    let iconName: String

    /// Target value needed to unlock (for progressive achievements)
    let targetValue: Int

    /// Whether this achievement is hidden until unlocked
    let isHidden: Bool

    /// Point value of this achievement
    let points: Int

    /// Creates a new achievement
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - title: Display title
    ///   - description: How to unlock description
    ///   - category: Achievement category
    ///   - iconName: SF Symbol name
    ///   - targetValue: Target value to reach
    ///   - isHidden: Whether hidden until unlocked
    ///   - points: Point value
    init(
        id: String,
        title: String,
        description: String,
        category: AchievementCategory,
        iconName: String,
        targetValue: Int = 1,
        isHidden: Bool = false,
        points: Int = 10
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.iconName = iconName
        self.targetValue = targetValue
        self.isHidden = isHidden
        self.points = points
        progress = 0.0
        isUnlocked = false
        unlockedAt = nil
    }
}

// MARK: - AchievementCategory

extension Achievement {
    /// Categories for organizing achievements
    enum AchievementCategory: String, Codable, CaseIterable {
        case games
        case difficulty
        case speed
        case mastery
        case streaks
        case special

        /// Display name for the category
        var displayName: String {
            switch self {
            case .games:
                "Games Played"
            case .difficulty:
                "Difficulty Mastery"
            case .speed:
                "Speed Running"
            case .mastery:
                "Perfect Play"
            case .streaks:
                "Dedication"
            case .special:
                "Special"
            }
        }

        /// Icon for the category
        var iconName: String {
            switch self {
            case .games:
                "gamecontroller.fill"
            case .difficulty:
                "chart.bar.fill"
            case .speed:
                "clock.fill"
            case .mastery:
                "star.fill"
            case .streaks:
                "flame.fill"
            case .special:
                "trophy.fill"
            }
        }

        /// Color for the category
        var color: Color {
            switch self {
            case .games:
                .blue
            case .difficulty:
                .orange
            case .speed:
                .green
            case .mastery:
                .purple
            case .streaks:
                .red
            case .special:
                .yellow
            }
        }
    }
}

// MARK: - Progress Management

extension Achievement {
    /// Updates progress toward unlocking the achievement
    /// - Parameter currentValue: Current progress value
    /// - Returns: True if achievement was unlocked by this update
    @discardableResult
    mutating func updateProgress(currentValue: Int) -> Bool {
        guard !isUnlocked else { return false }

        let previousProgress = progress
        progress = min(Double(currentValue) / Double(targetValue), 1.0)

        if progress >= 1.0 && !isUnlocked {
            unlock()
            return true
        }

        return false
    }

    /// Unlocks the achievement
    mutating func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        progress = 1.0
        unlockedAt = Date()
    }

    /// Resets the achievement to locked state (for testing/debugging)
    mutating func reset() {
        isUnlocked = false
        progress = 0.0
        unlockedAt = nil
    }
}

// MARK: - Computed Properties

extension Achievement {
    /// Progress as a percentage (0-100)
    var progressPercentage: Int {
        Int(progress * 100)
    }

    /// Current progress value based on target
    var currentValue: Int {
        Int(progress * Double(targetValue))
    }

    /// Formatted progress string (e.g., "5/10")
    var progressText: String {
        "\(currentValue)/\(targetValue)"
    }

    /// Whether the achievement should be displayed
    var isVisible: Bool {
        !isHidden || isUnlocked
    }

    /// Display title (hidden achievements show "???" until unlocked)
    var displayTitle: String {
        if isHidden && !isUnlocked {
            "???"
        } else {
            title
        }
    }

    /// Display description (hidden achievements show generic text until unlocked)
    var displayDescription: String {
        if isHidden && !isUnlocked {
            "This achievement is hidden. Keep playing to discover it!"
        } else {
            description
        }
    }

    /// Icon name to display (hidden achievements show question mark)
    var displayIconName: String {
        if isHidden && !isUnlocked {
            "questionmark.circle.fill"
        } else {
            iconName
        }
    }

    /// Formatted unlock date string
    var formattedUnlockDate: String? {
        guard let date = unlockedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Factory Methods

extension Achievement {
    /// Creates a simple one-time achievement (unlocks when condition is met once)
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - title: Display title
    ///   - description: How to unlock description
    ///   - category: Achievement category
    ///   - iconName: SF Symbol name
    ///   - isHidden: Whether hidden until unlocked
    ///   - points: Point value
    /// - Returns: A new Achievement instance
    static func oneTime(
        id: String,
        title: String,
        description: String,
        category: AchievementCategory,
        iconName: String,
        isHidden: Bool = false,
        points: Int = 10
    ) -> Achievement {
        Achievement(
            id: id,
            title: title,
            description: description,
            category: category,
            iconName: iconName,
            targetValue: 1,
            isHidden: isHidden,
            points: points
        )
    }

    /// Creates a progressive achievement (requires multiple completions)
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - title: Display title
    ///   - description: How to unlock description
    ///   - category: Achievement category
    ///   - iconName: SF Symbol name
    ///   - targetValue: Number of times to complete
    ///   - points: Point value
    /// - Returns: A new Achievement instance
    static func progressive(
        id: String,
        title: String,
        description: String,
        category: AchievementCategory,
        iconName: String,
        targetValue: Int,
        points: Int = 10
    ) -> Achievement {
        Achievement(
            id: id,
            title: title,
            description: description,
            category: category,
            iconName: iconName,
            targetValue: targetValue,
            isHidden: false,
            points: points
        )
    }
}

// MARK: - Predefined Achievements

extension Achievement {
    /// Returns all predefined achievements for the game
    static var allAchievements: [Achievement] {
        [
            // Games Played
            .oneTime(
                id: "first_game",
                title: "First Steps",
                description: "Complete your first puzzle",
                category: .games,
                iconName: "flag.checkered",
                points: 10
            ),
            .progressive(
                id: "games_10",
                title: "Getting Started",
                description: "Complete 10 puzzles",
                category: .games,
                iconName: "10.circle.fill",
                targetValue: 10,
                points: 20
            ),
            .progressive(
                id: "games_50",
                title: "Dedicated Player",
                description: "Complete 50 puzzles",
                category: .games,
                iconName: "50.circle.fill",
                targetValue: 50,
                points: 50
            ),
            .progressive(
                id: "games_100",
                title: "Centurion",
                description: "Complete 100 puzzles",
                category: .games,
                iconName: "100.circle.fill",
                targetValue: 100,
                points: 100
            ),

            // Difficulty Mastery
            .oneTime(
                id: "easy_master",
                title: "Easy Rider",
                description: "Complete 10 Easy puzzles",
                category: .difficulty,
                iconName: "leaf.fill",
                points: 15
            ),
            .oneTime(
                id: "medium_master",
                title: "Rising Challenge",
                description: "Complete 10 Medium puzzles",
                category: .difficulty,
                iconName: "chart.line.uptrend.xyaxis",
                points: 25
            ),
            .oneTime(
                id: "hard_master",
                title: "Hard Core",
                description: "Complete 10 Hard puzzles",
                category: .difficulty,
                iconName: "bolt.fill",
                points: 40
            ),
            .oneTime(
                id: "expert_master",
                title: "Expert Level",
                description: "Complete 10 Expert puzzles",
                category: .difficulty,
                iconName: "crown.fill",
                points: 75
            ),

            // Speed
            .oneTime(
                id: "speed_easy",
                title: "Quick Thinker",
                description: "Complete an Easy puzzle in under 3 minutes",
                category: .speed,
                iconName: "hare.fill",
                points: 15
            ),
            .oneTime(
                id: "speed_medium",
                title: "Speed Demon",
                description: "Complete a Medium puzzle in under 5 minutes",
                category: .speed,
                iconName: "bolt.fill",
                points: 30
            ),
            .oneTime(
                id: "speed_hard",
                title: "Lightning Fast",
                description: "Complete a Hard puzzle in under 10 minutes",
                category: .speed,
                iconName: "cloud.bolt.fill",
                points: 50
            ),

            // Mastery
            .oneTime(
                id: "no_hints",
                title: "Self-Sufficient",
                description: "Complete a puzzle without using any hints",
                category: .mastery,
                iconName: "lightbulb.slash.fill",
                points: 20
            ),
            .oneTime(
                id: "perfect_game",
                title: "Perfection",
                description: "Complete a puzzle without any errors",
                category: .mastery,
                iconName: "checkmark.seal.fill",
                points: 30
            ),

            // Streaks
            .progressive(
                id: "streak_3",
                title: "On Fire",
                description: "Play 3 days in a row",
                category: .streaks,
                iconName: "flame.fill",
                targetValue: 3,
                points: 25
            ),
            .progressive(
                id: "streak_7",
                title: "Week Warrior",
                description: "Play 7 days in a row",
                category: .streaks,
                iconName: "calendar.badge.exclamationmark",
                targetValue: 7,
                points: 50
            ),
            .progressive(
                id: "streak_30",
                title: "Monthly Master",
                description: "Play 30 days in a row",
                category: .streaks,
                iconName: "calendar.badge.clock",
                targetValue: 30,
                points: 100
            ),

            // Special
            .oneTime(
                id: "calculator_complete",
                title: "The Calculator",
                description: "Complete a Calculator difficulty puzzle",
                category: .special,
                iconName: "function",
                isHidden: true,
                points: 150
            )
        ]
    }
}

// MARK: - CustomStringConvertible

extension Achievement: CustomStringConvertible {
    var description: String {
        """
        Achievement(
            id: \(id),
            title: \(displayTitle),
            progress: \(progressText),
            unlocked: \(isUnlocked),
            points: \(points)
        )
        """
    }
}
