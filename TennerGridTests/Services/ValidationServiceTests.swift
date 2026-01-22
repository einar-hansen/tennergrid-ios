//
//  ValidationServiceTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

@testable import TennerGrid
import XCTest

final class ValidationServiceTests: XCTestCase {
    var service: ValidationService!
    var testPuzzle: TennerGridPuzzle!

    override func setUp() {
        super.setUp()
        service = ValidationService()

        // Create a simple 5x5 test puzzle
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

        testPuzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: solution
        )
    }

    override func tearDown() {
        service = nil
        testPuzzle = nil
        super.tearDown()
    }

    // MARK: - isValidPlacement Tests

    func testValidPlacement_EmptyCell() {
        // Given: A grid with empty cells
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Placing a value that doesn't violate any rules
        let isValid = service.isValidPlacement(
            value: 1,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: The placement should be valid
        XCTAssertTrue(isValid, "Placing 1 at (0,0) should be valid")
    }

    func testInvalidPlacement_AdjacentDuplicate_Horizontal() {
        // Given: A grid with a value at (0,1)
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Trying to place the same value adjacently
        let isValid = service.isValidPlacement(
            value: 2,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: The placement should be invalid
        XCTAssertFalse(isValid, "Placing 2 at (0,0) should be invalid due to adjacent duplicate at (0,1)")
    }

    func testInvalidPlacement_AdjacentDuplicate_Vertical() {
        // Given: A grid with a value at (1,0)
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [3, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Trying to place the same value adjacently
        let isValid = service.isValidPlacement(
            value: 3,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: The placement should be invalid
        XCTAssertFalse(isValid, "Placing 3 at (0,0) should be invalid due to adjacent duplicate at (1,0)")
    }

    func testInvalidPlacement_AdjacentDuplicate_Diagonal() {
        // Given: A grid with a value at (1,1)
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, 4, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Trying to place the same value diagonally adjacent
        let isValid = service.isValidPlacement(
            value: 4,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: The placement should be invalid
        XCTAssertFalse(isValid, "Placing 4 at (0,0) should be invalid due to diagonal duplicate at (1,1)")
    }

    func testInvalidPlacement_RowDuplicate() {
        // Given: A grid with a value elsewhere in the same row
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, 7],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Trying to place a duplicate value in the same row
        let isValid = service.isValidPlacement(
            value: 7,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: The placement should be invalid
        XCTAssertFalse(isValid, "Placing 7 at (0,0) should be invalid due to row duplicate at (0,4)")
    }

    func testInvalidPlacement_OutOfRange() {
        // Given: A position and grid
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Trying to place a value outside the valid range
        let isValidNegative = service.isValidPlacement(
            value: -1,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )
        let isValidTooHigh = service.isValidPlacement(
            value: 10,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: Both placements should be invalid
        XCTAssertFalse(isValidNegative, "Placing -1 should be invalid")
        XCTAssertFalse(isValidTooHigh, "Placing 10 should be invalid")
    }

    func testInvalidPlacement_OutOfBounds() {
        // Given: A position outside the grid
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 10, column: 10)

        // When: Trying to place a value at an invalid position
        let isValid = service.isValidPlacement(
            value: 5,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: The placement should be invalid
        XCTAssertFalse(isValid, "Placing at (10,10) should be invalid due to out of bounds")
    }

    // MARK: - detectConflicts Tests

    func testDetectConflicts_NoConflicts() {
        // Given: A grid where a cell has no conflicts
        let grid: [[Int?]] = [
            [1, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: No conflicts should be found
        XCTAssertTrue(conflicts.isEmpty, "Cell at (0,0) should have no conflicts")
    }

    func testDetectConflicts_AdjacentConflict() {
        // Given: A grid where a cell has an adjacent conflict
        let grid: [[Int?]] = [
            [5, 2, nil, nil, nil],
            [5, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: Should detect the adjacent conflict at (1,0)
        XCTAssertEqual(conflicts.count, 2, "Should detect 2 conflicts (adjacent and row duplicate)")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 1, column: 0)), "Should detect adjacent conflict at (1,0)")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 2, column: 0)), "Should detect row duplicate at (2,0)")
    }

    func testDetectConflicts_RowConflict() {
        // Given: A grid where a cell has a row conflict
        let grid: [[Int?]] = [
            [5, 2, nil, nil, 5],
            [nil, nil, 3, nil, nil],
            [1, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: Should detect the row conflict at (0,4)
        XCTAssertEqual(conflicts.count, 1, "Should detect 1 conflict")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 0, column: 4)), "Should detect row conflict at (0,4)")
    }

    func testDetectConflicts_MultipleConflicts() {
        // Given: A grid where a cell has multiple conflicts
        let grid: [[Int?]] = [
            [5, 5, nil, nil, 5],
            [5, nil, 3, nil, nil],
            [nil, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: Should detect all conflicts
        XCTAssertEqual(conflicts.count, 3, "Should detect 3 conflicts")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 0, column: 1)), "Should detect adjacent conflict at (0,1)")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 1, column: 0)), "Should detect adjacent conflict at (1,0)")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 0, column: 4)), "Should detect row conflict at (0,4)")
    }

    func testDetectConflicts_EmptyCell() {
        // Given: An empty cell
        let grid: [[Int?]] = [
            [nil, 2, nil, nil, nil],
            [nil, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: No conflicts should be found for an empty cell
        XCTAssertTrue(conflicts.isEmpty, "Empty cell should have no conflicts")
    }

    // MARK: - isColumnSumValid Tests

    func testColumnSumValid_CorrectSum() {
        // Given: A grid with a complete column that sums correctly
        // Column 0: 1+6+5+2+0 = 14, but we'll set targetSum to 14
        let targetSums = [14, 30, 20, 35, 25]
        let grid: [[Int?]] = [
            [1, 2, nil, nil, nil],
            [6, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [2, nil, nil, 7, nil],
            [0, nil, nil, nil, 9],
        ]

        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: grid,
            solution: testPuzzle.solution
        )

        // When: Validating the column sum
        let isValid = service.isColumnSumValid(column: 0, in: grid, puzzle: puzzle)

        // Then: The sum should be valid
        XCTAssertTrue(isValid, "Column 0 sum should be valid (14)")
    }

    func testColumnSumValid_IncorrectSum() {
        // Given: A grid with a complete column that sums incorrectly
        let targetSums = [25, 30, 20, 35, 25]
        let grid: [[Int?]] = [
            [1, 2, nil, nil, nil],
            [6, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [2, nil, nil, 7, nil],
            [0, nil, nil, nil, 9],
        ]

        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: grid,
            solution: testPuzzle.solution
        )

        // When: Validating the column sum (actual: 14, expected: 25)
        let isValid = service.isColumnSumValid(column: 0, in: grid, puzzle: puzzle)

        // Then: The sum should be invalid
        XCTAssertFalse(isValid, "Column 0 sum should be invalid (14 != 25)")
    }

    func testColumnSumValid_IncompleteColumn() {
        // Given: A grid with an incomplete column
        let grid: [[Int?]] = [
            [1, 2, nil, nil, nil],
            [6, nil, 3, nil, nil],
            [nil, nil, nil, nil, nil],
            [2, nil, nil, 7, nil],
            [0, nil, nil, nil, 9],
        ]

        // When: Validating the column sum
        let isValid = service.isColumnSumValid(column: 0, in: grid, puzzle: testPuzzle)

        // Then: The sum should be invalid due to incomplete column
        XCTAssertFalse(isValid, "Incomplete column should be invalid")
    }

    func testColumnSumValid_InvalidColumn() {
        // Given: A grid
        let grid: [[Int?]] = [
            [1, 2, nil, nil, nil],
            [6, nil, 3, nil, nil],
            [5, nil, nil, nil, nil],
            [2, nil, nil, 7, nil],
            [0, nil, nil, nil, 9],
        ]

        // When: Validating an out-of-bounds column
        let isValidNegative = service.isColumnSumValid(column: -1, in: grid, puzzle: testPuzzle)
        let isValidTooHigh = service.isColumnSumValid(column: 10, in: grid, puzzle: testPuzzle)

        // Then: Both should be invalid
        XCTAssertFalse(isValidNegative, "Negative column index should be invalid")
        XCTAssertFalse(isValidTooHigh, "Column index >= columns should be invalid")
    }

    // MARK: - isPuzzleComplete Tests

    func testPuzzleComplete_ValidSolution() {
        // Given: A complete and correct solution
        let grid: [[Int?]] = [
            [1, 2, 3, 4, 5],
            [6, 7, 3, 8, 0],
            [5, 9, 1, 7, 3],
            [2, 4, 6, 7, 8],
            [0, 3, 5, 1, 9],
        ]

        // Adjust target sums to match the actual column sums
        let actualSums = (0 ..< 5).map { col in
            grid.compactMap { $0[col] }.reduce(0, +)
        }
        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: actualSums,
            initialGrid: testPuzzle.initialGrid,
            solution: testPuzzle.solution
        )

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: puzzle)

        // Then: The puzzle should be complete if no conflicts exist
        // Note: This will be true only if the grid follows all rules
        XCTAssertTrue(isComplete, "Valid solution should be complete")
    }

    func testPuzzleComplete_IncompletePuzzle() {
        // Given: An incomplete grid
        let grid: [[Int?]] = [
            [1, 2, 3, 4, 5],
            [6, 7, 3, 8, 0],
            [5, 9, 1, 7, nil],
            [2, 4, 6, 7, 8],
            [0, 3, 5, 1, 9],
        ]

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: testPuzzle)

        // Then: The puzzle should not be complete
        XCTAssertFalse(isComplete, "Incomplete puzzle should not be complete")
    }

    func testPuzzleComplete_WithConflicts() {
        // Given: A complete grid with conflicts
        let grid: [[Int?]] = [
            [1, 1, 3, 4, 5], // Row duplicate: 1 appears twice
            [6, 7, 3, 8, 0],
            [5, 9, 1, 7, 3],
            [2, 4, 6, 7, 8],
            [0, 3, 5, 1, 9],
        ]

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: testPuzzle)

        // Then: The puzzle should not be complete due to conflicts
        XCTAssertFalse(isComplete, "Puzzle with conflicts should not be complete")
    }

    func testPuzzleComplete_WithIncorrectColumnSums() {
        // Given: A complete grid without conflicts but wrong column sums
        let grid: [[Int?]] = [
            [0, 2, 3, 4, 5],
            [6, 7, 3, 8, 1],
            [5, 9, 1, 7, 3],
            [2, 4, 6, 0, 8],
            [1, 3, 5, 2, 9],
        ]

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: testPuzzle)

        // Then: The puzzle should not be complete due to incorrect sums
        XCTAssertFalse(isComplete, "Puzzle with incorrect column sums should not be complete")
    }

    // MARK: - Edge Cases

    func testValidPlacement_CornerCell() {
        // Given: A corner cell position
        let grid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 5), count: 5)
        let position = CellPosition(row: 0, column: 0)

        // When: Placing a value
        let isValid = service.isValidPlacement(
            value: 5,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: Should be valid
        XCTAssertTrue(isValid, "Placement in empty corner should be valid")
    }

    func testValidPlacement_CenterCell() {
        // Given: A center cell with values around it
        let grid: [[Int?]] = [
            [nil, 1, nil, nil, nil],
            [2, nil, 3, nil, nil],
            [nil, 4, nil, nil, nil],
            [nil, nil, nil, 7, nil],
            [nil, nil, nil, nil, 9],
        ]
        let position = CellPosition(row: 1, column: 1)

        // When: Placing a value not adjacent to any existing value
        let isValid = service.isValidPlacement(
            value: 5,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: Should be valid
        XCTAssertTrue(isValid, "Placing 5 at (1,1) should be valid")
    }

    func testValidPlacement_Zero() {
        // Given: An empty grid
        let grid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 5), count: 5)
        let position = CellPosition(row: 0, column: 0)

        // When: Placing zero
        let isValid = service.isValidPlacement(
            value: 0,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: Should be valid (0 is a valid value in Tenner Grid)
        XCTAssertTrue(isValid, "Zero should be a valid value")
    }
}
