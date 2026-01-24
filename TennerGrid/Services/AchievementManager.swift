import Combine
import Foundation

/// Service for managing achievements, checking conditions, and persisting unlock status
final class AchievementManager: ObservableObject {
    // MARK: - Properties

    /// Shared singleton instance
    static let shared = AchievementManager()

    /// Published list of all achievements with current unlock status
    @Published private(set) var achievements: [Achievement]

    /// Key for storing achievements in UserDefaults
    private let achievementsKey = "com.tennergrid.achievements"

    /// UserDefaults instance for persistence (allows injection for testing)
    private let userDefaults: UserDefaults

    /// Statistics manager for checking achievement conditions
    private let statisticsManager: StatisticsManager

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    /// - Parameters:
    ///   - statisticsManager: Statistics manager to use (defaults to shared instance)
    ///   - userDefaults: UserDefaults instance for persistence (defaults to standard)
    private init(statisticsManager: StatisticsManager = .shared, userDefaults: UserDefaults = .standard) {
        self.statisticsManager = statisticsManager
        self.userDefaults = userDefaults
        self.achievements = AchievementManager.loadAchievements(from: userDefaults)
    }

    // MARK: - Public Methods

    /// Checks all achievement conditions and unlocks any newly achieved ones
    /// - Parameter gameState: Optional game state from completed game
    /// - Returns: Array of newly unlocked achievements
    @discardableResult
    func checkAchievements(gameState: GameState? = nil) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        for index in achievements.indices {
            guard !achievements[index].isUnlocked else { continue }

            if checkCondition(for: achievements[index], gameState: gameState) {
                achievements[index].unlock()
                newlyUnlocked.append(achievements[index])
            }
        }

        if !newlyUnlocked.isEmpty {
            saveAchievements()
        }

