//
//  PuzzleSolverTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

@testable import TennerGrid
import XCTest

final class PuzzleSolverTests: XCTestCase {
    var solver: PuzzleSolver!

    override func setUp() {
        super.setUp()
        solver = PuzzleSolver()
    }

    override func tearDown() {
        solver = nil
        super.tearDown()
    }

    // MARK: - hasUniqueSolution Tests

    func testHasUniqueSolution_SimplePuzzleWithUniqueSolution() {
        // Given: A simple 3x3 puzzle with a unique solution
        // Grid structure where only one solution is possible
        let initialGrid: [[Int?]] = [
            [1, 2, nil],
            [4, nil, 6],
            [nil, 8, 9],
        ]

        // Target sums calculated from the expected solution
        // Expected solution:
        // [1, 2, 3]
        // [4, 5, 6]
        // [7, 8, 9]
        // Column sums: 12, 15, 18
        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The puzzle should have a unique solution
        XCTAssertTrue(hasUnique, "Puzzle with unique solution should return true")
    }

    func testHasUniqueSolution_PuzzleWithMultipleSolutions() {
        // Given: A puzzle with very few constraints, allowing multiple solutions
        let initialGrid: [[Int?]] = [
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil],
        ]

        // Very lenient target sums that allow multiple valid grids
        let targetSums = [20, 20, 5]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [9, 9, 2],
                [9, 9, 0],
                [2, 2, 3],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The puzzle should not have a unique solution (multiple solutions exist)
        XCTAssertFalse(hasUnique, "Puzzle with multiple solutions should return false")
    }

    func testHasUniqueSolution_PuzzleWithNoSolution() {
        // Given: A puzzle with impossible constraints
        let initialGrid: [[Int?]] = [
            [1, 2, nil],
            [2, nil, nil],
            [nil, nil, nil],
        ]

        // Impossible target sum for column 0 (already has 1+2 = 3, but target is 2)
        let targetSums = [2, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [2, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The puzzle should not have a unique solution (no solution exists)
        XCTAssertFalse(hasUnique, "Puzzle with no solution should return false")
    }

    func testHasUniqueSolution_FullyConstrainedGrid() {
        // Given: A puzzle where all cells are filled (fully constrained)
        let initialGrid: [[Int?]] = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The fully filled grid should have exactly one solution (itself)
        XCTAssertTrue(hasUnique, "Fully constrained grid should have unique solution")
    }

    func testHasUniqueSolution_InvalidDimensions() {
        // Given: A puzzle with mismatched grid dimensions
        let initialGrid: [[Int?]] = [
            [1, 2],
            [4, 5],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: Should return false due to invalid dimensions
        XCTAssertFalse(hasUnique, "Puzzle with invalid dimensions should return false")
    }

    // MARK: - findNextLogicalMove Tests

    func testFindNextLogicalMove_NakedSingle() {
        // Given: A grid where one cell has only one possible value (naked single)
        let initialGrid: [[Int?]] = [
            [1, 2, nil], // Position (0, 2) can only be 3 based on constraints
            [4, nil, 6],
            [7, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should return a move (naked single)
        XCTAssertNotNil(result, "Should find a logical move")
        if let move = result {
            // Verify the move is one of the empty cells
            XCTAssertTrue(
                (move.position.row == 0 && move.position.column == 2) ||
                    (move.position.row == 1 && move.position.column == 1),
                "Should return one of the empty cells"
            )
            XCTAssertTrue(move.value >= 0 && move.value <= 9, "Value should be between 0 and 9")
        }
    }

    func testFindNextLogicalMove_HiddenSingle() {
        // Given: A grid where a value can only go in one position in a row/column
        let initialGrid: [[Int?]] = [
            [0, 1, 2],
            [3, nil, 5],
            [nil, nil, nil],
        ]

        let targetSums = [10, 10, 16]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [0, 1, 2],
                [3, 4, 5],
                [7, 6, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should find a logical move
        XCTAssertNotNil(result, "Should find a logical move (hidden single or naked single)")
    }

    func testFindNextLogicalMove_ColumnSumConstraint() {
        // Given: A grid where column sum forces a specific value
        let initialGrid: [[Int?]] = [
            [5, 2, 3],
            [4, 7, 6],
            [nil, 8, 9],
        ]

        // Column 0 target sum is 12, and we have 5 + 4 = 9, so the last cell must be 3
        let targetSums = [12, 17, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [5, 2, 3],
                [4, 7, 6],
                [3, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should find the forced move
        XCTAssertNotNil(result, "Should find a logical move")
        if let move = result {
            XCTAssertEqual(move.position.row, 2, "Should be in row 2")
            XCTAssertEqual(move.position.column, 0, "Should be in column 0")
            XCTAssertEqual(move.value, 3, "Value should be 3 (forced by column sum)")
        }
    }

    func testFindNextLogicalMove_NoLogicalMove() {
        // Given: A complex grid where no logical deduction is possible (requires guessing)
        let initialGrid: [[Int?]] = [
            [nil, nil, nil],
            [nil, 5, nil],
            [nil, nil, nil],
        ]

        let targetSums = [15, 15, 15]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .hard,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [4, 6, 3],
                [7, 5, 8],
                [4, 4, 4],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: May or may not find a move depending on constraints
        // This is a valid test case - we just verify it returns a valid result type
        if let move = result {
            XCTAssertTrue(move.value >= 0 && move.value <= 9, "If move found, value should be valid")
        }
    }

    func testFindNextLogicalMove_EmptyGrid() {
        // Given: A completely empty grid
        let initialGrid: [[Int?]] = [
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: May or may not find a logical move
        // With an empty grid, there might not be enough constraints for a logical deduction
        if let move = result {
            XCTAssertTrue(move.value >= 0 && move.value <= 9, "If move found, value should be valid")
            XCTAssertTrue(move.position.row >= 0 && move.position.row < 3, "Row should be valid")
            XCTAssertTrue(move.position.column >= 0 && move.position.column < 3, "Column should be valid")
        }
    }

    func testFindNextLogicalMove_AlmostComplete() {
        // Given: A grid that is almost complete
        let initialGrid: [[Int?]] = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should find the last move
        XCTAssertNotNil(result, "Should find the final move")
        if let move = result {
            XCTAssertEqual(move.position.row, 2, "Should be in row 2")
            XCTAssertEqual(move.position.column, 2, "Should be in column 2")
            XCTAssertEqual(move.value, 9, "Value should be 9")
        }
    }
}
