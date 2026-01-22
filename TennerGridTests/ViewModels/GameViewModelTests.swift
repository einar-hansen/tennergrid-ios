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
}
