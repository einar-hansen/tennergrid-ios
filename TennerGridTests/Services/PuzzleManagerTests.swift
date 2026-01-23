import XCTest
@testable import TennerGrid

@MainActor
final class PuzzleManagerTests: XCTestCase {
    var puzzleManager: PuzzleManager!

    // Class-level setup runs once per test class instead of per test
    override class func setUp() {
        super.setUp()
        // Clear UserDefaults directly to avoid MainActor issues
        UserDefaults.standard.removeObject(forKey: "savedGames")
    }

    override class func tearDown() {
        // Clear UserDefaults directly
        UserDefaults.standard.removeObject(forKey: "savedGames")
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        // Clear before creating manager
        UserDefaults.standard.removeObject(forKey: "savedGames")
        puzzleManager = PuzzleManager()
    }

    override func tearDown() {
        // Ensure cleanup
        puzzleManager?.removeAllSavedGames()
        puzzleManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(puzzleManager)
        XCTAssertNil(puzzleManager.currentPuzzle)
        XCTAssertEqual(puzzleManager.savedGames.count, 0)
    }

    // MARK: - Puzzle Selection Tests

    func testRandomPuzzle() {
        // When
        let puzzle = puzzleManager.randomPuzzle(rows: 5, difficulty: .easy)

        // Then
        XCTAssertNotNil(puzzle)
        XCTAssertEqual(puzzle?.columns, 10)
        XCTAssertEqual(puzzle?.rows, 5)
        XCTAssertEqual(puzzle?.difficulty, .easy)
    }

    func testFirstPuzzle() {
        // When
        let puzzle = puzzleManager.firstPuzzle(rows: 5, difficulty: .medium)

        // Then
        XCTAssertNotNil(puzzle)
        XCTAssertEqual(puzzle?.columns, 10)
        XCTAssertEqual(puzzle?.rows, 5)
        XCTAssertEqual(puzzle?.difficulty, .medium)
    }

    func testDailyPuzzle() {
        // When
        let puzzle = puzzleManager.dailyPuzzle()

        // Then
        XCTAssertNotNil(puzzle)
        XCTAssertEqual(puzzle?.columns, 10)
        XCTAssertEqual(puzzle?.rows, 5)
        XCTAssertEqual(puzzle?.difficulty, .medium)
    }

    func testDailyPuzzle_sameDay_returnsSamePuzzle() {
        // When
        let puzzle1 = puzzleManager.dailyPuzzle()
        let puzzle2 = puzzleManager.dailyPuzzle()

        // Then
        XCTAssertEqual(puzzle1?.id, puzzle2?.id, "Same day should return same puzzle")
    }

    func testSetPuzzleFromFixture() {
        // Given - Use fixture instead of generating
        let puzzle = TestFixtures.easyPuzzle

        // When
        puzzleManager.setCurrentPuzzle(puzzle)

        // Then
        XCTAssertNotNil(puzzleManager.currentPuzzle)
        XCTAssertEqual(puzzleManager.currentPuzzle?.difficulty, .easy)
    }

    func testPuzzleValidation_withDifferentDifficulties() {
        // Test that fixtures for different difficulties are valid
        let puzzles = [
            TestFixtures.easyPuzzle,
            TestFixtures.mediumPuzzle,
            TestFixtures.hardPuzzle,
        ]

        for puzzle in puzzles {
            XCTAssertNotNil(puzzle, "Fixture puzzle for \(puzzle.difficulty) should exist")
        }
    }

    func testInvalidRowCount() {
        // Test that invalid row counts return nil
        XCTAssertNil(puzzleManager.randomPuzzle(rows: 2, difficulty: .easy), "Rows < 3 should return nil")
        XCTAssertNil(puzzleManager.randomPuzzle(rows: 8, difficulty: .easy), "Rows > 7 should return nil")
    }

    // MARK: - Saved Games Tests

