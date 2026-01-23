import Foundation
import Testing
import XCTest
@testable import TennerGrid

struct TennerGridPuzzleTests {
    // MARK: - Test Helpers

    /// Creates a valid 10x5 puzzle that passes validation (with unique ID)
    private func createValidPuzzle() -> TennerGridPuzzle {
        guard let template = BundledPuzzleService.shared.firstPuzzle(difficulty: .medium, rows: 5) else {
            fatalError("Failed to load test puzzle from bundle")
        }
        // Return puzzle with unique ID to allow equality testing
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

    // MARK: - Initialization Tests

    @Test func defaultInitialization() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.columns == 10)
        #expect(puzzle.rows == 5)
        #expect(puzzle.difficulty == .medium)
        #expect(puzzle.targetSums.count == 10)
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
            columns: 10,
            rows: 5,
            difficulty: .easy,
            targetSums: [10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 10), count: 5)
        )

        #expect(puzzle.id == customID)
    }

    @Test func customCreatedAt() {
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 5,
            difficulty: .easy,
            targetSums: [10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 10), count: 5),
            createdAt: customDate
        )

        #expect(puzzle.createdAt == customDate)
    }

    // MARK: - Computed Properties Tests

    @Test func testTotalCells() {
        let puzzle10x5 = createValidPuzzle()
        #expect(puzzle10x5.totalCells == 50)

        let puzzle10x6 = TennerGridPuzzle(
            columns: 10,
            rows: 6,
            difficulty: .hard,
            targetSums: Array(repeating: 30, count: 10),
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 6),
            solution: Array(repeating: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], count: 6)
        )
        #expect(puzzle10x6.totalCells == 60)
    }

    @Test func testPrefilledCount() {
        let puzzle = createValidPuzzle()
        // Count non-nil values in initialGrid dynamically
        let expectedCount = puzzle.initialGrid.flatMap { $0 }.compactMap { $0 }.count
        #expect(puzzle.prefilledCount == expectedCount)
        #expect(puzzle.prefilledCount > 0) // Should have some prefilled cells
    }

    @Test func prefilledCountEmpty() {
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 5,
            difficulty: .hard,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(puzzle.prefilledCount == 0)
    }

    @Test func prefilledCountFull() {
        let solution = Array(repeating: Array(repeating: 5, count: 5), count: 5)
        let puzzle = TennerGridPuzzle(
            columns: 10,
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
        #expect(puzzle.emptyCellCount > 0) // Should have some empty cells to fill
    }

    @Test func testPrefilledPercentage() {
        let puzzle = createValidPuzzle()
        let expectedPercentage = Double(puzzle.prefilledCount) / Double(puzzle.totalCells)
        #expect(puzzle.prefilledPercentage == expectedPercentage)
        #expect(puzzle.prefilledPercentage > 0 && puzzle.prefilledPercentage < 1)
    }

    @Test func prefilledPercentageEmpty() {
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 5,
            difficulty: .hard,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )

        #expect(puzzle.prefilledPercentage == 0.0)
    }

    @Test func prefilledPercentageFull() {
        let solution = Array(repeating: Array(repeating: 5, count: 10), count: 5)
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 25, count: 10),
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
            columns: 10,
            rows: 2, // Too small (minimum is 3)
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 10),
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 2),
            solution: Array(repeating: Array(repeating: 0, count: 10), count: 2)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidRowCountTooLarge() {
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 11, // Too large (maximum is 10)
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 10),
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 11),
            solution: Array(repeating: Array(repeating: 0, count: 10), count: 11)
        )

        #expect(!puzzle.isValid())
    }

    @Test func invalidTargetSumsCount() {
        let puzzle = TennerGridPuzzle(
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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
            columns: 10,
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

        // Find a prefilled cell and an empty cell dynamically
        var prefilledPosition: CellPosition?
        var emptyPosition: CellPosition?

        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if puzzle.initialGrid[row][col] != nil, prefilledPosition == nil {
                    prefilledPosition = pos
                } else if puzzle.initialGrid[row][col] == nil, emptyPosition == nil {
                    emptyPosition = pos
                }
            }
        }

        // Prefilled cell should return its value
        if let pos = prefilledPosition {
            #expect(puzzle.initialValue(at: pos) == puzzle.initialGrid[pos.row][pos.column])
        }
        // Empty cell should return nil
        if let pos = emptyPosition {
            #expect(puzzle.initialValue(at: pos) == nil)
        }
    }

    @Test func initialValueOutOfBounds() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.initialValue(at: CellPosition(row: -1, column: 0)) == nil)
        #expect(puzzle.initialValue(at: CellPosition(row: 0, column: -1)) == nil)
        #expect(puzzle.initialValue(at: CellPosition(row: 5, column: 0)) == nil)
        #expect(puzzle.initialValue(at: CellPosition(row: 0, column: 10)) == nil)
    }

    @Test func testSolutionValue() {
        let puzzle = createValidPuzzle()

        // Check that solution values match the solution array
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                #expect(puzzle.solutionValue(at: pos) == puzzle.solution[row][col])
            }
        }
    }

    @Test func solutionValueOutOfBounds() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.solutionValue(at: CellPosition(row: -1, column: 0)) == nil)
        #expect(puzzle.solutionValue(at: CellPosition(row: 0, column: -1)) == nil)
        #expect(puzzle.solutionValue(at: CellPosition(row: 5, column: 0)) == nil)
        #expect(puzzle.solutionValue(at: CellPosition(row: 0, column: 10)) == nil)
    }

    @Test func testIsValidPosition() {
        let puzzle = createValidPuzzle()

        #expect(puzzle.isValidPosition(CellPosition(row: 0, column: 0)))
        #expect(puzzle.isValidPosition(CellPosition(row: 4, column: 9)))
        #expect(puzzle.isValidPosition(CellPosition(row: 2, column: 5)))

        #expect(!puzzle.isValidPosition(CellPosition(row: -1, column: 0)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 0, column: -1)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 5, column: 0)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 0, column: 10)))
        #expect(!puzzle.isValidPosition(CellPosition(row: 10, column: 10)))
    }

    @Test func testIsPrefilled() {
        let puzzle = createValidPuzzle()

        // Check that isPrefilled matches whether initialGrid has a value
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                let expected = puzzle.initialGrid[row][col] != nil
                #expect(puzzle.isPrefilled(at: pos) == expected)
            }
        }
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
            columns: 10,
            rows: 5,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 5),
            initialGrid: Array(repeating: Array(repeating: nil, count: 5), count: 5),
            solution: Array(repeating: Array(repeating: 0, count: 5), count: 5)
        )
        let puzzle2 = TennerGridPuzzle(
            id: id,
            columns: 10,
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
        #expect(description.contains("\(puzzle.columns)x\(puzzle.rows)"))
        #expect(description.contains(puzzle.difficulty.displayName))
        #expect(description.contains("\(puzzle.prefilledCount)/\(puzzle.totalCells)"))
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        let puzzle = createValidPuzzle()
        let encoder = JSONEncoder()
        let data = try encoder.encode(puzzle)

        #expect(!data.isEmpty)

        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"columns\":10"))
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
            columns: 10,
            rows: 3,
            difficulty: .easy,
            targetSums: Array(repeating: 10, count: 10),
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 3),
            solution: Array(repeating: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], count: 3)
        )

        #expect(puzzle.isValid())
        #expect(puzzle.totalCells == 30)
    }

    @Test func maximumSizePuzzle() {
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 7,
            difficulty: .hard,
            targetSums: Array(repeating: 45, count: 10),
            initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 7),
            solution: Array(repeating: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], count: 7)
        )

        #expect(puzzle.isValid())
        #expect(puzzle.totalCells == 70)
    }

    @Test func allDifficulties() {
        for difficulty in Difficulty.allCases {
            let puzzle = TennerGridPuzzle(
                columns: 10,
                rows: 5,
                difficulty: difficulty,
                targetSums: Array(repeating: 10, count: 10),
                initialGrid: Array(repeating: Array(repeating: nil, count: 10), count: 5),
                solution: Array(repeating: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], count: 5)
            )

            #expect(puzzle.difficulty == difficulty)
            #expect(puzzle.isValid())
        }
    }
}
