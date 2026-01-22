//
//  PuzzleManagerTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

@testable import TennerGrid
import XCTest

@MainActor
final class PuzzleManagerTests: XCTestCase {
    var puzzleManager: PuzzleManager!

    override func setUp() async throws {
        try await super.setUp()
        puzzleManager = PuzzleManager()
        // Clear any saved games from previous tests
        puzzleManager.removeAllSavedGames()
    }

    override func tearDown() async throws {
        puzzleManager.removeAllSavedGames()
        puzzleManager = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(puzzleManager)
        XCTAssertNil(puzzleManager.currentPuzzle)
        XCTAssertEqual(puzzleManager.savedGames.count, 0)
        XCTAssertFalse(puzzleManager.isGenerating)
    }

    // MARK: - Puzzle Generation Tests

    func testGenerateNewPuzzle_withValidParameters() async {
        let puzzle = await puzzleManager.generateNewPuzzle(
            columns: 10,
            rows: 5,
            difficulty: .easy
        )

        XCTAssertNotNil(puzzle)
        XCTAssertEqual(puzzle?.columns, 10)
        XCTAssertEqual(puzzle?.rows, 5)
        XCTAssertEqual(puzzle?.difficulty, .easy)
        XCTAssertTrue(puzzle?.isValid() ?? false)
    }

    func testGenerateNewPuzzle_withDifferentDifficulties() async {
        let difficulties: [Difficulty] = [.easy, .medium, .hard, .expert]

        for difficulty in difficulties {
            let puzzle = await puzzleManager.generateNewPuzzle(
                columns: 10,
                rows: 5,
                difficulty: difficulty
            )

            XCTAssertNotNil(puzzle, "Failed to generate puzzle for difficulty: \(difficulty)")
            XCTAssertEqual(puzzle?.difficulty, difficulty)
        }
    }

    func testGenerateNewPuzzle_withCustomDimensions() async {
        let testCases: [(columns: Int, rows: Int)] = [
            (5, 5),
            (7, 6),
            (10, 5),
            (8, 8),
        ]

        for testCase in testCases {
            let puzzle = await puzzleManager.generateNewPuzzle(
                columns: testCase.columns,
                rows: testCase.rows,
                difficulty: .medium
            )

            XCTAssertNotNil(puzzle, "Failed to generate puzzle with dimensions \(testCase.rows)x\(testCase.columns)")
            XCTAssertEqual(puzzle?.columns, testCase.columns)
            XCTAssertEqual(puzzle?.rows, testCase.rows)
        }
    }

    func testGenerateNewPuzzle_withInvalidColumns() async {
        let invalidColumns = [4, 11, 0, -1]

        for columns in invalidColumns {
            let puzzle = await puzzleManager.generateNewPuzzle(
                columns: columns,
                rows: 5,
                difficulty: .easy
            )

            XCTAssertNil(puzzle, "Should return nil for invalid columns: \(columns)")
        }
    }

    func testGenerateNewPuzzle_withInvalidRows() async {
        let invalidRows = [4, 11, 0, -1]

        for rows in invalidRows {
            let puzzle = await puzzleManager.generateNewPuzzle(
                columns: 10,
                rows: rows,
                difficulty: .easy
            )

            XCTAssertNil(puzzle, "Should return nil for invalid rows: \(rows)")
        }
    }

    func testGenerateNewPuzzle_setsIsGeneratingFlag() async {
        XCTAssertFalse(puzzleManager.isGenerating)

        // Start generation in background
        let task = Task { @MainActor in
            await puzzleManager.generateNewPuzzle(
                columns: 10,
                rows: 5,
                difficulty: .easy
            )
        }

        // Wait for completion
        _ = await task.value

        // Should be false after completion
        XCTAssertFalse(puzzleManager.isGenerating)
    }

    // MARK: - Daily Puzzle Tests