    func testAddSavedGame() {
        let puzzle = createTestPuzzle()
        let gameState = GameState(puzzle: puzzle)
        let savedGame = SavedGame(puzzle: puzzle, gameState: gameState)

        puzzleManager.addSavedGame(savedGame)

        XCTAssertEqual(puzzleManager.savedGames.count, 1)
        XCTAssertEqual(puzzleManager.savedGames.first?.puzzle.id, puzzle.id)
    }

    func testAddSavedGame_multipleGames() {
        let puzzle1 = createTestPuzzle()
        let puzzle2 = createTestPuzzle()

        let savedGame1 = SavedGame(puzzle: puzzle1, gameState: GameState(puzzle: puzzle1))
        let savedGame2 = SavedGame(puzzle: puzzle2, gameState: GameState(puzzle: puzzle2))

        puzzleManager.addSavedGame(savedGame1)
        puzzleManager.addSavedGame(savedGame2)

        XCTAssertEqual(puzzleManager.savedGames.count, 2)
    }

    func testAddSavedGame_replacesExistingGameWithSamePuzzleID() {
        let puzzle = createTestPuzzle()
        let gameState1 = GameState(puzzle: puzzle)
        var gameState2 = GameState(puzzle: puzzle)

        gameState2.addTime(60) // Add some time to differentiate

        let savedGame1 = SavedGame(puzzle: puzzle, gameState: gameState1)
        let savedGame2 = SavedGame(puzzle: puzzle, gameState: gameState2)

        puzzleManager.addSavedGame(savedGame1)
        puzzleManager.addSavedGame(savedGame2)

        XCTAssertEqual(puzzleManager.savedGames.count, 1, "Should replace existing game with same puzzle ID")
        XCTAssertEqual(puzzleManager.savedGames.first?.gameState.elapsedTime, 60)
    }

    func testAddSavedGame_limitsToTwentyGames() {
        // Add 25 games
        for _ in 0 ..< 25 {
            let puzzle = createTestPuzzle()
            let savedGame = SavedGame(puzzle: puzzle, gameState: GameState(puzzle: puzzle))
            puzzleManager.addSavedGame(savedGame)
        }

        XCTAssertEqual(puzzleManager.savedGames.count, 20, "Should limit to 20 most recent games")
    }

    func testAddSavedGame_mostRecentFirst() {
        let puzzle1 = createTestPuzzle()
        let puzzle2 = createTestPuzzle()

        let savedGame1 = SavedGame(puzzle: puzzle1, gameState: GameState(puzzle: puzzle1))
        let savedGame2 = SavedGame(puzzle: puzzle2, gameState: GameState(puzzle: puzzle2))

        puzzleManager.addSavedGame(savedGame1)
        puzzleManager.addSavedGame(savedGame2)

        XCTAssertEqual(puzzleManager.savedGames.first?.puzzle.id, puzzle2.id, "Most recent game should be first")
        XCTAssertEqual(puzzleManager.savedGames.last?.puzzle.id, puzzle1.id)
    }

    func testRemoveSavedGame() {
        let puzzle = createTestPuzzle()
        let savedGame = SavedGame(puzzle: puzzle, gameState: GameState(puzzle: puzzle))

        puzzleManager.addSavedGame(savedGame)
        XCTAssertEqual(puzzleManager.savedGames.count, 1)

        puzzleManager.removeSavedGame(withPuzzleID: puzzle.id)
        XCTAssertEqual(puzzleManager.savedGames.count, 0)
    }

    func testRemoveSavedGame_nonExistentID() {
        let puzzle = createTestPuzzle()
        let savedGame = SavedGame(puzzle: puzzle, gameState: GameState(puzzle: puzzle))

        puzzleManager.addSavedGame(savedGame)
        XCTAssertEqual(puzzleManager.savedGames.count, 1)

        puzzleManager.removeSavedGame(withPuzzleID: UUID())
        XCTAssertEqual(puzzleManager.savedGames.count, 1, "Should not remove anything if ID not found")
    }

