import Foundation
import SwiftUI

/// Represents an achievement that can be unlocked by the player
struct Achievement: Equatable, Identifiable {
    /// Unique identifier for the achievement
    let id: String

    /// Display title of the achievement
    let title: String

    /// Detailed description explaining how to unlock it
    let achievementDescription: String

    /// Current progress toward unlocking (0.0 to 1.0)
    var progress: Double

    /// Whether the achievement has been unlocked
    var isUnlocked: Bool

    /// Date when the achievement was unlocked (nil if not unlocked)
    var unlockedAt: Date?

    /// Current progress value (for progressive achievements)
    var currentValue: Int

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
    ///   - achievementDescription: How to unlock description
    ///   - category: Achievement category
    ///   - iconName: SF Symbol name
    ///   - targetValue: Target value to reach
    ///   - isHidden: Whether hidden until unlocked
    ///   - points: Point value
    init(
        id: String,
        title: String,
        achievementDescription: String,
        category: AchievementCategory,
        iconName: String,
        targetValue: Int = 1,
        isHidden: Bool = false,
        points: Int = 10
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.category = category
        self.iconName = iconName
        self.targetValue = targetValue
        self.isHidden = isHidden
        self.points = points
        progress = 0.0
        currentValue = 0
        isUnlocked = false
        unlockedAt = nil
    }
}

// MARK: - Codable

extension Achievement: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case achievementDescription
        case progress
        case isUnlocked
        case unlockedAt
        case currentValue
        case category
        case iconName
        case targetValue
        case isHidden
        case points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        achievementDescription = try container.decode(String.self, forKey: .achievementDescription)
        progress = try container.decode(Double.self, forKey: .progress)
        isUnlocked = try container.decode(Bool.self, forKey: .isUnlocked)
        unlockedAt = try container.decodeIfPresent(Date.self, forKey: .unlockedAt)

        category = try container.decode(AchievementCategory.self, forKey: .category)
        iconName = try container.decode(String.self, forKey: .iconName)
        targetValue = try container.decode(Int.self, forKey: .targetValue)

        // Handle migration: currentValue might not exist in old saved data
        currentValue = (try container.decodeIfPresent(Int.self, forKey: .currentValue)) ?? Int(progress * Double(targetValue))
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        points = try container.decode(Int.self, forKey: .points)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(achievementDescription, forKey: .achievementDescription)
        try container.encode(progress, forKey: .progress)
        try container.encode(isUnlocked, forKey: .isUnlocked)
        try container.encodeIfPresent(unlockedAt, forKey: .unlockedAt)
        try container.encode(currentValue, forKey: .currentValue)
        try container.encode(category, forKey: .category)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(targetValue, forKey: .targetValue)
        try container.encode(isHidden, forKey: .isHidden)
        try container.encode(points, forKey: .points)
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

        self.currentValue = currentValue
        progress = min(Double(currentValue) / Double(targetValue), 1.0)

        if progress >= 1.0, !isUnlocked {
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
        currentValue = targetValue
        unlockedAt = Date()
    }

    /// Resets the achievement to locked state (for testing/debugging)
    mutating func reset() {
        isUnlocked = false
        progress = 0.0
        currentValue = 0
        unlockedAt = nil
    }
}

// MARK: - Computed Properties

extension Achievement {
    /// Progress as a percentage (0-100)
    var progressPercentage: Int {
        Int(progress * 100)
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
        if isHidden, !isUnlocked {
            "???"
        } else {
            title
        }
    }

    /// Display description (hidden achievements show generic text until unlocked)
    var displayDescription: String {
        if isHidden, !isUnlocked {
            "This achievement is hidden. Keep playing to discover it!"
        } else {
            achievementDescription
        }
    }