        return newlyUnlocked
    }

    /// Updates progress for a specific achievement
    /// - Parameters:
    ///   - achievementId: ID of the achievement to update
    ///   - currentValue: Current progress value
    /// - Returns: True if the achievement was unlocked by this update
    @discardableResult
    func updateProgress(achievementId: String, currentValue: Int) -> Bool {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else {
            return false
        }

        let wasUnlocked = achievements[index].updateProgress(currentValue: currentValue)
        if wasUnlocked || achievements[index].progress > 0 {
            saveAchievements()
        }

        return wasUnlocked
    }

    /// Gets achievement by ID
    /// - Parameter id: Achievement identifier
    /// - Returns: Achievement if found, nil otherwise
    func achievement(withId id: String) -> Achievement? {
        achievements.first { $0.id == id }
    }

    /// Gets all achievements in a specific category
    /// - Parameter category: Achievement category
    /// - Returns: Array of achievements in that category
    func achievements(in category: Achievement.AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    /// Gets all unlocked achievements
    /// - Returns: Array of unlocked achievements
    func unlockedAchievements() -> [Achievement] {
        achievements.filter(\.isUnlocked)
    }

    /// Gets all locked achievements
    /// - Returns: Array of locked achievements
    func lockedAchievements() -> [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }

    /// Gets total points earned from unlocked achievements
    /// - Returns: Sum of points from unlocked achievements
    func totalPointsEarned() -> Int {
        achievements.filter(\.isUnlocked).reduce(0) { $0 + $1.points }
    }

    /// Gets total possible points from all achievements
    /// - Returns: Sum of points from all achievements
    func totalPossiblePoints() -> Int {
        achievements.reduce(0) { $0 + $1.points }
    }

    /// Gets completion percentage across all achievements
    /// - Returns: Percentage (0.0 to 1.0) of achievements unlocked
    func completionPercentage() -> Double {
        guard !achievements.isEmpty else { return 0.0 }
        let unlockedCount = achievements.filter(\.isUnlocked).count
        return Double(unlockedCount) / Double(achievements.count)
    }

    /// Resets all achievements to locked state
    /// - Warning: This cannot be undone
    func resetAllAchievements() {
        achievements = Achievement.allAchievements
        saveAchievements()
    }

    // MARK: - Private Methods

    /// Checks if a specific achievement's condition is met
    /// - Parameters:
    ///   - achievement: Achievement to check
    ///   - gameState: Optional game state from completed game
    /// - Returns: True if condition is met
    // swiftlint:disable:next cyclomatic_complexity
    private func checkCondition(for achievement: Achievement, gameState: GameState?) -> Bool {
        let stats = statisticsManager.statistics

        switch achievement.id {
        // Games Played
        case "first_game":
            return stats.gamesCompleted >= 1

        case "games_10", "games_50", "games_100":
            return updateProgressAndCheck(achievement: achievement, currentValue: stats.gamesCompleted)

        // Difficulty Mastery
        case "easy_master":
            return stats.statistics(for: .easy).completed >= 10

        case "medium_master":
            return stats.statistics(for: .medium).completed >= 10

        case "hard_master":
            return stats.statistics(for: .hard).completed >= 10

        // Speed
        case "speed_easy":
            return checkSpeedAchievement(gameState: gameState, difficulty: .easy, maxTime: 180)

        case "speed_medium":
            return checkSpeedAchievement(gameState: gameState, difficulty: .medium, maxTime: 300)

        case "speed_hard":
            return checkSpeedAchievement(gameState: gameState, difficulty: .hard, maxTime: 600)

        // Mastery
        case "no_hints":
            return checkPerfectionAchievement(gameState: gameState) { $0.hintsUsed == 0 }

        case "perfect_game":
            return checkPerfectionAchievement(gameState: gameState) { $0.errorCount == 0 }

        // Streaks
        case "streak_3", "streak_7", "streak_30":
            return updateProgressAndCheck(achievement: achievement, currentValue: stats.currentStreak)

        // Special
        case "calculator_complete":
            return false // Calculator difficulty not yet implemented

        default:
            return false
        }
    }

    /// Checks speed achievement condition
    private func checkSpeedAchievement(
        gameState: GameState?,
        difficulty: Difficulty,
        maxTime: TimeInterval
    ) -> Bool {
        guard let gameState,
              gameState.puzzle.difficulty == difficulty,
              gameState.isCompleted
        else { return false }
        return gameState.elapsedTime <= maxTime
    }

    /// Checks mastery achievement condition using a predicate
    private func checkPerfectionAchievement(
        gameState: GameState?,
        predicate: (GameState) -> Bool
    ) -> Bool {
        guard let gameState, gameState.isCompleted else { return false }
        return predicate(gameState)
    }

    /// Helper to update progress and check if target is met
    /// - Parameters:
    ///   - achievement: Achievement to update
    ///   - currentValue: Current progress value
    /// - Returns: True if target value is reached
    private func updateProgressAndCheck(achievement: Achievement, currentValue: Int) -> Bool {
        guard let index = achievements.firstIndex(where: { $0.id == achievement.id }) else {
            return false
        }

        achievements[index].updateProgress(currentValue: currentValue)
        return achievements[index].isUnlocked
    }

    /// Saves current achievements to UserDefaults
    private func saveAchievements() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(achievements)
            userDefaults.set(data, forKey: achievementsKey)
        } catch {
            // swiftlint:disable:next no_print
            print("Failed to save achievements: \(error.localizedDescription)")
        }
    }

    /// Loads achievements from UserDefaults
    /// - Parameter userDefaults: UserDefaults instance to load from
    /// - Returns: Array of achievements, either loaded or default
    private static func loadAchievements(from userDefaults: UserDefaults) -> [Achievement] {
        guard let data = userDefaults.data(forKey: "com.tennergrid.achievements") else {
            return Achievement.allAchievements
        }

        do {
            let decoder = JSONDecoder()
            let savedAchievements = try decoder.decode([Achievement].self, from: data)

            // Merge with predefined achievements to handle new achievements added in updates
            let allAchievements = Achievement.allAchievements
            var mergedAchievements: [Achievement] = []

            for achievement in allAchievements {
                if let saved = savedAchievements.first(where: { $0.id == achievement.id }) {
                    mergedAchievements.append(saved)
                } else {
                    mergedAchievements.append(achievement)
                }
            }

            return mergedAchievements
        } catch {
            // swiftlint:disable:next no_print
            print("Failed to load achievements: \(error.localizedDescription)")
            return Achievement.allAchievements
        }
    }
}

// MARK: - Testing Support

#if DEBUG
    extension AchievementManager {
        /// Creates a test instance with custom statistics manager and UserDefaults
        /// - Parameters:
        ///   - statisticsManager: Custom statistics manager for testing
        ///   - userDefaults: Custom UserDefaults for testing
        /// - Returns: New AchievementManager instance
        static func test(statisticsManager: StatisticsManager, userDefaults: UserDefaults) -> AchievementManager {
            AchievementManager(statisticsManager: statisticsManager, userDefaults: userDefaults)
        }

        /// Unlocks a specific achievement for testing
        /// - Parameter achievementId: ID of achievement to unlock
        func unlockForTesting(achievementId: String) {
            guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else {
                return
            }
            achievements[index].unlock()
            saveAchievements()
        }
    }
#endif
