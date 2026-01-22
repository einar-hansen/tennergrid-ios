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
}
