//
//  TennerGridPuzzleTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

@testable import TennerGrid
import Testing

struct TennerGridPuzzleTests {
    // MARK: - Test Helpers

    /// Creates a simple 5x5 valid puzzle for testing
    private func createValidPuzzle() -> TennerGridPuzzle {
        let solution = [
            [0, 1, 2, 3, 4],
            [5, 6, 7, 8, 9],
            [1, 2, 3, 4, 5],
            [6, 7, 8, 9, 0],
            [2, 3, 4, 5, 6],
        ]

        let initialGrid: [[Int?]] = [
            [0, nil, nil, nil, 4],
            [nil, 6, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [nil, nil, nil, 9, nil],
            [2, nil, nil, nil, 6],
        ]

        let targetSums = [14, 19, 24, 29, 24]

        return TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .medium,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: solution
        )
    }

    // MARK: - Initialization Tests

    @Test func defaultInitialization() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.columns == 5)
        #expect(puzzle.rows == 5)
        #expect(puzzle.difficulty == .medium)
        #expect(puzzle.targetSums.count == 5)
        #expect(puzzle.initialGrid.count == 5)
        #expect(puzzle.solution.count == 5)
    }

    @Test func uUIDIsGenerated() {
        let puzzle1 = createValidPuzzle()
        let puzzle2 = createValidPuzzle()

        #expect(puzzle1.id != puzzle2.id)
    }

    @Test func createdAtDefaultsToNow() {
        let before = Date()
        let puzzle = createValidPuzzle()
        let after = Date()

        #expect(puzzle.createdAt >= before)
        #expect(puzzle.createdAt <= after)
    }

    @Test func testCustomID() {
        let customID = UUID()
        let puzzle = TennerGridPuzzle(
            id: customID,
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: [10, 10, 10, 10, 10],
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(puzzle.id == customID)
    }

    @Test func customCreatedAt() {
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: [10, 10, 10, 10, 10],
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5),
            createdAt: customDate
        )

        #expect(puzzle.createdAt == customDate)
    }

    // MARK: - Computed Properties Tests

    @Test func testTotalCells() {
        let puzzle5x5 = createValidPuzzle()
        #expect(puzzle5x5.totalCells == 25)

        let puzzle8x6 = TennerGridPuzzle(
            columns: 8,
            rows: 6,
            difficulty: .hard,
            targetSums: Array(repeating: 30, count: 8),
            initialGrid: Array(repeating: Array(repeating: nil, count: 8), count: 6),
            solution: Array(repeating: Array(repeating: 5, count: 8), count: 6)
        )
        #expect(puzzle8x6.totalCells == 48)
    }

    @Test func testPrefilledCount() {
        let puzzle = createValidPuzzle()
        // Count non-nil values in initialGrid
        let expectedCount = 8 // Based on createValidPuzzle()
        #expect(puzzle.prefilledCount == expectedCount)
    }

    @Test func prefilledCountEmpty() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .calculator,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(puzzle.prefilledCount == 0)
    }

    @Test func prefilledCountFull() {
        let solution = Array(repeating: Array(repeating: 5, count: 5), count: 5)
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 25, count: 5),
            initialGrid: solution.map { $0.map { Int?($0) } },
            solution: solution
        )

        #expect(puzzle.prefilledCount == 25)
    }

    @Test func testEmptyCellCount() {
        let puzzle = createValidPuzzle()
        #expect(puzzle.emptyCellCount == puzzle.totalCells - puzzle.prefilledCount)
        #expect(puzzle.emptyCellCount == 17) // 25 - 8
    }

    @Test func testPrefilledPercentage() {
        let puzzle = createValidPuzzle()
        let expectedPercentage = Double(8) / Double(25)
        #expect(puzzle.prefilledPercentage == expectedPercentage)
    }

    @Test func prefilledPercentageEmpty() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .calculator,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(puzzle.prefilledPercentage == 0.0)
    }

    @Test func prefilledPercentageFull() {
        let solution = Array(repeating: Array(repeating: 5, count: 5), count: 5)
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 25, count: 5),
            initialGrid: solution.map { $0.map { Int?($0) } },
            solution: solution
        )

        #expect(puzzle.prefilledPercentage == 1.0)
    }

    // MARK: - Validation Tests

    @Test func validPuzzle() {
        let puzzle = createValidPuzzle()
        #expect(puzzle.isValid())
    }

    @Test func invalidColumnCountTooSmall() {
        let puzzle = TennerGridPuzzle(
            columns: 4, // Too small
            rows: 5,
            difficulty: .easy,
            targetSums: [10, 10, 10, 10],
            initialGrid: Array(repeating: Array(repeating: nil, count: 4), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 4), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidColumnCountTooLarge() {
        let puzzle = TennerGridPuzzle(
            columns: 11, // Too large
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 11),
            initialGrid: Array(repeating: Array(repeating: nil, count: 11), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 11), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidRowCountTooSmall() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 4, // Too small
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 4),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 4)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidRowCountTooLarge() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 11, // Too large
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 11),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 11)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidTargetSumsCount() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: [10, 10, 10], // Wrong count
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidTargetSumsNegative() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: [10, -5, 10, 10, 10], // Negative value
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidTargetSumsZero() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: [10, 0, 10, 10, 10], // Zero is invalid
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidInitialGridRowCount() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 4), // Wrong row count
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidInitialGridColumnCount() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 4), count: 5), // Wrong column count
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidSolutionRowCount() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 4) // Wrong row count
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidSolutionColumnCount() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 4), count: 5) // Wrong column count
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidSolutionValueTooLarge() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: [[0, 1, 2, 3, 10]] + Array(repeating: Array(repeating: 0, count: 5), count: 4) // 10 is invalid
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidSolutionValueNegative() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: [[0, 1, -1, 3, 4]] + Array(repeating: Array(repeating: 0, count: 5), count: 4) // -1 is invalid
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidInitialGridDoesNotMatchSolution() {
        var initialGrid = Array(repeating: Array(repeating: nil as Int?, count: 5), count: 5)
        initialGrid[0][0] = 5 // Does not match solution which has 0 at [0][0]

        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: initialGrid,
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(!puzzle.isValid())
    }

    // MARK: - Grid Access Tests

    @Test func testInitialValue() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.initialValue(at: CellPosition(row: 0, column: 0)) == 0)
        #expect(puzzle.initialValue(at: CellPosition(row: 0, column: 1)) == nil)
        #expect(puzzle.initialValue(at: CellPosition(row: 1, column: 1)) == 6)
        #expect(puzzle.initialValue(at: CellPosition(row: 4, column: 4)) == 6)
    }

    @Test func initialValueOutOfBounds() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.initialValue(at: CellPosition(row: -1, column: 0)) == nil)
        #expect(puzzle.initialValue(at: CellPosition(row: 0, column: -1)) == nil)
        #expect(puzzle.initialValue(at: CellPosition(row: 5, column: 0)) == nil)
        #expect(puzzle.initialValue(at: CellPosition(row: 0, column: 5)) == nil)
    }

    @Test func testSolutionValue() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.solutionValue(at: CellPosition(row: 0, column: 0)) == 0)
        #expect(puzzle.solutionValue(at: CellPosition(row: 0, column: 1)) == 1)
        #expect(puzzle.solutionValue(at: CellPosition(row: 1, column: 1)) == 6)
        #expect(puzzle.solutionValue(at: CellPosition(row: 4, column: 4)) == 6)
    }

    @Test func solutionValueOutOfBounds() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.solutionValue(at: CellPosition(row: -1, column: 0)) == nil)
        #expect(puzzle.solutionValue(at: CellPosition(row: 0, column: -1)) == nil)
        #expect(puzzle.solutionValue(at: CellPosition(row: 5, column: 0)) == nil)
        #expect(puzzle.solutionValue(at: CellPosition(row: 0, column: 5)) == nil)
    }

    @Test func testIsValidPosition() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.isValidPosition(CellPosition(row: 0, column: 0)))
        #expect(puzzle.isValidPosition(CellPosition(row: 4, column: 4)))
        #expect(puzzle.isValidPosition(CellPosition(row: 2, column: 3)))

        #expect(!puzzle.isValidPosition(CellPosition(row: -1, column: 0)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 0, column: -1)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 5, column: 0)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 0, column: 5)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 10, column: 10)))
    }

    @Test func testIsPrefilled() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.isPrefilled(at: CellPosition(row: 0, column: 0)))
        #expect(!puzzle.isPrefilled(at: CellPosition(row: 0, column: 1)))
        #expect(puzzle.isPrefilled(at: CellPosition(row: 1, column: 1)))
        #expect(!puzzle.isPrefilled(at: CellPosition(row: 1, column: 0)))
    }

    // MARK: - Equatable Tests

    @Test func equality() {
        let puzzle1 = createValidPuzzle()
        let puzzle2 = createValidPuzzle()

        // Different IDs means different puzzles
        #expect(puzzle1 != puzzle2)
    }

    @Test func equalityWithSameID() {
        let id = UUID()
        let puzzle1 = TennerGridPuzzle(
            id: id,
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )
        let puzzle2 = TennerGridPuzzle(
            id: id,
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(puzzle1 == puzzle2)
    }

    // MARK: - CustomStringConvertible Tests

    @Test func testDescription() {
        let puzzle = createValidPuzzle()
        let description = puzzle.description

        #expect(description.contains("TennerGridPuzzle"))
        #expect(description.contains("5x5"))
        #expect(description.contains("Medium"))
        #expect(description.contains("8/25")) // prefilledCount/totalCells
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        let puzzle = createValidPuzzle()
        let encoder = JSONEncoder()
        let data = try encoder.encode(puzzle)

        #expect(!data.isEmpty)

        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"columns\":5"))
        #expect(json.contains("\"rows\":5"))
        #expect(json.contains("\"difficulty\":\"medium\""))
    }

    @Test func codableDecoding() throws {
        let puzzle = createValidPuzzle()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(puzzle)
        let decoded = try decoder.decode(TennerGridPuzzle.self, from: data)

        #expect(decoded.id == puzzle.id)
        #expect(decoded.columns == puzzle.columns)
        #expect(decoded.rows == puzzle.rows)
        #expect(decoded.difficulty == puzzle.difficulty)
        #expect(decoded.targetSums == puzzle.targetSums)
    }

    @Test func codableRoundTrip() throws {
        let original = createValidPuzzle()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TennerGridPuzzle.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Edge Cases

    @Test func minimumSizePuzzle() {
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 2, count: 5), count: 5)
        )

        #expect(puzzle.isValid())
        #expect(puzzle.totalCells == 25)
    }

    @Test func maximumSizePuzzle() {
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 10,
            difficulty: .expert,
            targetSums: Array(repeating: 45, count: 10),
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 10),
            solution: Array(repeating: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], count: 10)
        )

        #expect(puzzle.isValid())
        #expect(puzzle.totalCells == 100)
    }

    @Test func allDifficulties() {
        for difficulty in Difficulty.allCases {
            let puzzle = TennerGridPuzzle(
                columns: 5,
                rows: 5,
                difficulty: difficulty,
                targetSums: Array(repeating: 10, count: 5),
                initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
                solution: Array(repeating: Array(repeating: 2, count: 5), count: 5)
            )

            #expect(puzzle.difficulty == difficulty)
            #expect(puzzle.isValid())
        }
    }
}
