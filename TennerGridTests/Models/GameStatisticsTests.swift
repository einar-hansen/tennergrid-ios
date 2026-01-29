import Foundation
import Testing
@testable import TennerGrid

struct GameStatisticsTests {
    // MARK: - Initialization Tests

    @Test func newStatisticsIsEmpty() {
        let stats = GameStatistics.new()

        #expect(stats.gamesPlayed == 0)
        #expect(stats.gamesCompleted == 0)
        #expect(stats.totalTimePlayed == 0)
        #expect(stats.bestTime == nil)
        #expect(stats.difficultyBreakdowns.isEmpty)
        #expect(stats.currentStreak == 0)
        #expect(stats.longestStreak == 0)
        #expect(stats.lastPlayedDate == nil)
    }

    @Test func newStatisticsHasCreatedDate() {
        let beforeCreation = Date()
        let stats = GameStatistics.new()
        let afterCreation = Date()

        #expect(stats.createdAt >= beforeCreation)
        #expect(stats.createdAt <= afterCreation)
    }

    // MARK: - Recording Game Started Tests

    @Test func recordGameStartedIncrementsCount() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        #expect(stats.gamesPlayed == 1)

        stats.recordGameStarted(difficulty: .medium)
        #expect(stats.gamesPlayed == 2)
    }

    @Test func recordGameStartedCreatesDifficultyBreakdown() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        #expect(stats.difficultyBreakdowns[.easy] != nil)
        #expect(stats.difficultyBreakdowns[.easy]?.played == 1)
    }

    @Test func recordGameStartedUpdatesLastPlayedDate() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        #expect(stats.lastPlayedDate != nil)
    }

    @Test func recordGameStartedStartsStreak() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == 1)
    }

    // MARK: - Recording Game Completed Tests

    @Test func recordGameCompletedIncrementsCount() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)
        #expect(stats.gamesCompleted == 1)

        stats.recordGameCompleted(difficulty: .medium, time: 600, hintsUsed: 3, errors: 2)
        #expect(stats.gamesCompleted == 2)
    }

    @Test func recordGameCompletedUpdatesTotalTime() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 0)
        #expect(stats.totalTimePlayed == 300)

        stats.recordGameCompleted(difficulty: .easy, time: 200, hintsUsed: 0, errors: 0)
        #expect(stats.totalTimePlayed == 500)
    }

    @Test func recordGameCompletedSetsBestTime() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 0)
        #expect(stats.bestTime == 300)

        stats.recordGameCompleted(difficulty: .easy, time: 200, hintsUsed: 0, errors: 0)
        #expect(stats.bestTime == 200)

        stats.recordGameCompleted(difficulty: .easy, time: 250, hintsUsed: 0, errors: 0)
        #expect(stats.bestTime == 200) // Should not change
    }

    @Test func recordGameCompletedUpdatesDifficultyStats() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)

        let easyStats = stats.statistics(for: .easy)
        #expect(easyStats.completed == 1)
        #expect(easyStats.totalTime == 300)
        #expect(easyStats.totalHintsUsed == 2)
        #expect(easyStats.totalErrors == 1)
        #expect(easyStats.bestTime == 300)
    }

    @Test func recordGameCompletedUpdatesDifficultyBestTime() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 0)
        stats.recordGameCompleted(difficulty: .easy, time: 200, hintsUsed: 0, errors: 0)
        stats.recordGameCompleted(difficulty: .easy, time: 250, hintsUsed: 0, errors: 0)

        let easyStats = stats.statistics(for: .easy)
        #expect(easyStats.bestTime == 200)
    }

    // MARK: - Win Rate Tests

    @Test func winRateWithNoGames() {
        let stats = GameStatistics.new()
        #expect(stats.winRate == 0.0)
    }

    @Test func winRateWithAllWins() {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 0)
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 200, hintsUsed: 0, errors: 0)

        #expect(stats.winRate == 1.0)
        #expect(stats.winRatePercentage == "100.0%")
    }

    @Test func winRateWithPartialWins() {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 0)
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 200, hintsUsed: 0, errors: 0)

        #expect(stats.gamesPlayed == 3)
        #expect(stats.gamesCompleted == 2)
        #expect(abs(stats.winRate - 0.666) < 0.01)
    }

    // MARK: - Average Time Tests

    @Test func averageTimeWithNoCompletedGames() {
        let stats = GameStatistics.new()
        #expect(stats.averageTime == nil)
    }

    @Test func averageTimeWithCompletedGames() {
        var stats = GameStatistics.new()
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 0)
        stats.recordGameCompleted(difficulty: .easy, time: 500, hintsUsed: 0, errors: 0)

        #expect(stats.averageTime == 400)
    }

    // MARK: - Difficulty Statistics Tests

    @Test func difficultyStatisticsWinRate() {
        var diffStats = GameStatistics.DifficultyStatistics()
        #expect(diffStats.winRate == 0.0)

        diffStats.played = 4
        diffStats.completed = 3
        #expect(diffStats.winRate == 0.75)
    }

    @Test func difficultyStatisticsAverageTime() {
        var diffStats = GameStatistics.DifficultyStatistics()
        #expect(diffStats.averageTime == nil)

        diffStats.completed = 2
        diffStats.totalTime = 600
        #expect(diffStats.averageTime == 300)
    }

    @Test func difficultyStatisticsAverageHints() {
        var diffStats = GameStatistics.DifficultyStatistics()
        #expect(diffStats.averageHints == 0.0)

        diffStats.completed = 3
        diffStats.totalHintsUsed = 9
        #expect(diffStats.averageHints == 3.0)
    }

    @Test func difficultyStatisticsAverageErrors() {
        var diffStats = GameStatistics.DifficultyStatistics()
        #expect(diffStats.averageErrors == 0.0)

        diffStats.completed = 2
        diffStats.totalErrors = 5
        #expect(diffStats.averageErrors == 2.5)
    }

    // MARK: - Streak Tests

    @Test func firstGameStartsStreak() {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)

        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == 1)
    }

    @Test func consecutiveDaysIncrementStreak() {
        var stats = GameStatistics.new()
        let calendar = Calendar.current

        // Day 1
        stats.lastPlayedDate = calendar.date(byAdding: .day, value: -2, to: Date())
        stats.currentStreak = 1
        stats.longestStreak = 1

        // Day 2 (yesterday)
        stats.lastPlayedDate = calendar.date(byAdding: .day, value: -1, to: Date())
        stats.recordGameStarted(difficulty: .easy)

        #expect(stats.currentStreak == 2)
        #expect(stats.longestStreak == 2)
    }

    @Test func samePlayedDateDoesNotChangeStreak() {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)
        let initialStreak = stats.currentStreak

        stats.recordGameStarted(difficulty: .easy)
        #expect(stats.currentStreak == initialStreak)
    }

    @Test func longestStreakIsPreserved() {
        var stats = GameStatistics.new()
        let calendar = Calendar.current

        // Directly set up a state where we had a streak of 3 yesterday
        stats.lastPlayedDate = calendar.date(byAdding: .day, value: -1, to: Date())
        stats.currentStreak = 3
        stats.longestStreak = 3

        let longestBefore = stats.longestStreak
        #expect(longestBefore >= 3)

        // Break the streak (simulate 2+ days gap by backdating lastPlayedDate)
        stats.lastPlayedDate = calendar.date(byAdding: .day, value: -5, to: Date())
        stats.recordGameStarted(difficulty: .easy)

        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == longestBefore) // Should preserve old longest
    }

    @Test func hasActiveStreakWhenPlayedToday() {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)

        #expect(stats.hasActiveStreak())
    }

    @Test func hasActiveStreakWhenPlayedYesterday() {
        var stats = GameStatistics.new()
        let calendar = Calendar.current
        stats.lastPlayedDate = calendar.date(byAdding: .day, value: -1, to: Date())
        stats.currentStreak = 5

        #expect(stats.hasActiveStreak())
    }

    @Test func noActiveStreakWhenPlayedTwoDaysAgo() {
        var stats = GameStatistics.new()
        let calendar = Calendar.current
        stats.lastPlayedDate = calendar.date(byAdding: .day, value: -2, to: Date())
        stats.currentStreak = 5

        #expect(!stats.hasActiveStreak())
    }

    // MARK: - Query Methods Tests

    @Test func statisticsForUnplayedDifficulty() {
        let stats = GameStatistics.new()
        let easyStats = stats.statistics(for: .easy)

        #expect(easyStats.played == 0)
        #expect(easyStats.completed == 0)
    }

    @Test func hasPlayedReturnsFalseForUnplayedDifficulty() {
        let stats = GameStatistics.new()
        #expect(!stats.hasPlayed(difficulty: .easy))
    }

    @Test func hasPlayedReturnsTrueAfterPlaying() {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)

        #expect(stats.hasPlayed(difficulty: .easy))
        #expect(!stats.hasPlayed(difficulty: .medium))
    }

    @Test func difficultiesByPlayCountSortsCorrectly() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameStarted(difficulty: .medium)
        stats.recordGameStarted(difficulty: .hard)
        stats.recordGameStarted(difficulty: .hard)
        stats.recordGameStarted(difficulty: .hard)

        let sorted = stats.difficultiesByPlayCount()
        #expect(sorted.first == .hard) // 3 games
        #expect(sorted.last == .medium) // 1 game
    }

    @Test func mostPlayedDifficultyWithNoGames() {
        let stats = GameStatistics.new()
        #expect(stats.mostPlayedDifficulty() == nil)
    }

    @Test func mostPlayedDifficultyReturnsCorrectValue() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameStarted(difficulty: .medium)

        #expect(stats.mostPlayedDifficulty() == .easy)
    }

    // MARK: - Aggregation Tests

    @Test func totalHintsUsedAcrossDifficulties() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 0)
        stats.recordGameCompleted(difficulty: .medium, time: 400, hintsUsed: 3, errors: 0)
        stats.recordGameCompleted(difficulty: .hard, time: 500, hintsUsed: 5, errors: 0)

        #expect(stats.totalHintsUsed == 10)
    }

    @Test func totalErrorsAcrossDifficulties() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 1)
        stats.recordGameCompleted(difficulty: .medium, time: 400, hintsUsed: 0, errors: 2)
        stats.recordGameCompleted(difficulty: .hard, time: 500, hintsUsed: 0, errors: 3)

        #expect(stats.totalErrors == 6)
    }

    @Test func difficultiesPlayedCount() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameStarted(difficulty: .medium)
        stats.recordGameStarted(difficulty: .hard)

        #expect(stats.difficultiesPlayed == 3)
    }

    // MARK: - Reset Tests

    @Test func resetClearsAllStatistics() {
        var stats = GameStatistics.new()

        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)
        stats.recordGameStarted(difficulty: .medium)

        stats.reset()

        #expect(stats.gamesPlayed == 0)
        #expect(stats.gamesCompleted == 0)
        #expect(stats.totalTimePlayed == 0)
        #expect(stats.bestTime == nil)
        #expect(stats.difficultyBreakdowns.isEmpty)
        #expect(stats.currentStreak == 0)
        #expect(stats.longestStreak == 0)
        #expect(stats.lastPlayedDate == nil)
    }

    // MARK: - Formatting Tests

    @Test func formattedTotalTimeWithMinutes() {
        var stats = GameStatistics.new()
        stats.recordGameCompleted(difficulty: .easy, time: 1800, hintsUsed: 0, errors: 0) // 30 minutes

        #expect(stats.formattedTotalTime == "30m")
    }

    @Test func formattedTotalTimeWithHours() {
        var stats = GameStatistics.new()
        stats.recordGameCompleted(difficulty: .easy, time: 7800, hintsUsed: 0, errors: 0) // 2h 10m

        #expect(stats.formattedTotalTime == "2h 10m")
    }

    @Test func formattedAverageTimeWithNoGames() {
        let stats = GameStatistics.new()
        #expect(stats.formattedAverageTime == nil)
    }

    @Test func formattedAverageTime() {
        var stats = GameStatistics.new()
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 0, errors: 0) // 5:00

        #expect(stats.formattedAverageTime == "05:00")
    }

    @Test func formattedBestTimeWithNoGames() {
        let stats = GameStatistics.new()
        #expect(stats.formattedBestTime == nil)
    }

    @Test func formattedBestTime() {
        var stats = GameStatistics.new()
        stats.recordGameCompleted(difficulty: .easy, time: 185, hintsUsed: 0, errors: 0) // 3:05

        #expect(stats.formattedBestTime == "03:05")
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)

        let encoder = JSONEncoder()
        let data = try encoder.encode(stats)

        #expect(!data.isEmpty)
    }

    @Test func codableDecoding() throws {
        var original = GameStatistics.new()
        original.recordGameStarted(difficulty: .easy)
        original.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(GameStatistics.self, from: data)

        #expect(decoded == original)
    }

    @Test func codableRoundTrip() throws {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)
        stats.recordGameStarted(difficulty: .medium)
        stats.recordGameCompleted(difficulty: .medium, time: 600, hintsUsed: 3, errors: 2)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(stats)
        let decoded = try decoder.decode(GameStatistics.self, from: encoded)

        #expect(decoded.gamesPlayed == stats.gamesPlayed)
        #expect(decoded.gamesCompleted == stats.gamesCompleted)
        #expect(decoded.totalTimePlayed == stats.totalTimePlayed)
        #expect(decoded.bestTime == stats.bestTime)
        #expect(decoded.currentStreak == stats.currentStreak)
        #expect(decoded.longestStreak == stats.longestStreak)
    }

    // MARK: - Equatable Tests

    @Test func equalityWhenEmpty() {
        let stats1 = GameStatistics()
        let stats2 = GameStatistics()

        // Note: createdAt will be different, so they won't be equal
        #expect(stats1.gamesPlayed == stats2.gamesPlayed)
        #expect(stats1.gamesCompleted == stats2.gamesCompleted)
    }

    @Test func equalityAfterSameOperations() {
        let createdDate = Date()
        var stats1 = GameStatistics(createdAt: createdDate)
        var stats2 = GameStatistics(createdAt: createdDate)

        stats1.recordGameStarted(difficulty: .easy)
        stats2.recordGameStarted(difficulty: .easy)

        stats1.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)
        stats2.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)

        // They should be equal if lastPlayedDate matches
        stats1.lastPlayedDate = stats2.lastPlayedDate

        #expect(stats1 == stats2)
    }

    // MARK: - CustomStringConvertible Tests

    @Test func descriptionContainsKeyInfo() {
        var stats = GameStatistics.new()
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 2, errors: 1)

        let description = stats.description

        #expect(description.contains("GameStatistics"))
        #expect(description.contains("games:"))
        #expect(description.contains("winRate:"))
        #expect(description.contains("streak:"))
    }

    // MARK: - Edge Cases

    @Test func multipleGamesMultipleDifficulties() {
        var stats = GameStatistics.new()

        // Play 3 easy games
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 300, hintsUsed: 1, errors: 0)
        stats.recordGameStarted(difficulty: .easy)
        stats.recordGameCompleted(difficulty: .easy, time: 250, hintsUsed: 0, errors: 1)
        stats.recordGameStarted(difficulty: .easy)

        // Play 2 hard games
        stats.recordGameStarted(difficulty: .hard)
        stats.recordGameCompleted(difficulty: .hard, time: 800, hintsUsed: 5, errors: 3)
        stats.recordGameStarted(difficulty: .hard)
        stats.recordGameCompleted(difficulty: .hard, time: 900, hintsUsed: 6, errors: 2)

        #expect(stats.gamesPlayed == 5)
        #expect(stats.gamesCompleted == 4)
        #expect(stats.winRate == 0.8)
        #expect(stats.bestTime == 250)

        let easyStats = stats.statistics(for: .easy)
        #expect(easyStats.played == 3)
        #expect(easyStats.completed == 2)
        #expect(easyStats.bestTime == 250)

        let hardStats = stats.statistics(for: .hard)
        #expect(hardStats.played == 2)
        #expect(hardStats.completed == 2)
        #expect(hardStats.bestTime == 800)
    }

    @Test func veryLargeValues() {
        var stats = GameStatistics.new()

        stats.recordGameCompleted(
            difficulty: .hard,
            time: 36000, // 10 hours
            hintsUsed: 100,
            errors: 50
        )

        #expect(stats.totalTimePlayed == 36000)
        #expect(stats.totalHintsUsed == 100)
        #expect(stats.totalErrors == 50)
    }
}
