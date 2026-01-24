import Combine
import Foundation

// Note: GameStatistics, Difficulty, GameState, and Achievement are defined in the project
// but may need explicit imports if in separate modules

/// Service for managing game statistics persistence
/// Handles recording game completions, updating streaks, and calculating trends
final class StatisticsManager: ObservableObject {
    // MARK: - Properties

    /// Shared singleton instance
    static let shared = StatisticsManager()

    /// Published current game statistics
    @Published private(set) var statistics: GameStatistics

    /// Key for storing statistics in UserDefaults
    private let statisticsKey = "com.tennergrid.gameStatistics"

    /// UserDefaults instance for persistence (allows injection for testing)
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Load statistics from UserDefaults or create new
        self.statistics = StatisticsManager.loadStatistics(from: userDefaults) ?? GameStatistics()
    }

    // MARK: - Public Methods

    /// Records the start of a new game
    /// - Parameter difficulty: The difficulty of the started game
    func recordGameStarted(difficulty: Difficulty) {
        statistics.recordGameStarted(difficulty: difficulty)
        saveStatistics()
    }

    /// Records a completed game and updates all relevant statistics
    /// - Parameters:
    ///   - difficulty: The difficulty of the completed game
    ///   - time: Time taken to complete the game (in seconds)
    ///   - hintsUsed: Number of hints used during the game
    ///   - errors: Number of errors made during the game
    ///   - gameState: Optional game state for achievement checking
    /// - Returns: Array of newly unlocked achievements
    @discardableResult
    func recordGameCompleted(
        difficulty: Difficulty,
        time: TimeInterval,
        hintsUsed: Int = 0,
        errors: Int = 0,
        gameState: GameState? = nil
    ) -> [Achievement] {
        statistics.recordGameCompleted(
            difficulty: difficulty,
            time: time,
            hintsUsed: hintsUsed,
            errors: errors
        )
        saveStatistics()

        // Check for newly unlocked achievements after updating statistics
        let unlockedAchievements = AchievementManager.shared.checkAchievements(gameState: gameState)

        return unlockedAchievements
    }

    /// Updates the streak information based on today's play
    /// This is called automatically when recording game starts
    func updateStreaks() {
        // Streak updates are handled internally by GameStatistics
        // when recordGameStarted is called. This method exists for
        // explicit streak updates if needed in the future.
        saveStatistics()
    }

    /// Gets statistics for a specific difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Statistics for that difficulty
    func statistics(for difficulty: Difficulty) -> GameStatistics.DifficultyStatistics {
        statistics.statistics(for: difficulty)
    }

    /// Calculates the average completion time across all difficulties
    /// - Returns: Average time in seconds, or nil if no games completed
    func averageCompletionTime() -> TimeInterval? {
        statistics.averageTime
    }

    /// Calculates the average completion time for a specific difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Average time in seconds, or nil if no games completed at this difficulty
    func averageCompletionTime(for difficulty: Difficulty) -> TimeInterval? {
        statistics.statistics(for: difficulty).averageTime
    }

    /// Calculates the win rate across all difficulties
    /// - Returns: Win rate as a value between 0.0 and 1.0
    func overallWinRate() -> Double {
        statistics.winRate
    }

    /// Calculates the win rate for a specific difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Win rate as a value between 0.0 and 1.0
    func winRate(for difficulty: Difficulty) -> Double {
        statistics.statistics(for: difficulty).winRate
    }

    /// Gets the current play streak (consecutive days)
    /// - Returns: Number of consecutive days played
    func currentStreak() -> Int {
        statistics.currentStreak
    }

    /// Gets the longest play streak ever achieved
    /// - Returns: Longest number of consecutive days played
    func longestStreak() -> Int {
        statistics.longestStreak
    }

    /// Checks if the user has an active streak
    /// - Returns: True if played yesterday or today
    func hasActiveStreak() -> Bool {
        statistics.hasActiveStreak()
    }

    /// Gets the most played difficulty level
    /// - Returns: The difficulty with the most games played, or nil if no games played
    func mostPlayedDifficulty() -> Difficulty? {
        statistics.mostPlayedDifficulty()
    }

    /// Gets all difficulties sorted by play count
    /// - Returns: Array of difficulties sorted by number of games played (descending)
    func difficultiesByPlayCount() -> [Difficulty] {
        statistics.difficultiesByPlayCount()
    }

    /// Calculates improvement trend for a specific difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Trend information showing improvement over time
    func improvementTrend(for difficulty: Difficulty) -> ImprovementTrend {
        let stats = statistics.statistics(for: difficulty)

        // Calculate if user is improving based on average time vs best time
        guard let avgTime = stats.averageTime,
              let bestTime = stats.bestTime,
              stats.completed >= 3
        else {
            return ImprovementTrend(isImproving: false, percentageChange: 0.0)
        }

        // If average is close to best time, user is consistently performing well
        let percentageChange = ((avgTime - bestTime) / bestTime) * 100
        let isImproving = percentageChange <= 20 // Within 20% of best time

        return ImprovementTrend(isImproving: isImproving, percentageChange: percentageChange)
    }

    /// Gets total games played across all difficulties
    /// - Returns: Total number of games started
    func totalGamesPlayed() -> Int {
        statistics.gamesPlayed
    }

    /// Gets total games completed across all difficulties
    /// - Returns: Total number of games completed
    func totalGamesCompleted() -> Int {
        statistics.gamesCompleted
    }

    /// Gets total time played across all games
    /// - Returns: Total time in seconds
    func totalTimePlayed() -> TimeInterval {
        statistics.totalTimePlayed
    }

    /// Gets the best (fastest) completion time across all difficulties
    /// - Returns: Best time in seconds, or nil if no games completed
    func bestTime() -> TimeInterval? {
        statistics.bestTime
    }

    /// Gets the best time for a specific difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Best time in seconds, or nil if no games completed at this difficulty
    func bestTime(for difficulty: Difficulty) -> TimeInterval? {
        statistics.statistics(for: difficulty).bestTime
    }

    /// Resets all statistics to initial values
    /// - Warning: This cannot be undone
    func resetAllStatistics() {
        statistics.reset()
        saveStatistics()
    }

    // MARK: - Private Methods

    /// Saves current statistics to UserDefaults
    private func saveStatistics() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(statistics)
            userDefaults.set(data, forKey: statisticsKey)
        } catch {
            // swiftlint:disable:next no_print
            print("Failed to save statistics: \(error.localizedDescription)")
        }
    }

    /// Loads statistics from UserDefaults
    /// - Parameter userDefaults: UserDefaults instance to load from
    /// - Returns: GameStatistics if found and decoded successfully, nil otherwise
    private static func loadStatistics(from userDefaults: UserDefaults) -> GameStatistics? {
        guard let data = userDefaults.data(forKey: "com.tennergrid.gameStatistics") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(GameStatistics.self, from: data)
        } catch {
            // swiftlint:disable:next no_print
            print("Failed to load statistics: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Supporting Types

extension StatisticsManager {
    /// Represents improvement trend data for a difficulty level
    struct ImprovementTrend {
        /// Whether the user is improving (average time close to best time)
        let isImproving: Bool

        /// Percentage difference between average and best time
        /// Positive means average is slower than best, negative means average is faster (unlikely)
        let percentageChange: Double

        /// Formatted percentage string (e.g., "15.5%")
        var formattedPercentage: String {
            String(format: "%.1f%%", abs(percentageChange))
        }

        /// Description of the trend
        var description: String {
            if isImproving {
                "Consistently performing well"
            } else {
                "Room for improvement"
            }
        }
    }
}

// MARK: - Testing Support

#if DEBUG
    extension StatisticsManager {
        /// Creates a test instance with custom UserDefaults
        /// - Parameter userDefaults: Custom UserDefaults for testing
        /// - Returns: New StatisticsManager instance for testing
        static func test(userDefaults: UserDefaults) -> StatisticsManager {
            StatisticsManager(userDefaults: userDefaults)
        }

        /// Records a game completion for testing
        /// - Parameter gameState: Game state to record
        func recordCompletion(gameState: GameState) {
            statistics.recordGameCompleted(
                difficulty: gameState.puzzle.difficulty,
                time: gameState.elapsedTime,
                hintsUsed: gameState.hintsUsed,
                errors: gameState.errorCount
            )
            saveStatistics()
        }

        /// Updates the streak for testing
        /// - Parameter newStreak: New streak value to set
        func updateStreak(newStreak: Int) {
            statistics.currentStreak = newStreak
            if newStreak > statistics.longestStreak {
                statistics.longestStreak = newStreak
            }
            saveStatistics()
        }
    }
#endif
