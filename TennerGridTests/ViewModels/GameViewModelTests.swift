//
//  GameViewModelTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

@testable import TennerGrid
import XCTest

@MainActor
final class GameViewModelTests: XCTestCase {
    // MARK: - Test Properties

    var puzzle: TennerGridPuzzle!
    var viewModel: GameViewModel!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create a simple 3x3 test puzzle
        // Solution:
        // [1, 2, 0]
        // [3, 0, 1]
        // [2, 1, 3]
        let solution = [
            [1, 2, 0],
            [3, 0, 1],
            [2, 1, 3],
        ]

        // Initial grid with some pre-filled cells
        let initialGrid: [[Int?]] = [
            [1, nil, nil],
            [nil, nil, 1],
            [nil, 1, nil],
        ]

        // Target sums: sum of each column
        let targetSums = [6, 3, 4]

        puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: solution
        )

        viewModel = GameViewModel(puzzle: puzzle)
    }

    override func tearDown() async throws {
        viewModel = nil
        puzzle = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel.gameState)
        XCTAssertNil(viewModel.selectedPosition)
        XCTAssertFalse(viewModel.notesMode)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    func testInitializationFromPuzzle() {
        let newViewModel = GameViewModel(puzzle: puzzle)
        XCTAssertNotNil(newViewModel.gameState.puzzle)
        XCTAssertNil(newViewModel.selectedPosition)
    }

    // MARK: - Cell Selection Tests

    func testSelectValidCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        XCTAssertEqual(viewModel.selectedPosition, position)
        XCTAssertEqual(viewModel.gameState.selectedCell, position)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSelectInvalidCell() {
        let position = CellPosition(row: 10, column: 10)
        viewModel.selectCell(at: position)

        XCTAssertNil(viewModel.selectedPosition)
        XCTAssertEqual(viewModel.errorMessage, "Invalid cell position")
    }

    func testClearSelection() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        XCTAssertEqual(viewModel.selectedPosition, position)

        viewModel.selectCell(at: nil)
        XCTAssertNil(viewModel.selectedPosition)
        XCTAssertNil(viewModel.gameState.selectedCell)
    }

    func testToggleCellSelection() {
        let position = CellPosition(row: 0, column: 1)

        // Toggle to select
        viewModel.toggleCellSelection(at: position)
        XCTAssertEqual(viewModel.selectedPosition, position)

        // Toggle to deselect
        viewModel.toggleCellSelection(at: position)
        XCTAssertNil(viewModel.selectedPosition)
    }

    func testToggleDifferentCellSelection() {
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 0)

        viewModel.toggleCellSelection(at: position1)
        XCTAssertEqual(viewModel.selectedPosition, position1)

        viewModel.toggleCellSelection(at: position2)
        XCTAssertEqual(viewModel.selectedPosition, position2)
    }

    func testIsSelected() {
        let position = CellPosition(row: 0, column: 1)
        XCTAssertFalse(viewModel.isSelected(at: position))

        viewModel.selectCell(at: position)
        XCTAssertTrue(viewModel.isSelected(at: position))
    }

    // MARK: - Number Entry Tests

    func testEnterValidNumber() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(2)

        XCTAssertEqual(viewModel.value(at: position), 2)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    func testEnterInvalidNumber() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(15)

        XCTAssertNil(viewModel.value(at: position))
        XCTAssertEqual(viewModel.errorMessage, "Invalid number: must be 0-9")
    }

    func testEnterNumberWithoutSelection() {
        viewModel.enterNumber(5)
        XCTAssertEqual(viewModel.errorMessage, "No cell selected")
    }

    func testEnterNumberOnPrefilledCell() {
        let position = CellPosition(row: 0, column: 0) // Pre-filled with 1
        viewModel.selectCell(at: position)
        viewModel.enterNumber(5)

        XCTAssertEqual(viewModel.value(at: position), 1) // Should remain unchanged
        XCTAssertEqual(viewModel.errorMessage, "Cannot modify pre-filled cells")
    }

    func testEnterNumberWithConflict() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Try to enter 1, which conflicts with pre-filled 1 in same row
        viewModel.enterNumber(1)

        XCTAssertNil(viewModel.value(at: position)) // Should not be placed
        XCTAssertEqual(viewModel.errorMessage, "Invalid placement: violates game rules")
        XCTAssertFalse(viewModel.conflictingPositions.isEmpty)
    }

    func testEnterNumberClearsError() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Create error
        viewModel.enterNumber(1)
        XCTAssertNotNil(viewModel.errorMessage)

        // Clear selection and select another cell
        viewModel.selectCell(at: CellPosition(row: 1, column: 0))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testEnterNumberRecordsError() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        let initialErrors = viewModel.gameState.errorCount

        // Try to enter invalid number
        viewModel.enterNumber(1)

        XCTAssertEqual(viewModel.gameState.errorCount, initialErrors + 1)
    }

    // MARK: - Clear Cell Tests

    func testClearSelectedCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(2)

        XCTAssertEqual(viewModel.value(at: position), 2)

        viewModel.clearSelectedCell()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testClearWithoutSelection() {
        viewModel.clearSelectedCell()
        XCTAssertEqual(viewModel.errorMessage, "No cell selected")
    }

    func testClearPrefilledCell() {
        let position = CellPosition(row: 0, column: 0)
        viewModel.selectCell(at: position)
        viewModel.clearSelectedCell()

        XCTAssertEqual(viewModel.value(at: position), 1) // Should remain unchanged
        XCTAssertEqual(viewModel.errorMessage, "Cannot modify pre-filled cells")
    }

    // MARK: - Notes Mode Tests

    func testToggleNotesMode() {
        XCTAssertFalse(viewModel.notesMode)

        viewModel.toggleNotesMode()
        XCTAssertTrue(viewModel.notesMode)
        XCTAssertTrue(viewModel.gameState.notesMode)

        viewModel.toggleNotesMode()
        XCTAssertFalse(viewModel.notesMode)
        XCTAssertFalse(viewModel.gameState.notesMode)
    }

    func testSetNotesMode() {
        viewModel.setNotesMode(true)
        XCTAssertTrue(viewModel.notesMode)
        XCTAssertTrue(viewModel.gameState.notesMode)

        viewModel.setNotesMode(false)
        XCTAssertFalse(viewModel.notesMode)
        XCTAssertFalse(viewModel.gameState.notesMode)
    }

    func testEnterNumberInNotesMode() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enable notes mode
        viewModel.setNotesMode(true)

        // Enter number as pencil mark
        viewModel.enterNumber(2)

        XCTAssertNil(viewModel.value(at: position)) // Cell should still be empty
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Pencil Marks Tests

    func testAddPencilMark() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.addPencilMark(5)

        XCTAssertTrue(viewModel.marks(at: position).contains(5))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAddMultiplePencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        viewModel.addPencilMark(2)
        viewModel.addPencilMark(5)
        viewModel.addPencilMark(7)

        let marks = viewModel.marks(at: position)
        XCTAssertEqual(marks.count, 3)
        XCTAssertTrue(marks.contains(2))
        XCTAssertTrue(marks.contains(5))
        XCTAssertTrue(marks.contains(7))
    }

    func testAddPencilMarkWithoutSelection() {
        viewModel.addPencilMark(5)
        XCTAssertEqual(viewModel.errorMessage, "No cell selected")
    }

    func testAddInvalidPencilMark() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.addPencilMark(15)

        XCTAssertEqual(viewModel.errorMessage, "Invalid mark: must be 0-9")
    }

    func testAddPencilMarkToFilledCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(2)
        viewModel.addPencilMark(5)

        XCTAssertEqual(viewModel.errorMessage, "Cannot add marks to filled cells")
    }

    func testRemovePencilMark() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        viewModel.addPencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        viewModel.removePencilMark(5)
        XCTAssertFalse(viewModel.marks(at: position).contains(5))
    }

    func testTogglePencilMark() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Toggle to add
        viewModel.togglePencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Toggle to remove
        viewModel.togglePencilMark(5)
        XCTAssertFalse(viewModel.marks(at: position).contains(5))
    }

    func testTogglePencilMarkWithoutSelection() {
        viewModel.togglePencilMark(5)
        XCTAssertEqual(viewModel.errorMessage, "No cell selected")
    }

    func testTogglePencilMarkOnPrefilledCell() {
        let position = CellPosition(row: 0, column: 0)
        viewModel.selectCell(at: position)
        viewModel.togglePencilMark(5)

        XCTAssertEqual(viewModel.errorMessage, "Cannot modify pre-filled cells")
    }

    func testClearPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        viewModel.addPencilMark(2)
        viewModel.addPencilMark(5)
        XCTAssertFalse(viewModel.marks(at: position).isEmpty)

        viewModel.clearPencilMarks()
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
    }

    func testEnterNumberClearsPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        viewModel.addPencilMark(5)
        viewModel.addPencilMark(7)
        XCTAssertFalse(viewModel.marks(at: position).isEmpty)

        viewModel.enterNumber(2)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
    }

    // MARK: - Validation Tests

    func testCanPlaceValidValue() {
        let position = CellPosition(row: 0, column: 1)
        XCTAssertTrue(viewModel.canPlaceValue(2, at: position))
    }

    func testCannotPlaceInvalidValue() {
        let position = CellPosition(row: 0, column: 1)
        // 1 is already in the row at position (0, 0)
        XCTAssertFalse(viewModel.canPlaceValue(1, at: position))
    }

    func testCannotPlaceInPrefilledCell() {
        let position = CellPosition(row: 0, column: 0)
        XCTAssertFalse(viewModel.canPlaceValue(5, at: position))
    }

    func testGetValidValues() {
        let position = CellPosition(row: 0, column: 1)
        let validValues = viewModel.getValidValues(for: position)

        XCTAssertFalse(validValues.isEmpty)
        // Should not contain 1 (already in row)
        XCTAssertFalse(validValues.contains(1))
    }

    func testGetValidValuesForFilledCell() {
        let position = CellPosition(row: 0, column: 0)
        let validValues = viewModel.getValidValues(for: position)
        XCTAssertTrue(validValues.isEmpty)
    }

    // MARK: - Conflict Detection Tests

    func testConflictDetection() {
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 0)

        // Place valid numbers first
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(3)

        // Verify no conflicts yet
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    func testHasConflict() {
        let position = CellPosition(row: 0, column: 1)

        XCTAssertFalse(viewModel.hasConflict(at: position))

        // This will be tested more thoroughly when we create conflicts
        // For now, just verify the method exists and returns false initially
    }

    // MARK: - Error Management Tests

    func testClearError() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Create an error
        viewModel.enterNumber(1) // Invalid
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.conflictingPositions.isEmpty)

        // Clear error
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    // MARK: - Game State Query Tests

    func testValueQuery() {
        let position = CellPosition(row: 0, column: 0)
        XCTAssertEqual(viewModel.value(at: position), 1)

        let emptyPosition = CellPosition(row: 0, column: 1)
        XCTAssertNil(viewModel.value(at: emptyPosition))
    }

    func testMarksQuery() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.addPencilMark(5)

        let marks = viewModel.marks(at: position)
        XCTAssertTrue(marks.contains(5))
    }

    func testIsEditableQuery() {
        let prefilledPosition = CellPosition(row: 0, column: 0)
        XCTAssertFalse(viewModel.isEditable(at: prefilledPosition))

        let emptyPosition = CellPosition(row: 0, column: 1)
        XCTAssertTrue(viewModel.isEditable(at: emptyPosition))
    }

    func testIsEmptyQuery() {
        let prefilledPosition = CellPosition(row: 0, column: 0)
        XCTAssertFalse(viewModel.isEmpty(at: prefilledPosition))

        let emptyPosition = CellPosition(row: 0, column: 1)
        XCTAssertTrue(viewModel.isEmpty(at: emptyPosition))
    }

    // MARK: - Game Completion Tests

    func testGameCompletionDetection() {
        // Fill in the puzzle correctly
        viewModel.selectCell(at: CellPosition(row: 0, column: 1))
        viewModel.enterNumber(2)

        viewModel.selectCell(at: CellPosition(row: 0, column: 2))
        viewModel.enterNumber(0)

        viewModel.selectCell(at: CellPosition(row: 1, column: 0))
        viewModel.enterNumber(3)

        viewModel.selectCell(at: CellPosition(row: 1, column: 1))
        viewModel.enterNumber(0)

        viewModel.selectCell(at: CellPosition(row: 2, column: 0))
        viewModel.enterNumber(2)

        viewModel.selectCell(at: CellPosition(row: 2, column: 2))
        viewModel.enterNumber(3)

        // After completing all cells correctly, game should be marked complete
        XCTAssertTrue(viewModel.gameState.isCompleted)
    }

    // MARK: - Description Tests

    func testDescription() {
        let description = viewModel.description
        XCTAssertTrue(description.contains("GameViewModel"))
        XCTAssertTrue(description.contains("notesMode"))
    }

    // MARK: - Undo/Redo Tests

    func testUndoHistory() {
        // Initially, there should be no undo history
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertEqual(viewModel.undoCount, 0)

        // Perform an action
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(2)

        // Now there should be one action in undo history
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertEqual(viewModel.undoCount, 1)
    }

    func testUndoSetValue() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a value
        viewModel.enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position), 2)
        XCTAssertTrue(viewModel.canUndo)

        // Undo the action
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUndoSetValueRestoresPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Add pencil marks
        viewModel.addPencilMark(2)
        viewModel.addPencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Enter a value (clears pencil marks)
        viewModel.enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position), 2)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo should restore pencil marks
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))
    }

    func testUndoClearCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a value
        viewModel.enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position), 2)

        // Clear the cell
        viewModel.clearSelectedCell()
        XCTAssertNil(viewModel.value(at: position))

        // Undo should restore the value
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position), 2)
    }

    func testUndoClearCellRestoresPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Add pencil marks
        viewModel.addPencilMark(3)
        viewModel.addPencilMark(7)

        // Clear the cell
        viewModel.clearSelectedCell()
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo should restore pencil marks
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).contains(3))
        XCTAssertTrue(viewModel.marks(at: position).contains(7))
    }

    func testUndoTogglePencilMark() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Toggle to add mark
        viewModel.togglePencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Undo should remove mark
        viewModel.undo()
        XCTAssertFalse(viewModel.marks(at: position).contains(5))
    }

    func testUndoSetPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Add a mark
        viewModel.addPencilMark(2)
        XCTAssertTrue(viewModel.marks(at: position).contains(2))

        // Add another mark
        viewModel.addPencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Undo last mark addition
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertFalse(viewModel.marks(at: position).contains(5))

        // Undo first mark addition
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
    }

    func testUndoMultipleActions() {
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 0)

        // Perform multiple actions
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(3)

        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertEqual(viewModel.value(at: position2), 3)
        XCTAssertEqual(viewModel.undoCount, 2)

        // Undo second action
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertEqual(viewModel.undoCount, 1)

        // Undo first action
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position1))
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertEqual(viewModel.undoCount, 0)
    }

    func testUndoWithoutHistory() {
        XCTAssertFalse(viewModel.canUndo)

        // Attempt to undo with no history
        viewModel.undo()
        XCTAssertEqual(viewModel.errorMessage, "Nothing to undo")
    }

    func testUndoMovesToRedoStack() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(2)

        XCTAssertEqual(viewModel.undoCount, 1)
        XCTAssertEqual(viewModel.redoCount, 0)

        // Undo should move action to redo stack
        viewModel.undo()
        XCTAssertEqual(viewModel.undoCount, 0)
        XCTAssertEqual(viewModel.redoCount, 1)
        XCTAssertTrue(viewModel.canRedo)
    }

    func testUndoUpdatesConflicts() {
        // Create a situation where undoing resolves conflicts
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 0, column: 2)

        // Place a valid number
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)

        // Place another valid number
        viewModel.selectCell(at: position2)
        viewModel.enterNumber(0)

        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)

        // Undo should update conflicts
        viewModel.undo()
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    func testUndoClearsErrorMessage() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Create error by entering invalid number
        viewModel.enterNumber(1) // Invalid
        XCTAssertNotNil(viewModel.errorMessage)

        // Perform a valid action
        viewModel.selectCell(at: CellPosition(row: 1, column: 0))
        viewModel.enterNumber(3)

        // Undo should clear error
        viewModel.undo()
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUndoInNotesMode() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.setNotesMode(true)

        // Enter numbers as pencil marks in notes mode
        viewModel.enterNumber(2)
        viewModel.enterNumber(5)

        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Undo last mark
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertFalse(viewModel.marks(at: position).contains(5))

        // Undo first mark
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
    }

    func testNewActionClearsRedoStack() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Perform action
        viewModel.enterNumber(2)

        // Undo
        viewModel.undo()
        XCTAssertTrue(viewModel.canRedo)
        XCTAssertEqual(viewModel.redoCount, 1)

        // Perform new action should clear redo stack
        viewModel.enterNumber(3)
        XCTAssertFalse(viewModel.canRedo)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testRedoBasicAction() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Perform action
        viewModel.enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position), 2)

        // Undo
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.canRedo)

        // Redo should restore the value
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 2)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRedoWithoutHistory() {
        XCTAssertFalse(viewModel.canRedo)

        // Attempt to redo with no history
        viewModel.redo()
        XCTAssertEqual(viewModel.errorMessage, "Nothing to redo")
    }

    func testRedoMovesToUndoStack() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(2)

        // Undo
        viewModel.undo()
        XCTAssertEqual(viewModel.undoCount, 0)
        XCTAssertEqual(viewModel.redoCount, 1)

        // Redo should move action back to undo stack
        viewModel.redo()
        XCTAssertEqual(viewModel.undoCount, 1)
        XCTAssertEqual(viewModel.redoCount, 0)
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)
    }

    func testRedoMultipleActions() {
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 0)

        // Perform multiple actions
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(3)

        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertEqual(viewModel.value(at: position2), 3)

        // Undo both actions
        viewModel.undo()
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position1))
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertEqual(viewModel.redoCount, 2)

        // Redo first action
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertEqual(viewModel.redoCount, 1)

        // Redo second action
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertEqual(viewModel.value(at: position2), 3)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testRedoClearCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a value
        viewModel.enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position), 2)

        // Clear the cell
        viewModel.clearSelectedCell()
        XCTAssertNil(viewModel.value(at: position))

        // Undo clear
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position), 2)

        // Redo clear
        viewModel.redo()
        XCTAssertNil(viewModel.value(at: position))
    }

    func testRedoPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Add pencil marks
        viewModel.addPencilMark(2)
        viewModel.addPencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Undo both marks
        viewModel.undo()
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Redo first mark
        viewModel.redo()
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertFalse(viewModel.marks(at: position).contains(5))

        // Redo second mark
        viewModel.redo()
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))
    }

    func testRedoTogglePencilMark() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Toggle to add mark
        viewModel.togglePencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Toggle to remove mark
        viewModel.togglePencilMark(5)
        XCTAssertFalse(viewModel.marks(at: position).contains(5))

        // Undo remove
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Undo add
        viewModel.undo()
        XCTAssertFalse(viewModel.marks(at: position).contains(5))

        // Redo add
        viewModel.redo()
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Redo remove
        viewModel.redo()
        XCTAssertFalse(viewModel.marks(at: position).contains(5))
    }

    func testRedoInNotesMode() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.setNotesMode(true)

        // Enter numbers as pencil marks
        viewModel.enterNumber(2)
        viewModel.enterNumber(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Undo both marks
        viewModel.undo()
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Redo first mark
        viewModel.redo()
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertFalse(viewModel.marks(at: position).contains(5))

        // Redo second mark
        viewModel.redo()
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))
    }

    func testRedoRestoresPencilMarksWhenCleared() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Add pencil marks
        viewModel.addPencilMark(2)
        viewModel.addPencilMark(5)

        // Enter a value (clears pencil marks)
        viewModel.enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position), 2)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo setValue
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Redo setValue
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 2)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
    }

    func testRedoUpdatesConflicts() {
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 0, column: 2)

        // Place valid numbers
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(0)

        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)

        // Undo both
        viewModel.undo()
        viewModel.undo()

        // Redo should update conflicts correctly
        viewModel.redo()
        viewModel.redo()
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    func testRedoClearsErrorMessage() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a value
        viewModel.enterNumber(2)

        // Undo
        viewModel.undo()

        // Create an error by trying invalid action
        viewModel.enterNumber(1) // Invalid
        XCTAssertNotNil(viewModel.errorMessage)

        // Redo should clear error
        viewModel.redo()
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUndoRedoSequence() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Perform action
        viewModel.enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position), 2)

        // Undo
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))

        // Redo
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 2)

        // Undo again
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))

        // Redo again
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 2)

        // Verify final state
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)
    }

    // MARK: - History Limit Tests

    func testHistoryLimitTo50Actions() {
        // Perform 60 actions to exceed the 50 action limit
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Perform 60 actions (alternating between values to create distinct actions)
        for i in 0 ..< 60 {
            let value = i % 10
            viewModel.enterNumber(value)
            viewModel.clearSelectedCell()
        }

        // Verify history is limited to 50
        XCTAssertEqual(viewModel.undoCount, 50, "History should be limited to 50 actions")

        // Verify we can undo exactly 50 times
        for _ in 0 ..< 50 {
            XCTAssertTrue(viewModel.canUndo)
            viewModel.undo()
        }

        // After 50 undos, there should be nothing left to undo
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertEqual(viewModel.undoCount, 0)

        // But we should have 50 actions in redo stack
        XCTAssertEqual(viewModel.redoCount, 50)
    }

    func testHistoryLimitPreservesNewestActions() {
        // Perform 55 actions
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // First 5 actions should be discarded (oldest)
        for i in 0 ..< 5 {
            viewModel.enterNumber(i)
            viewModel.clearSelectedCell()
        }

        // Next 50 actions should be preserved
        for i in 0 ..< 50 {
            viewModel.enterNumber(i % 10)
            viewModel.clearSelectedCell()
        }

        // Verify only 50 actions are stored
        XCTAssertEqual(viewModel.undoCount, 50)

        // Undo all 50 actions
        for _ in 0 ..< 50 {
            viewModel.undo()
        }

        // Verify we can't undo anymore (the first 5 actions were discarded)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertEqual(viewModel.undoCount, 0)
    }

    func testHistoryLimitWithMixedActions() {
        // Test with different action types
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 0)

        viewModel.selectCell(at: position1)

        // Perform 60 mixed actions
        for i in 0 ..< 60 {
            switch i % 4 {
            case 0:
                // Set value
                viewModel.enterNumber(i % 10)
            case 1:
                // Clear cell
                if !viewModel.isEmpty(at: position1) {
                    viewModel.clearSelectedCell()
                }
            case 2:
                // Add pencil mark
                if viewModel.isEmpty(at: position1) {
                    viewModel.addPencilMark(i % 10)
                }
            case 3:
                // Toggle pencil mark
                if viewModel.isEmpty(at: position1) {
                    viewModel.togglePencilMark(i % 10)
                }
            default:
                break
            }
        }

        // History should be limited to 50
        XCTAssertLessThanOrEqual(viewModel.undoCount, 50)
    }

    func testHistoryLimitDoesNotAffectRedoStack() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Perform 60 actions
        for i in 0 ..< 60 {
            viewModel.enterNumber(i % 10)
            viewModel.clearSelectedCell()
        }

        // Undo 30 actions
        for _ in 0 ..< 30 {
            viewModel.undo()
        }

        // Should have 20 in undo stack and 30 in redo stack
        XCTAssertEqual(viewModel.undoCount, 20)
        XCTAssertEqual(viewModel.redoCount, 30)

        // Perform a new action - this should clear redo stack but not affect undo limit
        viewModel.enterNumber(5)

        XCTAssertEqual(viewModel.undoCount, 21)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testMultipleActionSequencesWithUndoRedo() {
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 0)

        // Sequence 1: Fill position1
        viewModel.selectCell(at: position1)
        viewModel.addPencilMark(2)
        viewModel.addPencilMark(5)
        viewModel.enterNumber(2)

        XCTAssertEqual(viewModel.undoCount, 3)

        // Sequence 2: Fill position2
        viewModel.selectCell(at: position2)
        viewModel.addPencilMark(3)
        viewModel.enterNumber(3)

        XCTAssertEqual(viewModel.undoCount, 5)

        // Sequence 3: Clear position1
        viewModel.selectCell(at: position1)
        viewModel.clearSelectedCell()

        XCTAssertEqual(viewModel.undoCount, 6)

        // Undo entire sequence 3
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertEqual(viewModel.undoCount, 5)

        // Undo entire sequence 2
        viewModel.undo() // Undo enterNumber(3)
        viewModel.undo() // Undo addPencilMark(3)
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertTrue(viewModel.marks(at: position2).isEmpty)
        XCTAssertEqual(viewModel.undoCount, 3)

        // Undo entire sequence 1
        viewModel.undo() // Undo enterNumber(2)
        viewModel.undo() // Undo addPencilMark(5)
        viewModel.undo() // Undo addPencilMark(2)
        XCTAssertNil(viewModel.value(at: position1))
        XCTAssertTrue(viewModel.marks(at: position1).isEmpty)
        XCTAssertEqual(viewModel.undoCount, 0)

        // Verify we can redo all sequences
        XCTAssertEqual(viewModel.redoCount, 6)

        // Redo sequence 1
        viewModel.redo() // Redo addPencilMark(2)
        viewModel.redo() // Redo addPencilMark(5)
        viewModel.redo() // Redo enterNumber(2)
        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertEqual(viewModel.undoCount, 3)

        // Redo sequence 2
        viewModel.redo() // Redo addPencilMark(3)
        viewModel.redo() // Redo enterNumber(3)
        XCTAssertEqual(viewModel.value(at: position2), 3)
        XCTAssertEqual(viewModel.undoCount, 5)

        // Redo sequence 3
        viewModel.redo() // Redo clearSelectedCell
        XCTAssertNil(viewModel.value(at: position1))
        XCTAssertEqual(viewModel.undoCount, 6)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testComplexActionSequenceWithPartialUndoRedo() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Build up a complex state
        viewModel.addPencilMark(1)
        viewModel.addPencilMark(2)
        viewModel.addPencilMark(3)
        viewModel.togglePencilMark(2) // Remove 2
        viewModel.enterNumber(3) // Clear marks and set value
        viewModel.clearSelectedCell() // Clear value

        XCTAssertEqual(viewModel.undoCount, 6)
        XCTAssertTrue(viewModel.isEmpty(at: position))
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo half the sequence
        viewModel.undo() // Undo clear
        XCTAssertEqual(viewModel.value(at: position), 3)

        viewModel.undo() // Undo setValue(3)
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.marks(at: position).contains(1))
        XCTAssertFalse(viewModel.marks(at: position).contains(2))
        XCTAssertTrue(viewModel.marks(at: position).contains(3))

        viewModel.undo() // Undo toggle (restore 2)
        XCTAssertTrue(viewModel.marks(at: position).contains(2))

        XCTAssertEqual(viewModel.undoCount, 3)
        XCTAssertEqual(viewModel.redoCount, 3)

        // Perform new action in middle of sequence
        viewModel.addPencilMark(5)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

        // Redo stack should be cleared
        XCTAssertEqual(viewModel.redoCount, 0)
        XCTAssertEqual(viewModel.undoCount, 4)

        // Verify we can still undo to beginning
        for _ in 0 ..< 4 {
            viewModel.undo()
        }
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
        XCTAssertEqual(viewModel.undoCount, 0)
    }

    func testActionSequencePreservesGameState() {
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 0, column: 2)

        // Create a specific game state
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(0)

        XCTAssertEqual(viewModel.value(at: position1), 2)
        XCTAssertEqual(viewModel.value(at: position2), 0)

        // Store state
        let savedValue1 = viewModel.value(at: position1)
        let savedValue2 = viewModel.value(at: position2)

        // Perform many operations and undo all
        for i in 0 ..< 10 {
            viewModel.selectCell(at: position1)
            viewModel.enterNumber((i + 3) % 10)
            viewModel.clearSelectedCell()
        }

        // Undo all 20 actions (10 enter + 10 clear)
        for _ in 0 ..< 20 {
            viewModel.undo()
        }

        // Verify state is restored
        XCTAssertEqual(viewModel.value(at: position1), savedValue1)
        XCTAssertEqual(viewModel.value(at: position2), savedValue2)
    }

    // MARK: - Timer & Game Flow Tests

    func testTimerStartsAutomatically() {
        // Timer should start automatically when creating a new game
        XCTAssertTrue(viewModel.isTimerRunning)
        XCTAssertEqual(viewModel.elapsedTime, 0, accuracy: 0.1)
    }

    func testTimerDoesNotStartWhenGameIsPaused() async {
        // Create a paused game state
        var pausedState = GameState(puzzle: puzzle)
        pausedState.pause()

        let pausedViewModel = GameViewModel(gameState: pausedState)

        // Timer should not be running
        XCTAssertFalse(pausedViewModel.isTimerRunning)
        XCTAssertTrue(pausedViewModel.gameState.isPaused)
    }

    func testTimerDoesNotStartWhenGameIsCompleted() async {
        // Create a completed game state
        var completedState = GameState(puzzle: puzzle)
        completedState.complete()

        let completedViewModel = GameViewModel(gameState: completedState)

        // Timer should not be running
        XCTAssertFalse(completedViewModel.isTimerRunning)
        XCTAssertTrue(completedViewModel.gameState.isCompleted)
    }

    func testTimerUpdatesElapsedTime() async {
        // Start fresh
        let newViewModel = GameViewModel(puzzle: puzzle)
        XCTAssertEqual(newViewModel.elapsedTime, 0, accuracy: 0.1)

        // Wait for a bit
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Elapsed time should have increased
        XCTAssertGreaterThan(newViewModel.elapsedTime, 0.3)
        XCTAssertLessThan(newViewModel.elapsedTime, 0.8)
    }

    func testPauseTimer() async {
        // Start fresh
        let newViewModel = GameViewModel(puzzle: puzzle)

        // Wait for a bit
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Pause the timer
        newViewModel.pauseTimer()

        XCTAssertFalse(newViewModel.isTimerRunning)
        XCTAssertTrue(newViewModel.gameState.isPaused)

        let timeAfterPause = newViewModel.elapsedTime

        // Wait a bit more
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Time should not have changed significantly
        XCTAssertEqual(newViewModel.elapsedTime, timeAfterPause, accuracy: 0.05)
    }

    func testResumeTimer() async {
        // Start fresh
        let newViewModel = GameViewModel(puzzle: puzzle)

        // Pause the timer
        newViewModel.pauseTimer()
        XCTAssertFalse(newViewModel.isTimerRunning)

        let timeAfterPause = newViewModel.elapsedTime

        // Resume the timer
        newViewModel.resumeTimer()

        XCTAssertTrue(newViewModel.isTimerRunning)
        XCTAssertFalse(newViewModel.gameState.isPaused)

        // Wait for a bit
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Time should have increased
        XCTAssertGreaterThan(newViewModel.elapsedTime, timeAfterPause + 0.2)
    }

    func testPauseResumeCycle() async {
        // Start fresh
        let newViewModel = GameViewModel(puzzle: puzzle)

        // Let it run for a bit
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        let time1 = newViewModel.elapsedTime

        // Pause
        newViewModel.pauseTimer()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        let time2 = newViewModel.elapsedTime

        // Should not have increased much during pause
        XCTAssertEqual(time2, time1, accuracy: 0.05)

        // Resume
        newViewModel.resumeTimer()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        let time3 = newViewModel.elapsedTime

        // Should have increased after resume
        XCTAssertGreaterThan(time3, time2 + 0.15)
    }

    func testFormattedTime() {
        // Test zero time
        viewModel.pauseTimer() // Pause to prevent updates
        XCTAssertEqual(viewModel.formattedTime, "00:00")

        // Manually set time for testing
        var testState1 = viewModel.gameState
        testState1.addTime(65.0) // 1 minute 5 seconds
        let formatted1 = GameViewModel(gameState: testState1).formattedTime
        XCTAssertEqual(formatted1, "01:05")

        // Test larger time
        var testState2 = testState1
        testState2.addTime(595.0) // Add 9 minutes 55 seconds (total 11:00)
        let formatted2 = GameViewModel(gameState: testState2).formattedTime
        XCTAssertEqual(formatted2, "11:00")
    }

    func testTimerStopsOnCompletion() async {
        // Create a nearly complete puzzle
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 0, column: 2)
        let position3 = CellPosition(row: 1, column: 0)
        let position4 = CellPosition(row: 1, column: 1)
        let position5 = CellPosition(row: 2, column: 0)
        let position6 = CellPosition(row: 2, column: 2)

        // Fill all cells except the last one
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(0)

        viewModel.selectCell(at: position3)
        viewModel.enterNumber(3)

        viewModel.selectCell(at: position4)
        viewModel.enterNumber(0)

        viewModel.selectCell(at: position5)
        viewModel.enterNumber(2)

        // Timer should still be running
        XCTAssertTrue(viewModel.isTimerRunning)
        XCTAssertFalse(viewModel.gameState.isCompleted)

        // Complete the puzzle
        viewModel.selectCell(at: position6)
        viewModel.enterNumber(3)

        // Timer should have stopped
        XCTAssertFalse(viewModel.isTimerRunning)
        XCTAssertTrue(viewModel.gameState.isCompleted)

        let timeAfterCompletion = viewModel.elapsedTime

        // Wait a bit
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Time should not increase after completion
        XCTAssertEqual(viewModel.elapsedTime, timeAfterCompletion, accuracy: 0.05)
    }

    func testStartTimerWhenAlreadyRunning() {
        // Timer starts automatically
        XCTAssertTrue(viewModel.isTimerRunning)

        // Try to start again
        viewModel.startTimer()

        // Should still be running (no crash or error)
        XCTAssertTrue(viewModel.isTimerRunning)
    }

    func testStartTimerAfterCompletion() async {
        // Complete the game first
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 0, column: 2)
        let position3 = CellPosition(row: 1, column: 0)
        let position4 = CellPosition(row: 1, column: 1)
        let position5 = CellPosition(row: 2, column: 0)
        let position6 = CellPosition(row: 2, column: 2)

        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2)
        viewModel.selectCell(at: position2)
        viewModel.enterNumber(0)
        viewModel.selectCell(at: position3)
        viewModel.enterNumber(3)
        viewModel.selectCell(at: position4)
        viewModel.enterNumber(0)
        viewModel.selectCell(at: position5)
        viewModel.enterNumber(2)
        viewModel.selectCell(at: position6)
        viewModel.enterNumber(3)

        XCTAssertTrue(viewModel.gameState.isCompleted)
        XCTAssertFalse(viewModel.isTimerRunning)

        // Try to start timer after completion
        viewModel.startTimer()

        // Should still not be running
        XCTAssertFalse(viewModel.isTimerRunning)
    }

    func testElapsedTimeMatchesGameState() async {
        // Let timer run for a bit
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Pause to get consistent values
        viewModel.pauseTimer()

        // ViewModel elapsed time and game state elapsed time should match
        XCTAssertEqual(viewModel.elapsedTime, viewModel.gameState.elapsedTime, accuracy: 0.1)
    }

    func testTimerPreservesTimeAcrossViewModelCreation() async {
        // Let timer run
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Pause and capture state
        viewModel.pauseTimer()
        let savedTime = viewModel.elapsedTime
        let savedState = viewModel.gameState

        // Create new view model with saved state
        let newViewModel = GameViewModel(gameState: savedState)

        // Elapsed time should be preserved
        XCTAssertEqual(newViewModel.elapsedTime, savedTime, accuracy: 0.1)
        XCTAssertEqual(newViewModel.gameState.elapsedTime, savedTime, accuracy: 0.1)
    }

    func testViewModelDeallocatesCleanlyWithRunningTimer() async {
        // Create a view model in a scope that will deallocate it
        weak var weakViewModel: GameViewModel?

        autoreleasepool {
            let tempViewModel = GameViewModel(puzzle: puzzle)
            weakViewModel = tempViewModel

            // Verify timer is running
            XCTAssertTrue(tempViewModel.isTimerRunning)

            // Let it run briefly
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // tempViewModel goes out of scope and should deallocate
        }

        // Wait for deallocation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify the view model was deallocated (no memory leak)
        XCTAssertNil(weakViewModel, "GameViewModel should deallocate cleanly even with running timer")
    }

    func testViewModelDeallocatesCleanlyWhenPaused() async {
        weak var weakViewModel: GameViewModel?

        autoreleasepool {
            let tempViewModel = GameViewModel(puzzle: puzzle)
            weakViewModel = tempViewModel

            // Pause the timer before deallocation
            tempViewModel.pauseTimer()
            XCTAssertFalse(tempViewModel.isTimerRunning)

            // tempViewModel goes out of scope and should deallocate
        }

        // Wait for deallocation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify the view model was deallocated
        XCTAssertNil(weakViewModel, "GameViewModel should deallocate cleanly when paused")
    }
}
