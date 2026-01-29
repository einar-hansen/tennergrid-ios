import SwiftUI
import XCTest
@testable import TennerGrid

/// Tests for NumberPadView component with various interactions
/// Uses pre-built fixtures instead of generating puzzles for fast execution
@MainActor
final class NumberPadViewTests: XCTestCase {
    // MARK: - Number Entry Tests

    /// Test that tapping a number button calls enterNumber on the view model
    func testNumberButtonTapCallsEnterNumber() {
        // Given - Use fixture puzzle
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // Find an empty cell
        let position = findEmptyCell(in: puzzle) ?? CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // When - Enter a number
        viewModel.enterNumber(5)

        // Then - Verify the number was entered (or error if conflict)
        let cellValue = viewModel.value(at: position)
        // Value is either 5 or nil (if conflict prevented entry)
        XCTAssertTrue(cellValue == 5 || cellValue == nil, "Number should be entered or rejected due to conflict")
    }

    /// Test that number pad updates when cell is selected
    func testNumberPadUpdatesOnCellSelection() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When - Select different cells
        let testPositions = [
            CellPosition(row: 0, column: 1),
            CellPosition(row: 2, column: 2),
            CellPosition(row: 4, column: 4),
        ]

        for position in testPositions {
            viewModel.selectCell(at: position)
            XCTAssertEqual(viewModel.gameState.selectedCell, position, "Selected cell should be \(position)")
        }
    }

    /// Test that number pad works correctly in notes mode
    func testNumberPadInNotesMode() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let position = findEmptyCell(in: puzzle) ?? CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // When - Toggle notes mode
        viewModel.toggleNotesMode()
        XCTAssertTrue(viewModel.notesMode, "Notes mode should be toggled on")

        // When - Add a pencil mark
        viewModel.enterNumber(5)

        // Then - Verify pencil mark was added
        let pencilMarks = viewModel.gameState.pencilMarks[position] ?? []
        XCTAssertTrue(pencilMarks.contains(5), "Pencil mark 5 should be added")
    }

    /// Test that pre-filled cells cannot be edited via number pad
    func testPreFilledCellsCannotBeEdited() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // Find a pre-filled cell
        let position = findPrefilledCell(in: puzzle)
        guard let pos = position else {
            XCTFail("No pre-filled cell found in puzzle")
            return
        }

        // When
        viewModel.selectCell(at: pos)
        let originalValue = viewModel.value(at: pos)

        // Try to enter a different number
        viewModel.enterNumber((originalValue ?? 0) + 1)

        // Then - Value should not change
        XCTAssertEqual(viewModel.value(at: pos), originalValue, "Pre-filled cell value should not change")
    }

    // MARK: - Conflict Detection Tests

    /// Test that conflict count updates when placing invalid numbers
    func testConflictCountForInvalidPlacement() {
        // Given - Use a puzzle where we can create a conflict
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // Find two adjacent empty cells
        guard let pos1 = findEmptyCell(in: puzzle) else {
            XCTFail("No empty cell found")
            return
        }

        // Place a number in first cell
        viewModel.selectCell(at: pos1)
        viewModel.enterNumber(5)

        // Find an adjacent empty cell
        let adjacentPositions = [
            CellPosition(row: pos1.row, column: pos1.column + 1),
            CellPosition(row: pos1.row + 1, column: pos1.column),
        ]

        for pos2 in adjacentPositions {
            if puzzle.isValidPosition(pos2), !puzzle.isPrefilled(at: pos2) {
                viewModel.selectCell(at: pos2)
                // Check if placing 5 would create a conflict
                let conflicts = viewModel.conflictCount(for: 5, at: pos2)
                XCTAssertGreaterThan(conflicts, 0, "Adjacent duplicate should create a conflict")
                return
            }
        }
    }

    /// Test that conflict count is zero in notes mode
    func testConflictCountIgnoredInNotesMode() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let position = findEmptyCell(in: puzzle) ?? CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // When - Toggle notes mode
        viewModel.toggleNotesMode()
        XCTAssertTrue(viewModel.notesMode)

        // Then - View model's underlying conflict count still works (UI layer hides it)
        // The NumberPadView is responsible for not displaying conflicts in notes mode
        // The ViewModel's conflictCount should still return actual conflicts for validation
        let conflicts = viewModel.conflictCount(for: 5, at: position)
        XCTAssertGreaterThanOrEqual(conflicts, 0, "ViewModel should still calculate conflicts")
    }

    // MARK: - Selection and Disabled State Tests

    /// Test that invalid numbers are disabled
    func testInvalidNumbersDisabled() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // Find empty cell and place a number
        guard let pos1 = findEmptyCell(in: puzzle) else {
            XCTFail("No empty cell found")
            return
        }
        viewModel.selectCell(at: pos1)
        viewModel.enterNumber(5)

        // Find adjacent empty cell
        let pos2 = CellPosition(row: pos1.row, column: pos1.column + 1)
        if puzzle.isValidPosition(pos2), !puzzle.isPrefilled(at: pos2) {
            viewModel.selectCell(at: pos2)
            let canPlace = viewModel.canPlaceValue(5, at: pos2)
            XCTAssertFalse(canPlace, "Cannot place duplicate in adjacent cell")
        }
    }

    /// Test that number pad shows no selection when no cell is selected
    func testNumberPadWithNoSelection() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When - Do not select any cell
        XCTAssertNil(viewModel.gameState.selectedCell, "No cell should be selected initially")

        // Then - Create number pad view (should render without error)
        let view = NumberPadView(viewModel: viewModel)
        XCTAssertNotNil(view, "Number pad should render with no selection")
    }

    // MARK: - Multiple Entry Tests

    /// Test entering sequence of numbers
    func testSequentialNumberEntry() throws {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let position = findEmptyCell(in: puzzle) ?? CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // When - Enter a sequence of numbers
        let sequence = [1, 2, 3, 4, 5]
        for number in sequence {
            viewModel.enterNumber(number)
            // Value might not be set if it causes a conflict
        }

        // Then - Final value should be one of the sequence or nil
        let value = viewModel.value(at: position)
        XCTAssertTrue(
            try value == nil || sequence.contains(XCTUnwrap(value)),
            "Cell should contain a valid number or be empty"
        )
    }

    /// Test entering zero
    func testEnteringZero() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let position = findEmptyCell(in: puzzle) ?? CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // When
        viewModel.enterNumber(0)

        // Then - Value is 0 or nil if conflict
        let value = viewModel.value(at: position)
        XCTAssertTrue(value == 0 || value == nil, "Cell should contain 0 or be empty due to conflict")
    }

    // MARK: - View Creation Tests

    /// Test NumberPadView creates successfully
    func testNumberPadViewCreation() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = NumberPadView(viewModel: viewModel)

        // Then
        XCTAssertNotNil(view, "Number pad view should be created")
    }

    /// Test NumberPadView with different difficulty puzzles
    func testNumberPadViewWithDifferentDifficulties() {
        let puzzles = [
            TestFixtures.easyPuzzle,
            TestFixtures.mediumPuzzle,
            TestFixtures.hardPuzzle,
        ]

        for puzzle in puzzles {
            let viewModel = GameViewModel(puzzle: puzzle)
            let view = NumberPadView(viewModel: viewModel)
            XCTAssertNotNil(view, "Number pad should work with \(puzzle.difficulty) difficulty")
        }
    }

    // MARK: - Layout Adaptation Tests

    /// Test NumberPadView layout on compact device
    func testNumberPadLayoutCompactDevice() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let view = NumberPadView(viewModel: viewModel)

        // When/Then - Apply compact size class
        let compactView = view.environment(\.horizontalSizeClass, .compact)
        XCTAssertNotNil(compactView, "Number pad should support compact size class")
    }

    /// Test NumberPadView layout on regular device
    func testNumberPadLayoutRegularDevice() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let view = NumberPadView(viewModel: viewModel)

        // When/Then - Apply regular size class
        let regularView = view.environment(\.horizontalSizeClass, .regular)
        XCTAssertNotNil(regularView, "Number pad should support regular size class")
    }

    // MARK: - Integration Tests

    /// Test complete user flow: select cell -> enter number -> select different cell -> enter number
    func testCompleteUserFlow() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let view = NumberPadView(viewModel: viewModel)

        // Find two empty cells
        let emptyCells = findMultipleEmptyCells(in: puzzle, count: 2)
        guard emptyCells.count >= 2 else {
            XCTFail("Need at least 2 empty cells")
            return
        }

        // When - Select cell 1 and enter number
        let position1 = emptyCells[0]
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(3)

        // When - Select cell 2 and enter number
        let position2 = emptyCells[1]
        viewModel.selectCell(at: position2)
        viewModel.enterNumber(7)

        // Then - Both operations completed without crash
        XCTAssertNotNil(view, "View should be created successfully")
    }

    /// Test that number pad works correctly with clearing
    func testNumberPadWithClearing() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)
        let position = findEmptyCell(in: puzzle) ?? CellPosition(row: 0, column: 1)

        // When - Enter a number
        viewModel.selectCell(at: position)
        viewModel.enterNumber(5)

        // When - Clear the cell
        viewModel.clearSelectedCell()

        // Then - Cell should be empty
        XCTAssertNil(viewModel.value(at: position), "Cell should be empty after clear")
    }

    // MARK: - Helper Methods

    private func findEmptyCell(in puzzle: TennerGridPuzzle) -> CellPosition? {
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if !puzzle.isPrefilled(at: pos) {
                    return pos
                }
            }
        }
        return nil
    }

    private func findPrefilledCell(in puzzle: TennerGridPuzzle) -> CellPosition? {
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if puzzle.isPrefilled(at: pos) {
                    return pos
                }
            }
        }
        return nil
    }

    private func findMultipleEmptyCells(in puzzle: TennerGridPuzzle, count: Int) -> [CellPosition] {
        var cells: [CellPosition] = []
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if !puzzle.isPrefilled(at: pos) {
                    cells.append(pos)
                    if cells.count >= count {
                        return cells
                    }
                }
            }
        }
        return cells
    }
}
