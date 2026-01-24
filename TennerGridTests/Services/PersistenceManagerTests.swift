import XCTest
@testable import TennerGrid

/// Tests for PersistenceManager focusing on save/load functionality
/// including force-quit and app restart scenarios
// swiftlint:disable:next type_body_length
final class PersistenceManagerTests: XCTestCase {
    // MARK: - Properties

    private var persistenceManager: PersistenceManager {
        PersistenceManager.shared
    }

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Clean up any existing test data
        _ = persistenceManager.deleteAll()
    }

    override func tearDown() {
        super.tearDown()

        // Clean up test data
        _ = persistenceManager.deleteAll()
    }

    // MARK: - Basic Save/Load Tests

    func testSaveAndLoadGame() throws {
        // Given: A game state
        let puzzle = TestFixtures.easyPuzzle
        var gameState = GameState(puzzle: puzzle)
        gameState.setValue(5, at: CellPosition(row: 0, column: 0))
        gameState.elapsedTime = 120.0

        // When: We save the game
        try persistenceManager.saveGame(gameState)

        // Then: We should be able to load it back
        let loadedState = try persistenceManager.loadGame()
        XCTAssertNotNil(loadedState)
        XCTAssertEqual(loadedState?.puzzle.id, gameState.puzzle.id)
        if let elapsed = loadedState?.elapsedTime {
            XCTAssertEqual(elapsed, gameState.elapsedTime, accuracy: 0.1)
        } else {
            XCTFail("Elapsed time should not be nil")
        }
        XCTAssertEqual(loadedState?.value(at: CellPosition(row: 0, column: 0)), 5)
    }

    func testLoadGameWhenNoSaveExists() throws {
        // Given: No saved game exists
        XCTAssertFalse(persistenceManager.hasSavedGame())

        // When: We try to load a game
        let loadedState = try persistenceManager.loadGame()

        // Then: Should return nil
        XCTAssertNil(loadedState)
    }

    func testHasSavedGameReturnsTrueAfterSave() throws {
        // Given: No initial save
        XCTAssertFalse(persistenceManager.hasSavedGame())

        // When: We save a game
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        try persistenceManager.saveGame(gameState)

        // Then: hasSavedGame should return true
        XCTAssertTrue(persistenceManager.hasSavedGame())
    }

    func testDeleteSavedGame() throws {
        // Given: A saved game
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        try persistenceManager.saveGame(gameState)
        XCTAssertTrue(persistenceManager.hasSavedGame())

        // When: We delete the saved game
        try persistenceManager.deleteSavedGame()

        // Then: hasSavedGame should return false
        XCTAssertFalse(persistenceManager.hasSavedGame())
    }

    // MARK: - Force Quit Simulation Tests

    func testSaveLoadAfterForceQuitSimulation() throws {
        // This test simulates:
        // 1. User plays game
        // 2. App backgrounds and auto-saves
        // 3. User force-quits app
        // 4. User relaunches app
        // 5. Game state should be restored

        // Step 1 & 2: Create and save game state (simulating auto-save)
        let puzzle = TestFixtures.easyPuzzle
        var gameState = GameState(puzzle: puzzle)

        // Find empty cells to fill (avoid pre-filled cells)
        var testPositions: [CellPosition] = []
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if puzzle.initialGrid[row][col] == nil {
                    testPositions.append(pos)
                    if testPositions.count >= 3 { break }
                }
            }
            if testPositions.count >= 3 { break }
        }

        // Simulate some gameplay on empty cells
        gameState.setValue(3, at: testPositions[0])
        gameState.setValue(7, at: testPositions[1])
        gameState.setValue(5, at: testPositions[2])
        gameState.elapsedTime = 245.5

        // Save (simulating handleAppBackground)
        try persistenceManager.saveGame(gameState)

        // Step 3 & 4: Simulate force quit by creating a new persistence manager
        // (In real app, this is when app is relaunched)
        let newPersistenceManager = PersistenceManager.shared

        // Step 5: Load the saved game
        let restoredState = try newPersistenceManager.loadGame()

        // Verify all state is restored correctly
        XCTAssertNotNil(restoredState, "Game state should be restored after force quit")
        XCTAssertEqual(restoredState?.puzzle.id, gameState.puzzle.id)
        if let elapsed = restoredState?.elapsedTime {
            XCTAssertEqual(elapsed, gameState.elapsedTime, accuracy: 0.1)
        } else {
            XCTFail("Elapsed time should not be nil")
        }
        XCTAssertEqual(restoredState?.value(at: testPositions[0]), 3)
        XCTAssertEqual(restoredState?.value(at: testPositions[1]), 7)
        XCTAssertEqual(restoredState?.value(at: testPositions[2]), 5)
    }

    func testComplexGameStatePreservationAcrossRestart() throws {
        // Create a complex game state with multiple features
        let puzzle = TestFixtures.easyPuzzle
        var gameState = GameState(puzzle: puzzle)

        // Find empty cells for testing
        var emptyPositions: [CellPosition] = []
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if puzzle.initialGrid[row][col] == nil {
                    emptyPositions.append(pos)
                    if emptyPositions.count >= 4 { break }
                }
            }
            if emptyPositions.count >= 4 { break }
        }

        // Add various state elements using empty cells
        gameState.setValue(2, at: emptyPositions[0])
        gameState.setValue(8, at: emptyPositions[1])
        gameState.setValue(4, at: emptyPositions[2])

        // Add pencil marks to another empty cell
        gameState.togglePencilMark(1, at: emptyPositions[3])
        gameState.togglePencilMark(3, at: emptyPositions[3])
        gameState.togglePencilMark(5, at: emptyPositions[3])

        // Set timing
        gameState.elapsedTime = 567.8

        // Track hints used
        gameState.hintsUsed = 3

        // Save the state
        try persistenceManager.saveGame(gameState)

        // Simulate app restart
        let restoredState = try PersistenceManager.shared.loadGame()

        // Verify all complex state is preserved
        XCTAssertNotNil(restoredState)
        guard let restored = restoredState else {
            XCTFail("Failed to restore game state")
            return
        }

        // Verify cell values
        XCTAssertEqual(restored.value(at: emptyPositions[0]), 2)
        XCTAssertEqual(restored.value(at: emptyPositions[1]), 8)
        XCTAssertEqual(restored.value(at: emptyPositions[2]), 4)

        // Verify pencil marks
        let pencilMarks = restored.marks(at: emptyPositions[3])
        XCTAssertTrue(pencilMarks.contains(1))
        XCTAssertTrue(pencilMarks.contains(3))
        XCTAssertTrue(pencilMarks.contains(5))
        XCTAssertFalse(pencilMarks.contains(2))

        // Verify timing
        XCTAssertEqual(restored.elapsedTime, 567.8, accuracy: 0.1)

        // Verify hints
        XCTAssertEqual(restored.hintsUsed, 3)
    }

    func testMultipleSavesWithDifferentStates() throws {
        // Simulate multiple play sessions with saves
        let puzzle = TestFixtures.easyPuzzle
        var gameState = GameState(puzzle: puzzle)

        // First save - early game
        gameState.setValue(5, at: CellPosition(row: 0, column: 0))
        gameState.elapsedTime = 30.0
        try persistenceManager.saveGame(gameState)

        // Verify first save
        var loaded = try persistenceManager.loadGame()
        if let elapsed = loaded?.elapsedTime {
            XCTAssertEqual(elapsed, 30.0, accuracy: 0.1)
        } else {
            XCTFail("Elapsed time should not be nil")
        }
        XCTAssertEqual(loaded?.value(at: CellPosition(row: 0, column: 0)), 5)

        // Second save - more progress
        gameState.setValue(8, at: CellPosition(row: 0, column: 1))
        gameState.setValue(2, at: CellPosition(row: 1, column: 0))
        gameState.elapsedTime = 90.0
        try persistenceManager.saveGame(gameState)

        // Verify second save overwrites first
        loaded = try persistenceManager.loadGame()
        if let elapsed = loaded?.elapsedTime {
            XCTAssertEqual(elapsed, 90.0, accuracy: 0.1)
        } else {
            XCTFail("Elapsed time should not be nil")
        }
        XCTAssertEqual(loaded?.value(at: CellPosition(row: 0, column: 1)), 8)
        XCTAssertEqual(loaded?.value(at: CellPosition(row: 1, column: 0)), 2)

        // Third save - near completion
        gameState.elapsedTime = 180.0
        try persistenceManager.saveGame(gameState)

        // Verify third save
        loaded = try persistenceManager.loadGame()
        if let elapsed = loaded?.elapsedTime {
            XCTAssertEqual(elapsed, 180.0, accuracy: 0.1)
        } else {
            XCTFail("Elapsed time should not be nil")
        }
    }

    // MARK: - Statistics Persistence Tests

    func testSaveAndLoadStatistics() throws {
        // Given: Statistics with game data
        var statistics = GameStatistics()
        statistics.recordGameStarted(difficulty: .easy)
        statistics.recordGameCompleted(difficulty: .easy, time: 120, hintsUsed: 2, errors: 1)

        // When: We save and load statistics
        try persistenceManager.saveStatistics(statistics)
        let loaded = try persistenceManager.loadStatistics()

        // Then: Statistics should match
        XCTAssertEqual(loaded.gamesPlayed, 1)
        XCTAssertEqual(loaded.gamesCompleted, 1)
    }

    // MARK: - Achievements Persistence Tests

    func testSaveAndLoadAchievements() throws {
        // Given: Modified achievements
        var achievements = Achievement.allAchievements
        achievements[0].unlock()

        // When: We save and load achievements
        try persistenceManager.saveAchievements(achievements)
        let loaded = try persistenceManager.loadAchievements()

        // Then: Achievements should match
        XCTAssertEqual(loaded.count, achievements.count)
        XCTAssertTrue(loaded[0].isUnlocked)
    }

    // MARK: - Settings Persistence Tests

    func testSaveAndLoadSettings() throws {
        // Given: Modified settings
        var settings = UserSettings()
        settings.autoCheckErrors = false
        settings.showTimer = false

        // When: We save and load settings
        try persistenceManager.saveSettings(settings)
        let loaded = try persistenceManager.loadSettings()

        // Then: Settings should match
        XCTAssertEqual(loaded.autoCheckErrors, false)
        XCTAssertEqual(loaded.showTimer, false)
    }

    // MARK: - Bulk Operations Tests

    func testSaveAllAndLoadAll() throws {
        // Given: Complete app state
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)

        var statistics = GameStatistics()
        statistics.recordGameStarted(difficulty: .easy)

        var achievements = Achievement.allAchievements
        achievements[0].unlock()

        var settings = UserSettings()
        settings.autoCheckErrors = false

        // When: We save all data
        let saveErrors = persistenceManager.saveAll(
            gameState: gameState,
            statistics: statistics,
            achievements: achievements,
            settings: settings
        )

        // Then: No errors should occur
        XCTAssertTrue(saveErrors.isEmpty, "Save all should succeed without errors")

        // When: We load all data
        let appData = try persistenceManager.loadAll()

        // Then: All data should be present
        XCTAssertNotNil(appData.gameState)
        XCTAssertEqual(appData.statistics.gamesPlayed, 1)
        XCTAssertTrue(appData.achievements[0].isUnlocked)
        XCTAssertEqual(appData.settings.autoCheckErrors, false)
    }

    func testDeleteAll() throws {
        // Given: Saved data of all types
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        try persistenceManager.saveGame(gameState)
        try persistenceManager.saveStatistics(GameStatistics())
        try persistenceManager.saveAchievements(Achievement.allAchievements)
        try persistenceManager.saveSettings(UserSettings())

        XCTAssertTrue(persistenceManager.hasSavedGame())

        // When: We delete all data
        let errors = persistenceManager.deleteAll()

        // Then: No errors should occur and no data should exist
        XCTAssertTrue(errors.isEmpty)
        XCTAssertFalse(persistenceManager.hasSavedGame())
    }

    // MARK: - File Info Tests

    func testGetFileInfo() throws {
        // Given: A saved game
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        try persistenceManager.saveGame(gameState)

        // When: We get file info
        let fileInfo = persistenceManager.getFileInfo()

        // Then: File info should show saved game exists
        XCTAssertNotNil(fileInfo["savedGame"])
        XCTAssertTrue(fileInfo["savedGame"]?.exists ?? false)
        XCTAssertNotNil(fileInfo["savedGame"]?.size)
        XCTAssertNotNil(fileInfo["savedGame"]?.modificationDate)
    }

    func testTotalDataSize() throws {
        // Given: Multiple saved files
        try persistenceManager.saveGame(GameState(puzzle: TestFixtures.easyPuzzle))
        try persistenceManager.saveStatistics(GameStatistics())

        // When: We check total data size
        let totalSize = persistenceManager.totalDataSize
        let formattedSize = persistenceManager.formattedTotalDataSize

        // Then: Size should be greater than 0
        XCTAssertGreaterThan(totalSize, 0)
        XCTAssertFalse(formattedSize.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testCorruptedDataHandling() throws {
        // Given: A corrupted save file (invalid JSON)
        let corruptedData = Data("This is not valid JSON".utf8)
        try corruptedData.write(to: PersistenceSchema.FilePath.savedGame)

        // When: We try to load the game
        // Then: Should throw a decoding error
        XCTAssertThrowsError(try persistenceManager.loadGame()) { error in
            XCTAssertTrue(error is PersistenceError)
            if case .decodingFailed = error as? PersistenceError {
                // Expected error
            } else {
                XCTFail("Expected decodingFailed error, got \(error)")
            }
        }
    }

    func testSafeLoadHandlesCorruptedJSON() throws {
        // Given: A corrupted save file with invalid JSON
        let corruptedData = Data("This is not valid JSON".utf8)
        try corruptedData.write(to: PersistenceSchema.FilePath.savedGame)

        // Verify file exists before loading
        XCTAssertTrue(persistenceManager.hasSavedGame())

        // When: We use safe loading
        let result = persistenceManager.loadGameSafely()

        // Then: Should return nil and delete the corrupted file
        XCTAssertNil(result, "Should return nil for corrupted data")
        XCTAssertFalse(persistenceManager.hasSavedGame(), "Corrupted file should be deleted")
    }

    func testSafeLoadHandlesEmptyFile() throws {
        // Given: An empty save file
        let emptyData = Data()
        try emptyData.write(to: PersistenceSchema.FilePath.savedGame)

        // Verify file exists
        XCTAssertTrue(persistenceManager.hasSavedGame())

        // When: We use safe loading
        let result = persistenceManager.loadGameSafely()

        // Then: Should return nil and delete the corrupted file
        XCTAssertNil(result, "Should return nil for empty file")
        XCTAssertFalse(persistenceManager.hasSavedGame(), "Empty file should be deleted")
    }

    func testSafeLoadHandlesTruncatedJSON() throws {
        // Given: A truncated JSON file (incomplete)
        let truncatedJSON = """
        {"gameState":{"puzzle":{"id":"test","rows":3
        """
        let truncatedData = Data(truncatedJSON.utf8)
        try truncatedData.write(to: PersistenceSchema.FilePath.savedGame)

        // Verify file exists
        XCTAssertTrue(persistenceManager.hasSavedGame())

        // When: We use safe loading
        let result = persistenceManager.loadGameSafely()

        // Then: Should return nil and delete the corrupted file
        XCTAssertNil(result, "Should return nil for truncated JSON")
        XCTAssertFalse(persistenceManager.hasSavedGame(), "Truncated file should be deleted")
    }

    func testSafeLoadHandlesIncompatibleSchema() throws {
        // Given: A JSON file with incompatible schema (old version)
        let incompatibleJSON = """
        {"oldField":"value","anotherOldField":123}
        """
        let incompatibleData = Data(incompatibleJSON.utf8)
        try incompatibleData.write(to: PersistenceSchema.FilePath.savedGame)

        // Verify file exists
        XCTAssertTrue(persistenceManager.hasSavedGame())

        // When: We use safe loading
        let result = persistenceManager.loadGameSafely()

        // Then: Should return nil and delete the incompatible file
        XCTAssertNil(result, "Should return nil for incompatible schema")
        XCTAssertFalse(persistenceManager.hasSavedGame(), "Incompatible file should be deleted")
    }

    func testSafeLoadHandlesValidData() throws {
        // Given: A valid saved game
        let puzzle = TestFixtures.easyPuzzle
        var gameState = GameState(puzzle: puzzle)
        gameState.setValue(5, at: CellPosition(row: 0, column: 0))
        gameState.elapsedTime = 120.0
        try persistenceManager.saveGame(gameState)

        // When: We use safe loading
        let result = persistenceManager.loadGameSafely()

        // Then: Should return the game state successfully
        XCTAssertNotNil(result, "Should return game state for valid data")
        XCTAssertTrue(persistenceManager.hasSavedGame(), "Valid file should not be deleted")
        XCTAssertEqual(result?.puzzle.id, gameState.puzzle.id)
        XCTAssertEqual(result?.value(at: CellPosition(row: 0, column: 0)), 5)
    }

    func testSafeLoadHandlesNonExistentFile() {
        // Given: No saved game exists
        XCTAssertFalse(persistenceManager.hasSavedGame())

        // When: We use safe loading
        let result = persistenceManager.loadGameSafely()

        // Then: Should return nil without errors
        XCTAssertNil(result, "Should return nil when no file exists")
        XCTAssertFalse(persistenceManager.hasSavedGame())
    }

    func testSafeLoadStatisticsHandlesCorruption() throws {
        // Given: Corrupted statistics file
        let corruptedData = Data("Invalid statistics data".utf8)
        try corruptedData.write(to: PersistenceSchema.FilePath.statistics)

        // When: We use safe loading
        let result = persistenceManager.loadStatisticsSafely()

        // Then: Should return default statistics and delete corrupted file
        XCTAssertEqual(result.gamesPlayed, 0, "Should return default statistics")
        XCTAssertEqual(result.gamesCompleted, 0, "Should return default statistics")
    }

    func testSafeLoadAchievementsHandlesCorruption() throws {
        // Given: Corrupted achievements file
        let corruptedData = Data("Invalid achievements data".utf8)
        try corruptedData.write(to: PersistenceSchema.FilePath.achievements)

        // When: We use safe loading
        let result = persistenceManager.loadAchievementsSafely()

        // Then: Should return default achievements and delete corrupted file
        XCTAssertFalse(result.isEmpty, "Should return default achievements")
        XCTAssertEqual(result.count, Achievement.allAchievements.count)
    }

    func testSafeLoadSettingsHandlesCorruption() throws {
        // Given: Corrupted settings file
        let corruptedData = Data("Invalid settings data".utf8)
        try corruptedData.write(to: PersistenceSchema.FilePath.settings)

        // When: We use safe loading
        let result = persistenceManager.loadSettingsSafely()

        // Then: Should return default settings and delete corrupted file
        XCTAssertTrue(result.autoCheckErrors, "Should return default settings")
        XCTAssertTrue(result.showTimer, "Should return default settings")
    }

    func testSafeLoadAllHandlesPartialCorruption() throws {
        // Given: Some files are valid, some are corrupted
        // Valid game state
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        try persistenceManager.saveGame(gameState)

        // Valid statistics
        var statistics = GameStatistics()
        statistics.recordGameStarted(difficulty: .easy)
        try persistenceManager.saveStatistics(statistics)

        // Corrupted achievements
        let corruptedData = Data("Invalid".utf8)
        try corruptedData.write(to: PersistenceSchema.FilePath.achievements)

        // Corrupted settings
        try corruptedData.write(to: PersistenceSchema.FilePath.settings)

        // When: We use safe bulk loading
        let appData = persistenceManager.loadAllSafely()

        // Then: Valid data should be loaded, corrupted data should use defaults
        XCTAssertNotNil(appData.gameState, "Valid game state should load")
        XCTAssertEqual(appData.statistics.gamesPlayed, 1, "Valid statistics should load")
        XCTAssertFalse(appData.achievements.isEmpty, "Should return default achievements")
        XCTAssertTrue(appData.settings.autoCheckErrors, "Should return default settings")
    }

    func testSafeLoadAllWithNoData() {
        // Given: No saved data exists
        XCTAssertFalse(persistenceManager.hasSavedGame())

        // When: We use safe bulk loading
        let appData = persistenceManager.loadAllSafely()

        // Then: Should return all defaults without errors
        XCTAssertNil(appData.gameState)
        XCTAssertEqual(appData.statistics.gamesPlayed, 0)
        XCTAssertFalse(appData.achievements.isEmpty)
        XCTAssertTrue(appData.settings.autoCheckErrors)
    }

    func testRecoveryFromMultipleCorruptedFiles() throws {
        // Given: All files are corrupted
        let corruptedData = Data("Corrupted".utf8)
        try corruptedData.write(to: PersistenceSchema.FilePath.savedGame)
        try corruptedData.write(to: PersistenceSchema.FilePath.statistics)
        try corruptedData.write(to: PersistenceSchema.FilePath.achievements)
        try corruptedData.write(to: PersistenceSchema.FilePath.settings)

        // When: We attempt to load each piece of data safely
        let gameState = persistenceManager.loadGameSafely()
        let statistics = persistenceManager.loadStatisticsSafely()
        let achievements = persistenceManager.loadAchievementsSafely()
        let settings = persistenceManager.loadSettingsSafely()

        // Then: All should return defaults and app should be usable
        XCTAssertNil(gameState, "Corrupted game should return nil")
        XCTAssertEqual(statistics.gamesPlayed, 0, "Should return default statistics")
        XCTAssertFalse(achievements.isEmpty, "Should return default achievements")
        XCTAssertTrue(settings.autoCheckErrors, "Should return default settings")

        // Verify corrupted files were deleted
        XCTAssertFalse(persistenceManager.hasSavedGame(), "Corrupted game file should be deleted")
    }

    // MARK: - Integration Test: Complete App Lifecycle

    func testCompleteAppLifecycle() throws {
        // Simulates: Launch → Play → Background → Force Quit → Relaunch → Resume

        // === First Launch ===
        // No saved game should exist
        XCTAssertFalse(persistenceManager.hasSavedGame())

        // === Play Session 1 ===
        let puzzle = TestFixtures.easyPuzzle
        var gameState = GameState(puzzle: puzzle)

        // Find empty cells for testing
        var emptyPositions: [CellPosition] = []
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if puzzle.initialGrid[row][col] == nil {
                    emptyPositions.append(pos)
                    if emptyPositions.count >= 3 { break }
                }
            }
            if emptyPositions.count >= 3 { break }
        }

        // User plays for a while
        gameState.setValue(5, at: emptyPositions[0])
        gameState.setValue(8, at: emptyPositions[1])
        gameState.elapsedTime = 120.0

        // === App Backgrounds ===
        // Auto-save occurs
        try persistenceManager.saveGame(gameState)

        // Verify save occurred
        XCTAssertTrue(persistenceManager.hasSavedGame())

        // === User Force Quits App ===
        // (Simulated by continuing with same persistence manager)

        // === App Relaunch ===
        // Load saved game
        let restoredState = try persistenceManager.loadGame()
        XCTAssertNotNil(restoredState)

        // Verify game can resume exactly where it left off
        guard let restored = restoredState else {
            XCTFail("Failed to restore game state")
            return
        }

        XCTAssertEqual(restored.puzzle.id, puzzle.id)
        XCTAssertEqual(restored.elapsedTime, 120.0, accuracy: 0.1)
        XCTAssertEqual(restored.value(at: emptyPositions[0]), 5)
        XCTAssertEqual(restored.value(at: emptyPositions[1]), 8)

        // === Resume Playing ===
        var continuedState = restored
        continuedState.setValue(3, at: emptyPositions[2])
        continuedState.elapsedTime = 180.0

        // === Background Again ===
        try persistenceManager.saveGame(continuedState)

        // === Relaunch Again ===
        let secondRestore = try persistenceManager.loadGame()
        XCTAssertNotNil(secondRestore)
        if let elapsed = secondRestore?.elapsedTime {
            XCTAssertEqual(elapsed, 180.0, accuracy: 0.1)
        } else {
            XCTFail("Elapsed time should not be nil")
        }
        XCTAssertEqual(secondRestore?.value(at: emptyPositions[2]), 3)

        // === Complete Game ===
        // When game is completed and user starts new game, old save is deleted
        try persistenceManager.deleteSavedGame()
        XCTAssertFalse(persistenceManager.hasSavedGame())
    }

    // MARK: - Performance Tests

    func testSavePerformance() throws {
        // Given: A game state
        let puzzle = TestFixtures.hardPuzzle
        let gameState = GameState(puzzle: puzzle)

        // Measure save performance
        measure {
            try? persistenceManager.saveGame(gameState)
        }
    }

    func testLoadPerformance() throws {
        // Given: A saved game
        let puzzle = TestFixtures.hardPuzzle
        let gameState = GameState(puzzle: puzzle)
        try persistenceManager.saveGame(gameState)

        // Measure load performance
        measure {
            _ = try? persistenceManager.loadGame()
        }
    }
}
