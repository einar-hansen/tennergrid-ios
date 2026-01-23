import XCTest
@testable import TennerGrid

final class ValidationServiceTests: XCTestCase {
    var service: ValidationService!
    var testPuzzle: TennerGridPuzzle!

    override func setUp() {
        super.setUp()
        service = ValidationService()
        // Use a bundled 10-column puzzle from fixtures
        testPuzzle = TestFixtures.easyPuzzle
    }

    override func tearDown() {
        service = nil
        testPuzzle = nil
        super.tearDown()
    }

    // MARK: - isValidPlacement Tests

    func testValidPlacement_EmptyCell() {
        // Given: A 10-column grid with empty cells
        var grid = TestFixtures.emptyGrid10x3
        grid[0][1] = 2
        grid[1][2] = 3
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
        var grid = TestFixtures.emptyGrid10x3
        grid[0][1] = 2
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
        var grid = TestFixtures.emptyGrid10x3
        grid[1][0] = 3
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
        var grid = TestFixtures.emptyGrid10x3
        grid[1][1] = 4
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
        var grid = TestFixtures.emptyGrid10x3
        grid[0][9] = 7 // Same row, column 9
        let position = CellPosition(row: 0, column: 0)

        // When: Trying to place a duplicate value in the same row
        let isValid = service.isValidPlacement(
            value: 7,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: The placement should be invalid
        XCTAssertFalse(isValid, "Placing 7 at (0,0) should be invalid due to row duplicate at (0,9)")
    }

    func testInvalidPlacement_OutOfRange() {
        // Given: A position and grid
        let grid = TestFixtures.emptyGrid10x3
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
        let grid = TestFixtures.emptyGrid10x3
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
        var grid = TestFixtures.emptyGrid10x3
        grid[0][0] = 1
        grid[0][2] = 2 // Not adjacent to (0,0)
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: No conflicts should be found
        XCTAssertTrue(conflicts.isEmpty, "Cell at (0,0) should have no conflicts")
    }

    func testDetectConflicts_AdjacentConflict() {
        // Given: A grid where a cell has an adjacent conflict
        var grid = TestFixtures.emptyGrid10x3
        grid[0][0] = 5
        grid[1][0] = 5 // Adjacent vertical
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: Should detect the adjacent conflict at (1,0)
        XCTAssertEqual(conflicts.count, 1, "Should detect 1 adjacent conflict")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 1, column: 0)), "Should detect adjacent conflict at (1,0)")
    }

    func testDetectConflicts_RowConflict() {
        // Given: A grid where a cell has a row conflict (non-adjacent)
        var grid = TestFixtures.emptyGrid10x3
        grid[0][0] = 5
        grid[0][9] = 5 // Same row, far end
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: Should detect the row conflict at (0,9)
        XCTAssertEqual(conflicts.count, 1, "Should detect 1 conflict")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 0, column: 9)), "Should detect row conflict at (0,9)")
    }

    func testDetectConflicts_MultipleConflicts() {
        // Given: A grid where a cell has multiple conflicts
        var grid = TestFixtures.emptyGrid10x3
        grid[0][0] = 5
        grid[0][1] = 5 // Adjacent horizontal (also row conflict)
        grid[1][0] = 5 // Adjacent vertical
        grid[1][1] = 5 // Adjacent diagonal
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: Should detect all adjacent conflicts (row duplicates that are also adjacent are counted once)
        XCTAssertTrue(conflicts.count >= 3, "Should detect at least 3 conflicts")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 0, column: 1)), "Should detect adjacent conflict at (0,1)")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 1, column: 0)), "Should detect adjacent conflict at (1,0)")
        XCTAssertTrue(conflicts.contains(CellPosition(row: 1, column: 1)), "Should detect diagonal conflict at (1,1)")
    }

    func testDetectConflicts_EmptyCell() {
        // Given: An empty cell
        var grid = TestFixtures.emptyGrid10x3
        grid[0][1] = 2
        let position = CellPosition(row: 0, column: 0)

        // When: Detecting conflicts for an empty cell
        let conflicts = service.detectConflicts(at: position, in: grid, puzzle: testPuzzle)

        // Then: No conflicts should be found for an empty cell
        XCTAssertTrue(conflicts.isEmpty, "Empty cell should have no conflicts")
    }

    // MARK: - isColumnSumValid Tests

    func testColumnSumValid_CorrectSum() {
        // Given: A complete column that sums to the target
        // Using fixture's column sums
        let grid: [[Int?]] = TestFixtures.completedGrid10x3.map { $0.map { $0 as Int? } }

        // Create puzzle with matching sums
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 3,
            difficulty: .easy,
            targetSums: TestFixtures.columnSums10x3,
            initialGrid: grid,
            solution: TestFixtures.completedGrid10x3
        )

        // When: Validating each column sum
        for col in 0 ..< 10 {
            let isValid = service.isColumnSumValid(column: col, in: grid, puzzle: puzzle)
            XCTAssertTrue(isValid, "Column \(col) sum should be valid")
        }
    }

    func testColumnSumValid_IncorrectSum() {
        // Given: A complete column that doesn't sum to the target
        let grid: [[Int?]] = TestFixtures.completedGrid10x3.map { $0.map { $0 as Int? } }

        // Create puzzle with wrong target sums
        let wrongSums = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100]
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 3,
            difficulty: .easy,
            targetSums: wrongSums,
            initialGrid: grid,
            solution: TestFixtures.completedGrid10x3
        )

        // When: Validating column sum
        let isValid = service.isColumnSumValid(column: 0, in: grid, puzzle: puzzle)

        // Then: The sum should be invalid
        XCTAssertFalse(isValid, "Column 0 sum should be invalid with wrong target")
    }

    func testColumnSumValid_IncompleteColumn() {
        // Given: A grid with an incomplete column
        var grid = TestFixtures.emptyGrid10x3
        grid[0][0] = 5
        grid[1][0] = 3
        // Row 2, column 0 is still nil

        // When: Validating the column sum
        let isValid = service.isColumnSumValid(column: 0, in: grid, puzzle: testPuzzle)

        // Then: The sum should be invalid due to incomplete column
        XCTAssertFalse(isValid, "Incomplete column should be invalid")
    }

    func testColumnSumValid_InvalidColumn() {
        // Given: A grid
        let grid = TestFixtures.emptyGrid10x3

        // When: Validating an out-of-bounds column
        let isValidNegative = service.isColumnSumValid(column: -1, in: grid, puzzle: testPuzzle)
        let isValidTooHigh = service.isColumnSumValid(column: 10, in: grid, puzzle: testPuzzle)

        // Then: Both should be invalid
        XCTAssertFalse(isValidNegative, "Negative column index should be invalid")
        XCTAssertFalse(isValidTooHigh, "Column index >= columns should be invalid")
    }

    // MARK: - isPuzzleComplete Tests

    func testPuzzleComplete_ValidSolution() {
        // Given: A complete and correct solution using fixtures
        let grid: [[Int?]] = TestFixtures.completedGrid10x3.map { $0.map { $0 as Int? } }

        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 3,
            difficulty: .easy,
            targetSums: TestFixtures.columnSums10x3,
            initialGrid: TestFixtures.emptyGrid10x3,
            solution: TestFixtures.completedGrid10x3
        )

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: puzzle)

        // Then: The puzzle should be complete
        XCTAssertTrue(isComplete, "Valid solution should be complete")
    }

    func testPuzzleComplete_IncompletePuzzle() {
        // Given: An incomplete grid
        var grid: [[Int?]] = TestFixtures.completedGrid10x3.map { $0.map { $0 as Int? } }
        grid[2][5] = nil // Make one cell empty

        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 3,
            difficulty: .easy,
            targetSums: TestFixtures.columnSums10x3,
            initialGrid: TestFixtures.emptyGrid10x3,
            solution: TestFixtures.completedGrid10x3
        )

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: puzzle)

        // Then: The puzzle should not be complete
        XCTAssertFalse(isComplete, "Incomplete puzzle should not be complete")
    }

    func testPuzzleComplete_WithConflicts() {
        // Given: A complete grid with conflicts (adjacent duplicates)
        let grid: [[Int?]] = TestFixtures.invalidGrid_adjacentDuplicates.map { $0.map { $0 as Int? } }

        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 3,
            difficulty: .easy,
            targetSums: TestFixtures.columnSums10x3,
            initialGrid: TestFixtures.emptyGrid10x3,
            solution: TestFixtures.completedGrid10x3
        )

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: puzzle)

        // Then: The puzzle should not be complete due to conflicts
        XCTAssertFalse(isComplete, "Puzzle with conflicts should not be complete")
    }

    func testPuzzleComplete_WithIncorrectColumnSums() {
        // Given: A complete grid without conflicts but wrong column sums
        let grid: [[Int?]] = TestFixtures.completedGrid10x3.map { $0.map { $0 as Int? } }

        // Create puzzle with wrong target sums
        let wrongSums = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100]
        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 3,
            difficulty: .easy,
            targetSums: wrongSums,
            initialGrid: TestFixtures.emptyGrid10x3,
            solution: TestFixtures.completedGrid10x3
        )

        // When: Checking if puzzle is complete
        let isComplete = service.isPuzzleComplete(grid: grid, puzzle: puzzle)

        // Then: The puzzle should not be complete due to incorrect sums
        XCTAssertFalse(isComplete, "Puzzle with incorrect column sums should not be complete")
    }

    // MARK: - Edge Cases

    func testValidPlacement_CornerCell() {
        // Given: A corner cell position
        let grid = TestFixtures.emptyGrid10x3
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
        var grid = TestFixtures.emptyGrid10x3
        grid[0][4] = 1
        grid[1][3] = 2
        grid[1][5] = 3
        grid[2][4] = 4
        let position = CellPosition(row: 1, column: 4)

        // When: Placing a value not matching any adjacent value
        let isValid = service.isValidPlacement(
            value: 5,
            at: position,
            in: grid,
            puzzle: testPuzzle
        )

        // Then: Should be valid
        XCTAssertTrue(isValid, "Placing 5 at (1,4) should be valid")
    }

    func testValidPlacement_Zero() {
        // Given: An empty grid
        let grid = TestFixtures.emptyGrid10x3
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
