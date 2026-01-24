import XCTest
@testable import TennerGrid

/// Tests for AchievementManager service
// swiftlint:disable:next type_body_length
final class AchievementManagerTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    var sut: AchievementManager!
    var mockStatistics: StatisticsManager!
    // swiftlint:enable implicitly_unwrapped_optional
    let testSuiteName = "AchievementManagerTests"

    override func setUp() {
        super.setUp()
        // Use a custom UserDefaults suite for testing to avoid interfering with app data
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        defaults.removePersistentDomain(forName: testSuiteName)

        mockStatistics = StatisticsManager.test(userDefaults: defaults)
        sut = AchievementManager.test(statisticsManager: mockStatistics, userDefaults: defaults)
    }

    override func tearDown() {
        sut = nil
        mockStatistics = nil
        // Clean up test UserDefaults
        let defaults = UserDefaults(suiteName: testSuiteName)
        defaults?.removePersistentDomain(forName: testSuiteName)
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_LoadsDefaultAchievements() {
        // Then
        XCTAssertFalse(sut.achievements.isEmpty, "Should load default achievements")
        XCTAssertEqual(sut.achievements.count, Achievement.allAchievements.count)
    }

    func testInitialization_AllAchievementsStartLocked() {
        // Then
        let unlockedAchievements = sut.achievements.filter(\.isUnlocked)
        XCTAssertTrue(unlockedAchievements.isEmpty, "All achievements should start locked")
    }

    // MARK: - Achievement Retrieval Tests

    func testGetAchievementById_ExistingAchievement_ReturnsAchievement() {
        // When
        let achievement = sut.achievement(withId: "first_game")

        // Then
        XCTAssertNotNil(achievement)
        XCTAssertEqual(achievement?.title, "First Steps")
    }

    func testGetAchievementById_NonExistentAchievement_ReturnsNil() {
        // When
        let achievement = sut.achievement(withId: "nonexistent")

        // Then
        XCTAssertNil(achievement)
    }

    func testGetAchievementsByCategory_ReturnsCorrectAchievements() {
        // When
        let gamesAchievements = sut.achievements(in: .games)

        // Then
        XCTAssertFalse(gamesAchievements.isEmpty)
        XCTAssertTrue(gamesAchievements.allSatisfy { $0.category == .games })
    }

    func testUnlockedAchievements_InitiallyEmpty() {
        // When
        let unlocked = sut.unlockedAchievements()

        // Then
        XCTAssertTrue(unlocked.isEmpty)
    }

    func testLockedAchievements_InitiallyAll() {
        // When
        let locked = sut.lockedAchievements()

        // Then
        XCTAssertEqual(locked.count, Achievement.allAchievements.count)
    }

    // MARK: - First Game Achievement Tests

    func testCheckAchievements_FirstGameCompleted_UnlocksFirstGame() {
        // Given
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)
        gameState.isCompleted = true
        mockStatistics.recordCompletion(gameState: gameState)

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertEqual(newlyUnlocked.count, 1)
        XCTAssertEqual(newlyUnlocked.first?.id, "first_game")
        XCTAssertTrue(sut.achievement(withId: "first_game")?.isUnlocked ?? false)
    }

    func testCheckAchievements_NoGamesCompleted_NoUnlocks() {
        // When
        let newlyUnlocked = sut.checkAchievements()

        // Then
        XCTAssertTrue(newlyUnlocked.isEmpty)
    }

    // MARK: - Progressive Achievement Tests

    func testCheckAchievements_10GamesCompleted_UnlocksGames10() {
        // Given
        completeGames(count: 10, difficulty: .easy)

        // When
        let newlyUnlocked = sut.checkAchievements()

        // Then
        let games10 = sut.achievement(withId: "games_10")
        XCTAssertTrue(games10?.isUnlocked ?? false)
        XCTAssertEqual(games10?.progress, 1.0)
    }

    func testCheckAchievements_5GamesCompleted_PartialProgress() {
        // Given
        completeGames(count: 5, difficulty: .easy)

        // When
        sut.checkAchievements()

        // Then
        let games10 = sut.achievement(withId: "games_10")
        XCTAssertNotNil(games10)
        XCTAssertFalse(games10?.isUnlocked ?? true)
        XCTAssertEqual(games10?.progress ?? 0.0, 0.5, accuracy: 0.01)
    }

    func testUpdateProgress_ProgressesAchievement() {
        // When
        let wasUnlocked = sut.updateProgress(achievementId: "games_10", currentValue: 5)

        // Then
        XCTAssertFalse(wasUnlocked)
        let achievement = sut.achievement(withId: "games_10")
        XCTAssertNotNil(achievement)
        XCTAssertEqual(achievement?.progress ?? 0.0, 0.5, accuracy: 0.01)
        XCTAssertEqual(achievement?.currentValue ?? 0, 5)
    }

    func testUpdateProgress_ReachesTarget_UnlocksAchievement() {
        // When
        let wasUnlocked = sut.updateProgress(achievementId: "games_10", currentValue: 10)

        // Then
        XCTAssertTrue(wasUnlocked)
        let achievement = sut.achievement(withId: "games_10")
        XCTAssertTrue(achievement?.isUnlocked ?? false)
        XCTAssertEqual(achievement?.progress, 1.0)
    }

    func testUpdateProgress_InvalidAchievementId_ReturnsFalse() {
        // When
        let wasUnlocked = sut.updateProgress(achievementId: "nonexistent", currentValue: 10)

        // Then
        XCTAssertFalse(wasUnlocked)
    }

    // MARK: - Difficulty Master Achievement Tests

    // swiftlint:disable:next inclusive_language
    func testCheckAchievements_10EasyGames_UnlocksEasyMaster() {
        // Given
        completeGames(count: 10, difficulty: .easy)

        // When
        sut.checkAchievements()

        // Then
        XCTAssertTrue(sut.achievement(withId: "easy_master")?.isUnlocked ?? false)
    }

    // swiftlint:disable:next inclusive_language
    func testCheckAchievements_10MediumGames_UnlocksMediumMaster() {
        // Given
        completeGames(count: 10, difficulty: .medium)

        // When
        sut.checkAchievements()

        // Then
        XCTAssertTrue(sut.achievement(withId: "medium_master")?.isUnlocked ?? false)
    }

    // swiftlint:disable:next inclusive_language
    func testCheckAchievements_10HardGames_UnlocksHardMaster() {
        // Given
        completeGames(count: 10, difficulty: .hard)

        // When
        sut.checkAchievements()

        // Then
        XCTAssertTrue(sut.achievement(withId: "hard_master")?.isUnlocked ?? false)
    }

    // MARK: - Speed Achievement Tests

    func testCheckAchievements_EasyUnder3Minutes_UnlocksQuickThinker() {
        // Given
        let puzzle = createTestPuzzle(difficulty: .easy)
        var gameState = GameState(puzzle: puzzle)
        gameState.elapsedTime = 170 // 2:50
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertTrue(newlyUnlocked.contains(where: { $0.id == "speed_easy" }))
    }

    func testCheckAchievements_EasyOver3Minutes_NoSpeedAchievement() {
        // Given
        let puzzle = createTestPuzzle(difficulty: .easy)
        var gameState = GameState(puzzle: puzzle)
        gameState.elapsedTime = 200 // 3:20
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertFalse(newlyUnlocked.contains(where: { $0.id == "speed_easy" }))
    }

    func testCheckAchievements_MediumUnder5Minutes_UnlocksSpeedDemon() {
        // Given
        let puzzle = createTestPuzzle(difficulty: .medium)
        var gameState = GameState(puzzle: puzzle)
        gameState.elapsedTime = 290 // 4:50
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertTrue(newlyUnlocked.contains(where: { $0.id == "speed_medium" }))
    }

    func testCheckAchievements_HardUnder10Minutes_UnlocksLightningFast() {
        // Given
        let puzzle = createTestPuzzle(difficulty: .hard)
        var gameState = GameState(puzzle: puzzle)
        gameState.elapsedTime = 590 // 9:50
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertTrue(newlyUnlocked.contains(where: { $0.id == "speed_hard" }))
    }

    // MARK: - Mastery Achievement Tests

    func testCheckAchievements_NoHintsUsed_UnlocksNoHints() {
        // Given
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)
        gameState.hintsUsed = 0
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertTrue(newlyUnlocked.contains(where: { $0.id == "no_hints" }))
    }

    func testCheckAchievements_HintsUsed_NoNoHintsAchievement() {
        // Given
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)
        gameState.hintsUsed = 1
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertFalse(newlyUnlocked.contains(where: { $0.id == "no_hints" }))
    }

    func testCheckAchievements_NoErrors_UnlocksPerfectGame() {
        // Given
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)
        gameState.errorCount = 0
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertTrue(newlyUnlocked.contains(where: { $0.id == "perfect_game" }))
    }

    func testCheckAchievements_WithErrors_NoPerfectGame() {
        // Given
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)
        gameState.errorCount = 1
        gameState.isCompleted = true

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertFalse(newlyUnlocked.contains(where: { $0.id == "perfect_game" }))
    }

    // MARK: - Streak Achievement Tests

    func testCheckAchievements_3DayStreak_UnlocksOnFire() {
        // Given
        mockStatistics.updateStreak(newStreak: 3)

        // When
        sut.checkAchievements()

        // Then
        XCTAssertTrue(sut.achievement(withId: "streak_3")?.isUnlocked ?? false)
    }

    func testCheckAchievements_7DayStreak_UnlocksWeekWarrior() {
        // Given
        mockStatistics.updateStreak(newStreak: 7)

        // When
        sut.checkAchievements()

        // Then
        XCTAssertTrue(sut.achievement(withId: "streak_7")?.isUnlocked ?? false)
    }

    // swiftlint:disable:next inclusive_language
    func testCheckAchievements_30DayStreak_UnlocksMonthlyMaster() {
        // Given
        mockStatistics.updateStreak(newStreak: 30)

        // When
        sut.checkAchievements()

        // Then
        XCTAssertTrue(sut.achievement(withId: "streak_30")?.isUnlocked ?? false)
    }

    // MARK: - Points and Completion Tests

    func testTotalPointsEarned_NoUnlocks_ReturnsZero() {
        // When
        let points = sut.totalPointsEarned()

        // Then
        XCTAssertEqual(points, 0)
    }

    func testTotalPointsEarned_SomeUnlocks_ReturnsSum() {
        // Given
        completeGames(count: 1, difficulty: .easy)
        sut.checkAchievements()

        // When
        let points = sut.totalPointsEarned()

        // Then
        XCTAssertGreaterThan(points, 0)
    }

    func testTotalPossiblePoints_ReturnsCorrectSum() {
        // When
        let points = sut.totalPossiblePoints()

        // Then
        let expectedPoints = Achievement.allAchievements.reduce(0) { $0 + $1.points }
        XCTAssertEqual(points, expectedPoints)
    }

    func testCompletionPercentage_NoUnlocks_ReturnsZero() {
        // When
        let percentage = sut.completionPercentage()

        // Then
        XCTAssertEqual(percentage, 0.0)
    }

    func testCompletionPercentage_AllUnlocked_ReturnsOne() {
        // Given
        unlockAllAchievements()

        // When
        let percentage = sut.completionPercentage()

        // Then
        XCTAssertEqual(percentage, 1.0, accuracy: 0.01)
    }

    // MARK: - Persistence Tests

    func testPersistence_SavesUnlockedAchievements() {
        // Given
        completeGames(count: 1, difficulty: .easy)
        sut.checkAchievements()

        // When - Create new instance to force reload
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        let newStatsManager = StatisticsManager.test(userDefaults: defaults)
        let newManager = AchievementManager.test(statisticsManager: newStatsManager, userDefaults: defaults)

        // Then
        XCTAssertTrue(newManager.achievement(withId: "first_game")?.isUnlocked ?? false)
    }

    func testPersistence_SavesProgress() {
        // Given
        sut.updateProgress(achievementId: "games_10", currentValue: 5)

        // When - Create new instance to force reload
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        let newStatsManager = StatisticsManager.test(userDefaults: defaults)
        let newManager = AchievementManager.test(statisticsManager: newStatsManager, userDefaults: defaults)

        // Then
        let achievement = newManager.achievement(withId: "games_10")
        XCTAssertNotNil(achievement)
        XCTAssertEqual(achievement?.progress ?? 0.0, 0.5, accuracy: 0.01)
    }

    func testPersistence_SavesUnlockDate() {
        // Given
        completeGames(count: 1, difficulty: .easy)
        sut.checkAchievements()
        let originalDate = sut.achievement(withId: "first_game")?.unlockedAt

        // When - Create new instance to force reload
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        let newStatsManager = StatisticsManager.test(userDefaults: defaults)
        let newManager = AchievementManager.test(statisticsManager: newStatsManager, userDefaults: defaults)

        // Then
        let loadedDate = newManager.achievement(withId: "first_game")?.unlockedAt
        XCTAssertNotNil(loadedDate)
        XCTAssertNotNil(originalDate)
        XCTAssertEqual(
            originalDate?.timeIntervalSince1970 ?? 0.0,
            loadedDate?.timeIntervalSince1970 ?? 0.0,
            accuracy: 1.0
        )
    }

    func testPersistence_MergesNewAchievements() {
        // Given - Save current achievements
        completeGames(count: 1, difficulty: .easy)
        sut.checkAchievements()

        // Simulate app update with new achievements by reloading
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        let newStatsManager = StatisticsManager.test(userDefaults: defaults)
        let newManager = AchievementManager.test(statisticsManager: newStatsManager, userDefaults: defaults)

        // Then - Should have all current achievements plus any new ones
        XCTAssertEqual(newManager.achievements.count, Achievement.allAchievements.count)
        XCTAssertTrue(newManager.achievement(withId: "first_game")?.isUnlocked ?? false)
    }

    func testResetAllAchievements_ResetsAndPersists() {
        // Given
        completeGames(count: 1, difficulty: .easy)
        sut.checkAchievements()

        // When
        sut.resetAllAchievements()

        // Then
        XCTAssertTrue(sut.unlockedAchievements().isEmpty)

        // Verify persistence
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        let newStatsManager = StatisticsManager.test(userDefaults: defaults)
        let newManager = AchievementManager.test(statisticsManager: newStatsManager, userDefaults: defaults)
        XCTAssertTrue(newManager.unlockedAchievements().isEmpty)
    }

    // MARK: - Edge Cases

    func testCheckAchievements_AlreadyUnlocked_NoReunlock() {
        // Given
        completeGames(count: 1, difficulty: .easy)
        let firstCheck = sut.checkAchievements()
        XCTAssertEqual(firstCheck.count, 1)

        // When
        let secondCheck = sut.checkAchievements()

        // Then
        XCTAssertTrue(secondCheck.isEmpty, "Should not re-unlock already unlocked achievements")
    }

    func testCheckAchievements_IncompleteGame_NoUnlock() {
        // Given
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)
        gameState.isCompleted = false

        // When
        let newlyUnlocked = sut.checkAchievements(gameState: gameState)

        // Then
        XCTAssertTrue(newlyUnlocked.isEmpty)
    }

    // MARK: - Helper Methods

    private func createTestPuzzle(difficulty: Difficulty = .easy) -> TennerGridPuzzle {
        TennerGridPuzzle(
            id: UUID(),
            columns: 10,
            rows: 5,
            difficulty: difficulty,
            targetSums: Array(repeating: 25, count: 10),
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 5),
            solution: Array(repeating: Array(repeating: 5, count: 10), count: 5)
        )
    }

    private func completeGames(count: Int, difficulty: Difficulty) {
        for _ in 0 ..< count {
            let puzzle = createTestPuzzle(difficulty: difficulty)
            var gameState = GameState(puzzle: puzzle)
            gameState.isCompleted = true
            mockStatistics.recordCompletion(gameState: gameState)
        }
    }

    private func unlockAllAchievements() {
        for achievement in sut.achievements {
            sut.updateProgress(achievementId: achievement.id, currentValue: achievement.targetValue)
        }
    }
}