    func testRemoveAllSavedGames() {
        // Add multiple games
        for _ in 0 ..< 5 {
            let puzzle = createTestPuzzle()
            let savedGame = SavedGame(puzzle: puzzle, gameState: GameState(puzzle: puzzle))
            puzzleManager.addSavedGame(savedGame)
        }

        XCTAssertEqual(puzzleManager.savedGames.count, 5)

        puzzleManager.removeAllSavedGames()
        XCTAssertEqual(puzzleManager.savedGames.count, 0)
    }

    func testLoadSavedGame() {
        let puzzle = createTestPuzzle()
        let savedGame = SavedGame(puzzle: puzzle, gameState: GameState(puzzle: puzzle))

        puzzleManager.addSavedGame(savedGame)

        let loadedGame = puzzleManager.loadSavedGame(withPuzzleID: puzzle.id)

        XCTAssertNotNil(loadedGame)
        XCTAssertEqual(loadedGame?.puzzle.id, puzzle.id)
    }

    func testLoadSavedGame_nonExistentID() {
        let loadedGame = puzzleManager.loadSavedGame(withPuzzleID: UUID())
        XCTAssertNil(loadedGame, "Should return nil if game not found")
    }

    // MARK: - Current Puzzle Tests

    func testSetCurrentPuzzle() {
        let puzzle = createTestPuzzle()

        XCTAssertNil(puzzleManager.currentPuzzle)

        puzzleManager.setCurrentPuzzle(puzzle)

        XCTAssertNotNil(puzzleManager.currentPuzzle)
        XCTAssertEqual(puzzleManager.currentPuzzle?.id, puzzle.id)
    }

    func testSetCurrentPuzzle_toNil() {
        let puzzle = createTestPuzzle()

        puzzleManager.setCurrentPuzzle(puzzle)
        XCTAssertNotNil(puzzleManager.currentPuzzle)

        puzzleManager.setCurrentPuzzle(nil)
        XCTAssertNil(puzzleManager.currentPuzzle)
    }

    // MARK: - Persistence Tests

    func testSavedGamesPersistence() async throws {
        // Ensure clean state
        puzzleManager.removeAllSavedGames()

        let puzzle = createTestPuzzle()
        let savedGame = SavedGame(puzzle: puzzle, gameState: GameState(puzzle: puzzle))

        // Add the game
        puzzleManager.addSavedGame(savedGame)
        XCTAssertEqual(puzzleManager.savedGames.count, 1, "Should have 1 saved game after adding")

        // Force UserDefaults to synchronize
        UserDefaults.standard.synchronize()

        // Verify data was written to UserDefaults
        let savedData = UserDefaults.standard.data(forKey: "savedGames")
        XCTAssertNotNil(savedData, "UserDefaults should contain saved games data")

        // Verify we can decode the data manually
        if let savedData {
            do {
                let loadedGames = try JSONDecoder().decode([SavedGame].self, from: savedData)
                XCTAssertEqual(loadedGames.count, 1, "Should decode 1 saved game")
                XCTAssertEqual(loadedGames.first?.puzzle.id, puzzle.id, "Decoded game should match")
            } catch {
                XCTFail("Failed to decode saved games: \(error)")
            }
        }

        // Create a new manager instance (simulating app restart)
        // This must happen on MainActor since PuzzleManager is @MainActor isolated
        let newManager = await MainActor.run {
            PuzzleManager()
        }

        // Verify the new manager loaded the saved game
        XCTAssertEqual(newManager.savedGames.count, 1, "Saved games should persist across manager instances")
        XCTAssertEqual(newManager.savedGames.first?.puzzle.id, puzzle.id, "Loaded game should have same puzzle ID")

        // Clean up
        newManager.removeAllSavedGames()
        UserDefaults.standard.synchronize()
    }

    // MARK: - Helper Methods