    func testGenerateDailyPuzzle() async {
        let puzzle = await puzzleManager.generateDailyPuzzle()

        XCTAssertNotNil(puzzle)
        XCTAssertEqual(puzzle?.columns, 10, "Daily puzzles should use 10 columns")
        XCTAssertEqual(puzzle?.rows, 5, "Daily puzzles should use 5 rows")
        XCTAssertEqual(puzzle?.difficulty, .medium, "Daily puzzles should use medium difficulty")
        XCTAssertTrue(puzzle?.isValid() ?? false)
    }

    func testGenerateDailyPuzzle_isDeterministic() async {
        let puzzle1 = await puzzleManager.generateDailyPuzzle()
        let puzzle2 = await puzzleManager.generateDailyPuzzle()

        XCTAssertNotNil(puzzle1)
        XCTAssertNotNil(puzzle2)

        // Same date should generate same puzzle (same solution)
        XCTAssertEqual(puzzle1?.solution, puzzle2?.solution, "Daily puzzles for same date should be identical")
        XCTAssertEqual(puzzle1?.targetSums, puzzle2?.targetSums)
    }

    func testGenerateDailyPuzzle_forSpecificDate() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let specificDate = dateFormatter.date(from: "2026-01-15") else {
            XCTFail("Failed to create test date")
            return
        }

        let puzzle1 = await puzzleManager.generateDailyPuzzle(for: specificDate)
        let puzzle2 = await puzzleManager.generateDailyPuzzle(for: specificDate)

        XCTAssertNotNil(puzzle1)
        XCTAssertNotNil(puzzle2)

        // Same date should generate same puzzle
        XCTAssertEqual(puzzle1?.solution, puzzle2?.solution)
        XCTAssertEqual(puzzle1?.targetSums, puzzle2?.targetSums)
    }

    func testGenerateDailyPuzzle_differentDatesProduceDifferentPuzzles() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let date1 = dateFormatter.date(from: "2026-01-15"),
              let date2 = dateFormatter.date(from: "2026-01-16")
        else {
            XCTFail("Failed to create test dates")
            return
        }

        let puzzle1 = await puzzleManager.generateDailyPuzzle(for: date1)
        let puzzle2 = await puzzleManager.generateDailyPuzzle(for: date2)

        XCTAssertNotNil(puzzle1)
        XCTAssertNotNil(puzzle2)

        // Different dates should generate different puzzles
        XCTAssertNotEqual(puzzle1?.solution, puzzle2?.solution)
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
        var gameState1 = GameState(puzzle: puzzle)
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

    func testSavedGamesPersistence() {
        let puzzle = createTestPuzzle()
        let savedGame = SavedGame(puzzle: puzzle, gameState: GameState(puzzle: puzzle))

        puzzleManager.addSavedGame(savedGame)
        XCTAssertEqual(puzzleManager.savedGames.count, 1)

        // Create a new manager instance (simulating app restart)
        let newManager = PuzzleManager()

        XCTAssertEqual(newManager.savedGames.count, 1, "Saved games should persist across manager instances")
        XCTAssertEqual(newManager.savedGames.first?.puzzle.id, puzzle.id)

        // Clean up
        newManager.removeAllSavedGames()
    }

    // MARK: - Helper Methods

    private func createTestPuzzle() -> TennerGridPuzzle {
        let targetSums = [25, 30, 20, 35, 25]
        let initialGrid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let solution: [[Int]] = [
            [1, 2, 3, 4, 5],
            [6, 7, 3, 8, 0],
            [5, 9, 1, 7, 3],
            [2, 4, 6, 7, 8],
            [0, 3, 5, 1, 9],
        ]

        return TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: solution
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

    func testSavedGameCodable() throws {
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

    private func createTestPuzzle() -> TennerGridPuzzle {
        let targetSums = [25, 30, 20, 35, 25]
        let initialGrid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let solution: [[Int]] = [
            [1, 2, 3, 4, 5],
            [6, 7, 3, 8, 0],
            [5, 9, 1, 7, 3],
            [2, 4, 6, 7, 8],
            [0, 3, 5, 1, 9],
        ]

        return TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: solution
        )
    }
}