    /// Icon name to display (hidden achievements show question mark)
    var displayIconName: String {
        if isHidden, !isUnlocked {
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
    ///   - achievementDescription: How to unlock description
    ///   - category: Achievement category
    ///   - iconName: SF Symbol name
    ///   - isHidden: Whether hidden until unlocked
    ///   - points: Point value
    /// - Returns: A new Achievement instance
    static func oneTime(
        id: String,
        title: String,
        achievementDescription: String,
        category: AchievementCategory,
        iconName: String,
        isHidden: Bool = false,
        points: Int = 10
    ) -> Achievement {
        Achievement(
            id: id,
            title: title,
            achievementDescription: achievementDescription,
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
    ///   - achievementDescription: How to unlock description
    ///   - category: Achievement category
    ///   - iconName: SF Symbol name
    ///   - targetValue: Number of times to complete
    ///   - points: Point value
    /// - Returns: A new Achievement instance
    static func progressive(
        id: String,
        title: String,
        achievementDescription: String,
        category: AchievementCategory,
        iconName: String,
        targetValue: Int,
        points: Int = 10
    ) -> Achievement {
        Achievement(
            id: id,
            title: title,
            achievementDescription: achievementDescription,
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
                achievementDescription: "Complete your first puzzle",
                category: .games,
                iconName: "flag.checkered",
                points: 10
            ),
            .progressive(
                id: "games_10",
                title: "Getting Started",
                achievementDescription: "Complete 10 puzzles",
                category: .games,
                iconName: "10.circle.fill",
                targetValue: 10,
                points: 20
            ),
            .progressive(
                id: "games_50",
                title: "Dedicated Player",
                achievementDescription: "Complete 50 puzzles",
                category: .games,
                iconName: "50.circle.fill",
                targetValue: 50,
                points: 50
            ),
            .progressive(
                id: "games_100",
                title: "Centurion",
                achievementDescription: "Complete 100 puzzles",
                category: .games,
                iconName: "100.circle.fill",
                targetValue: 100,
                points: 100
            ),

            // Difficulty Mastery
            .oneTime(
                id: "easy_master",
                title: "Easy Rider",
                achievementDescription: "Complete 10 Easy puzzles",
                category: .difficulty,
                iconName: "leaf.fill",
                points: 15
            ),
            .oneTime(
                id: "medium_master",
                title: "Rising Challenge",
                achievementDescription: "Complete 10 Medium puzzles",
                category: .difficulty,
                iconName: "chart.line.uptrend.xyaxis",
                points: 25
            ),
            .oneTime(
                id: "hard_master",
                title: "Hard Core",
                achievementDescription: "Complete 10 Hard puzzles",
                category: .difficulty,
                iconName: "bolt.fill",
                points: 40
            ),

            // Speed
            .oneTime(
                id: "speed_easy",
                title: "Quick Thinker",
                achievementDescription: "Complete an Easy puzzle in under 3 minutes",
                category: .speed,
                iconName: "hare.fill",
                points: 15
            ),
            .oneTime(
                id: "speed_medium",
                title: "Speed Demon",
                achievementDescription: "Complete a Medium puzzle in under 5 minutes",
                category: .speed,
                iconName: "bolt.fill",
                points: 30
            ),
            .oneTime(
                id: "speed_hard",
                title: "Lightning Fast",
                achievementDescription: "Complete a Hard puzzle in under 10 minutes",
                category: .speed,
                iconName: "cloud.bolt.fill",
                points: 50
            ),

            // Mastery
            .oneTime(
                id: "no_hints",
                title: "Self-Sufficient",
                achievementDescription: "Complete a puzzle without using any hints",
                category: .mastery,
                iconName: "lightbulb.slash.fill",
                points: 20
            ),
            .oneTime(
                id: "perfect_game",
                title: "Perfection",
                achievementDescription: "Complete a puzzle without any errors",
                category: .mastery,
                iconName: "checkmark.seal.fill",
                points: 30
            ),

            // Streaks
            .progressive(
                id: "streak_3",
                title: "On Fire",
                achievementDescription: "Play 3 days in a row",
                category: .streaks,
                iconName: "flame.fill",
                targetValue: 3,
                points: 25
            ),
            .progressive(
                id: "streak_7",
                title: "Week Warrior",
                achievementDescription: "Play 7 days in a row",
                category: .streaks,
                iconName: "calendar.badge.exclamationmark",
                targetValue: 7,
                points: 50
            ),
            .progressive(
                id: "streak_30",
                title: "Monthly Master",
                achievementDescription: "Play 30 days in a row",
                category: .streaks,
                iconName: "calendar.badge.clock",
                targetValue: 30,
                points: 100
            ),

            // Special
            .oneTime(
                id: "calculator_complete",
                title: "The Calculator",
                achievementDescription: "Complete a Calculator difficulty puzzle",
                category: .special,
                iconName: "function",
                isHidden: true,
                points: 150
            ),
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