    private func createTestPuzzle() -> TennerGridPuzzle {
        // Load a puzzle from the bundle as template
        guard let template = BundledPuzzleService.shared.firstPuzzle(difficulty: .easy, rows: 5) else {
            fatalError("Failed to load test puzzle from bundle")
        }
        // Create a new puzzle with a unique ID to avoid test conflicts
        return TennerGridPuzzle(
            id: UUID(),
            columns: template.columns,
            rows: template.rows,
            difficulty: template.difficulty,
            targetSums: template.targetSums,
            initialGrid: template.initialGrid,
            solution: template.solution,
            createdAt: template.createdAt
        )
    }
}

// MARK: - SavedGame Tests

final class SavedGameTests: XCTestCase {
    func testSavedGameInitialization() {
        let puzzle = createTestPuzzle()
        let gameState = GameState(puzzle: puzzle)
        let savedGame = SavedGame(puzzle: puzzle, gameState: gameState)

        XCTAssertEqual(savedGame.puzzle.id, puzzle.id)
        XCTAssertEqual(savedGame.id, puzzle.id, "SavedGame ID should match puzzle ID")
        XCTAssertNotNil(savedGame.savedAt)
    }

    func testSavedGameFormattedElapsedTime() {
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)
        gameState.addTime(125) // 2 minutes and 5 seconds

        let savedGame = SavedGame(puzzle: puzzle, gameState: gameState)

        XCTAssertEqual(savedGame.formattedElapsedTime, "02:05")
    }

    func testSavedGameProgressPercentage() {
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)

        // Fill one cell
        gameState.setValue(1, at: CellPosition(row: 0, column: 0))

        let savedGame = SavedGame(puzzle: puzzle, gameState: gameState)
        let expectedProgress = (1.0 / Double(puzzle.emptyCellCount)) * 100

        XCTAssertEqual(savedGame.progressPercentage, expectedProgress, accuracy: 0.01)
    }

    func testSavedGameCanResume() {
        let puzzle = createTestPuzzle()
        var gameState = GameState(puzzle: puzzle)

        // New game - cannot resume
        var savedGame = SavedGame(puzzle: puzzle, gameState: gameState)
        XCTAssertFalse(savedGame.canResume)

        // Fill one cell - can resume
        gameState.setValue(1, at: CellPosition(row: 0, column: 0))
        savedGame = SavedGame(puzzle: puzzle, gameState: gameState)
        XCTAssertTrue(savedGame.canResume)

        // Complete the game - cannot resume
        gameState.complete()
        savedGame = SavedGame(puzzle: puzzle, gameState: gameState)
        XCTAssertFalse(savedGame.canResume)
    }

    nonisolated func testSavedGameCodable() throws {
        let puzzle = createTestPuzzle()
        let gameState = GameState(puzzle: puzzle)
        let savedGame = SavedGame(puzzle: puzzle, gameState: gameState)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(savedGame)

        // Decode
        let decoder = JSONDecoder()
        let decodedGame = try decoder.decode(SavedGame.self, from: data)

        XCTAssertEqual(decodedGame.puzzle.id, savedGame.puzzle.id)
        XCTAssertEqual(decodedGame.gameState.puzzle.id, savedGame.gameState.puzzle.id)
    }

    // MARK: - Helper Methods

    private nonisolated func createTestPuzzle() -> TennerGridPuzzle {
        // Load a puzzle from the bundle as template
        guard let template = BundledPuzzleService.shared.firstPuzzle(difficulty: .easy, rows: 5) else {
            fatalError("Failed to load test puzzle from bundle")
        }
        // Create a new puzzle with a unique ID to avoid test conflicts
        return TennerGridPuzzle(
            id: UUID(),
            columns: template.columns,
            rows: template.rows,
            difficulty: template.difficulty,
            targetSums: template.targetSums,
            initialGrid: template.initialGrid,
            solution: template.solution,
            createdAt: template.createdAt
        )
    }
}
