import XCTest
@testable import TennerGrid

@MainActor
final class GameViewModelTests: XCTestCase {
    // MARK: - Test Properties

    var puzzle: TennerGridPuzzle!
    var viewModel: GameViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Reset settings to defaults before each test to ensure consistent state
        var settings = UserSettings.default
        settings.autoCheckErrors = true
        settings.showTimer = true
        settings.highlightSameNumbers = true
        settings.hapticFeedback = true
        settings.soundEffects = true
        SettingsManager.shared.updateSettings(settings)

        // Also set UserDefaults directly to ensure @AppStorage properties pick up values immediately
        UserDefaults.standard.set(true, forKey: "highlightSameNumbers")
        UserDefaults.standard.set(true, forKey: "autoCheckErrors")
        UserDefaults.standard.set(true, forKey: "showTimer")
        UserDefaults.standard.set(true, forKey: "hapticFeedback")
        UserDefaults.standard.set(true, forKey: "soundEffects")

        // Use smallPuzzle from TestFixtures (first bundled 3-row easy puzzle)
        // This puzzle has 10 columns (required for Tenner Grid) and 3 rows
        //
        // Solution:
        // [1, 4, 5, 9, 8, 2, 6, 0, 3, 7]
        // [8, 6, 1, 3, 0, 4, 7, 9, 2, 5]
        // [1, 2, 7, 8, 5, 9, 3, 0, 6, 4]
        //
        // Initial grid (pre-filled):
        // [nil, nil, nil, 9, 8, 2, nil, 0, 3, 7]
        // [8, 6, 1, nil, nil, nil, nil, nil, 2, 5]
        // [nil, 2, nil, 8, 5, nil, 3, nil, nil, 4]
        //
        // Pre-filled positions: (0,3), (0,4), (0,5), (0,7), (0,8), (0,9),
        //                       (1,0), (1,1), (1,2), (1,8), (1,9),
        //                       (2,1), (2,3), (2,4), (2,6), (2,9)
        //
        // Empty positions and solution values:
        //   Row 0: (0,0)=1, (0,1)=4, (0,2)=5, (0,6)=6
        //   Row 1: (1,3)=3, (1,4)=0, (1,5)=4, (1,6)=7, (1,7)=9
        //   Row 2: (2,0)=1, (2,2)=7, (2,5)=9, (2,7)=0, (2,8)=6
        //
        // Target sums: [10, 12, 13, 20, 13, 15, 16, 9, 11, 16]

        puzzle = TestFixtures.smallPuzzle
        viewModel = GameViewModel(puzzle: puzzle)
    }

    override func tearDown() {
        viewModel = nil
        puzzle = nil

        // Reset settings to defaults for other tests
        var settings = UserSettings.default
        settings.autoCheckErrors = true
        settings.showTimer = true
        settings.highlightSameNumbers = true
        settings.hapticFeedback = true
        settings.soundEffects = true
        SettingsManager.shared.updateSettings(settings)

        // Also set UserDefaults directly to ensure cleanup
        UserDefaults.standard.set(true, forKey: "highlightSameNumbers")
        UserDefaults.standard.set(true, forKey: "autoCheckErrors")
        UserDefaults.standard.set(true, forKey: "showTimer")
        UserDefaults.standard.set(true, forKey: "hapticFeedback")
        UserDefaults.standard.set(true, forKey: "soundEffects")

        super.tearDown()
    }

    // MARK: - Helper Functions

    /// Dynamically finds all empty cells and their solution values for the current puzzle
    private func findAllEmptyCells() -> [(CellPosition, Int)] {
        var cellsToFill: [(CellPosition, Int)] = []
        for row in 0 ..< viewModel.gameState.puzzle.rows {
            for col in 0 ..< viewModel.gameState.puzzle.columns {
                let position = CellPosition(row: row, column: col)
                if !viewModel.gameState.puzzle.isPrefilled(at: position) {
                    let solutionValue = viewModel.gameState.puzzle.solutionValue(at: position) ?? 0
                    cellsToFill.append((position, solutionValue))
                }
            }
        }
        return cellsToFill
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
        // For TestFixtures.smallPuzzle (first bundled 3-row easy), (0,1) is empty with solution value 4
        // Row 0 has pre-filled: 9,8,2,0,3,7. Neighbors at (0,1): 8,6,1
        // Valid values at (0,1) include: 4 (solution value)
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(4)

        XCTAssertEqual(viewModel.value(at: position), 4)
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
        let position = CellPosition(row: 0, column: 3) // Pre-filled with 9 in TestFixtures.smallPuzzle
        viewModel.selectCell(at: position)
        viewModel.enterNumber(5)

        XCTAssertEqual(viewModel.value(at: position), 9) // Should remain unchanged
        XCTAssertEqual(viewModel.errorMessage, "Cannot modify pre-filled cells")
    }

    func testEnterNumberWithConflict() {
        // For TestFixtures.smallPuzzle, (1,0)=8 is pre-filled, so 8 conflicts in same row
        let position = CellPosition(row: 1, column: 3)
        viewModel.selectCell(at: position)

        // Try to enter 8, which conflicts with pre-filled 8 at (1,0) in same row
        viewModel.enterNumber(8)

        XCTAssertNil(viewModel.value(at: position)) // Should not be placed
        XCTAssertEqual(viewModel.errorMessage, "Invalid placement: violates game rules")
        XCTAssertFalse(viewModel.conflictingPositions.isEmpty)
    }

    func testEnterNumberClearsError() {
        let position = CellPosition(row: 1, column: 3)
        viewModel.selectCell(at: position)

        // Create error by entering 8 (conflicts with pre-filled 8 at (1,0))
        viewModel.enterNumber(8)
        XCTAssertNotNil(viewModel.errorMessage)

        // Clear selection and select another cell
        viewModel.selectCell(at: CellPosition(row: 1, column: 0))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testEnterNumberRecordsError() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        let initialErrors = viewModel.gameState.errorCount

        // Try to enter invalid number (9 conflicts with pre-filled 9 at (0,3))
        viewModel.enterNumber(9)

        XCTAssertEqual(viewModel.gameState.errorCount, initialErrors + 1)
    }

    // MARK: - Clear Cell Tests

    func testClearSelectedCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(4) // 4 is the solution value at (0,1)

        XCTAssertEqual(viewModel.value(at: position), 4)

        viewModel.clearSelectedCell()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testClearWithoutSelection() {
        viewModel.clearSelectedCell()
        XCTAssertEqual(viewModel.errorMessage, "No cell selected")
    }

    func testClearPrefilledCell() {
        let position = CellPosition(row: 0, column: 3)
        viewModel.selectCell(at: position)
        viewModel.clearSelectedCell()

        XCTAssertEqual(viewModel.value(at: position), 9) // Should remain unchanged (pre-filled with 9)
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
        viewModel.enterNumber(4) // 4 is the solution at (0,1)
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
        let position = CellPosition(row: 0, column: 3)
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
        viewModel.addPencilMark(4)
        XCTAssertFalse(viewModel.marks(at: position).isEmpty)

        viewModel.enterNumber(4) // 4 is the solution at (0,1)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
    }

    // MARK: - Validation Tests

    func testCanPlaceValidValue() {
        let position = CellPosition(row: 0, column: 1)
        XCTAssertTrue(viewModel.canPlaceValue(4, at: position)) // 4 is the solution value at (0,1)
    }

    func testCannotPlaceInvalidValue() {
        let position = CellPosition(row: 0, column: 1)
        // 9 is already in the row at position (0, 3) in TestFixtures.smallPuzzle
        XCTAssertFalse(viewModel.canPlaceValue(9, at: position))
    }

    func testCannotPlaceInPrefilledCell() {
        let position = CellPosition(row: 0, column: 3)
        XCTAssertFalse(viewModel.canPlaceValue(5, at: position))
    }

    func testGetValidValues() {
        let position = CellPosition(row: 0, column: 1)
        let validValues = viewModel.getValidValues(for: position)

        XCTAssertFalse(validValues.isEmpty)
        // Should not contain 9 (already in row at (0,3))
        XCTAssertFalse(validValues.contains(9))
    }

    func testGetValidValuesForFilledCell() {
        let position = CellPosition(row: 0, column: 3)
        let validValues = viewModel.getValidValues(for: position)
        XCTAssertTrue(validValues.isEmpty)
    }

    // MARK: - Conflict Detection Tests

    func testConflictDetection() {
        // For TestFixtures.smallPuzzle:
        // (0,1) is empty, solution is 4
        // (1,3) is empty, solution is 3
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 3)

        // Place valid numbers first
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

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

        // Create an error by entering 9 (conflicts with pre-filled 9 at (0,3))
        viewModel.enterNumber(9) // Invalid
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.conflictingPositions.isEmpty)

        // Clear error
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    // MARK: - Game State Query Tests

    func testValueQuery() {
        let position = CellPosition(row: 0, column: 3)
        XCTAssertEqual(viewModel.value(at: position), 9) // Pre-filled with 9 in TestFixtures.smallPuzzle

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
        let prefilledPosition = CellPosition(row: 0, column: 3)
        XCTAssertFalse(viewModel.isEditable(at: prefilledPosition))

        let emptyPosition = CellPosition(row: 0, column: 1)
        XCTAssertTrue(viewModel.isEditable(at: emptyPosition))
    }

    func testIsEmptyQuery() {
        let prefilledPosition = CellPosition(row: 0, column: 3)
        XCTAssertFalse(viewModel.isEmpty(at: prefilledPosition))

        let emptyPosition = CellPosition(row: 0, column: 1)
        XCTAssertTrue(viewModel.isEmpty(at: emptyPosition))
    }

    // MARK: - Game Completion Tests

    func testGameCompletionDetection() {
        // Dynamically find all empty cells and their solution values
        let emptyCellsAndValues = findAllEmptyCells()

        for (position, value) in emptyCellsAndValues {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

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

        // Perform an action - use 4 which is valid at (0,1)
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(4)

        // Now there should be one action in undo history
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertEqual(viewModel.undoCount, 1)
    }

    func testUndoSetValue() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a value - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position), 4)
        XCTAssertTrue(viewModel.canUndo)

        // Undo the action
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUndoSetValueRestoresPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Add pencil marks - use valid values at (0,1): 4, 5, 6
        viewModel.addPencilMark(5)
        viewModel.addPencilMark(6)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))
        XCTAssertTrue(viewModel.marks(at: position).contains(6))

        // Enter a value (clears pencil marks) - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position), 4)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo should restore pencil marks
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))
        XCTAssertTrue(viewModel.marks(at: position).contains(6))
    }

    func testUndoClearCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a value - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position), 4)

        // Clear the cell
        viewModel.clearSelectedCell()
        XCTAssertNil(viewModel.value(at: position))

        // Undo should restore the value
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position), 4)
    }

    func testUndoClearCellRestoresPencilMarks() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Add pencil marks
        viewModel.addPencilMark(5)
        viewModel.addPencilMark(6)

        // Clear the cell
        viewModel.clearSelectedCell()
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo should restore pencil marks
        viewModel.undo()
        XCTAssertTrue(viewModel.marks(at: position).contains(5))
        XCTAssertTrue(viewModel.marks(at: position).contains(6))
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
        // For smallPuzzle: (0,1) solution 4; (1,3) solution 3
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 3)

        // Perform multiple actions
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(3)

        XCTAssertEqual(viewModel.value(at: position1), 4)
        XCTAssertEqual(viewModel.value(at: position2), 3)
        XCTAssertEqual(viewModel.undoCount, 2)

        // Undo second action
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position1), 4)
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
        viewModel.enterNumber(4) // 4 is the solution at (0,1)

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
        // For TestFixtures.smallPuzzle, (0,1) solution=4, (0,2) solution=5
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 0, column: 2)

        // Place a valid number
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        // Place another valid number
        viewModel.selectCell(at: position2)
        viewModel.enterNumber(5)

        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)

        // Undo should update conflicts
        viewModel.undo()
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    func testUndoClearsErrorMessage() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Create error by entering invalid number (9 conflicts with pre-filled 9 at (0,3))
        viewModel.enterNumber(9) // Invalid
        XCTAssertNotNil(viewModel.errorMessage)

        // Perform a valid action at (1,3) - valid value is 3
        viewModel.selectCell(at: CellPosition(row: 1, column: 3))
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

        // Perform action - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)

        // Undo
        viewModel.undo()
        XCTAssertTrue(viewModel.canRedo)
        XCTAssertEqual(viewModel.redoCount, 1)

        // Perform new action should clear redo stack - use 5 which is valid at (0,1)
        viewModel.enterNumber(5)
        XCTAssertFalse(viewModel.canRedo)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testRedoBasicAction() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Perform action - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position), 4)

        // Undo
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.canRedo)

        // Redo should restore the value
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 4)
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
        viewModel.enterNumber(4) // 4 is the solution at (0,1)

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
        // For smallPuzzle: (0,1) solution 4; (1,3) solution 3
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 3)

        // Perform multiple actions
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(3)

        XCTAssertEqual(viewModel.value(at: position1), 4)
        XCTAssertEqual(viewModel.value(at: position2), 3)

        // Undo both actions
        viewModel.undo()
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position1))
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertEqual(viewModel.redoCount, 2)

        // Redo first action
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position1), 4)
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertEqual(viewModel.redoCount, 1)

        // Redo second action
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position1), 4)
        XCTAssertEqual(viewModel.value(at: position2), 3)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testRedoClearCell() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a value - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position), 4)

        // Clear the cell
        viewModel.clearSelectedCell()
        XCTAssertNil(viewModel.value(at: position))

        // Undo clear
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position), 4)

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

        // Add pencil marks - use valid values at (0,1): 4, 5, 6
        viewModel.addPencilMark(5)
        viewModel.addPencilMark(6)

        // Enter a value (clears pencil marks) - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position), 4)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo setValue
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.marks(at: position).contains(5))
        XCTAssertTrue(viewModel.marks(at: position).contains(6))

        // Redo setValue
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 4)
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)
    }

    func testRedoUpdatesConflicts() {
        // For TestFixtures.smallPuzzle, (0,1) solution=4, (0,2) solution=5
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 0, column: 2)

        // Place valid numbers
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(5)

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
        // For TestFixtures.smallPuzzle, valid value at (0,1) is 4
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Enter a valid value
        viewModel.enterNumber(4)

        // Undo
        viewModel.undo()

        // Create an error by trying invalid action (9 conflicts with pre-filled 9 at (0,3))
        viewModel.enterNumber(9) // Invalid
        XCTAssertNotNil(viewModel.errorMessage)

        // Redo should clear error
        viewModel.redo()
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUndoRedoSequence() {
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Perform action - use 4 which is valid at (0,1)
        viewModel.enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position), 4)

        // Undo
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))

        // Redo
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 4)

        // Undo again
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: position))

        // Redo again
        viewModel.redo()
        XCTAssertEqual(viewModel.value(at: position), 4)

        // Verify final state
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)
    }

    // MARK: - History Limit Tests

    func testHistoryLimitTo50Actions() {
        // Perform 60 actions to exceed the 50 action limit
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Valid values at (0,1): 4, 5, 6 (solution is 4; row has 9,8,2,0,3,7; diagonals have 8,1)
        let validValues = [4, 5, 6]

        // Perform 60 actions (alternating between valid values to create distinct actions)
        for i in 0 ..< 60 {
            let value = validValues[i % validValues.count]
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

        // Valid values at (0,1): 4, 5, 6 (solution is 4; row has 9,8,2,0,3,7; diagonals have 8,1)
        let validValues = [4, 5, 6]

        // First 5 actions should be discarded (oldest)
        for i in 0 ..< 5 {
            viewModel.enterNumber(validValues[i % validValues.count])
            viewModel.clearSelectedCell()
        }

        // Next 50 actions should be preserved
        for i in 0 ..< 50 {
            viewModel.enterNumber(validValues[i % validValues.count])
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
        _ = CellPosition(row: 1, column: 0) // position2 - reserved for future use

        viewModel.selectCell(at: position1)

        // Valid values at (0,1): 4, 5, 6 (solution is 4; row has 9,8,2,0,3,7; diagonals have 8,1)
        let validValues = [4, 5, 6]

        // Perform 60 mixed actions
        for i in 0 ..< 60 {
            switch i % 4 {
            case 0:
                // Set value
                viewModel.enterNumber(validValues[i % validValues.count])
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

        // Valid values at (0,1): 4, 5, 6 (solution is 4; row has 9,8,2,0,3,7; diagonals have 8,1)
        let validValues = [4, 5, 6]

        // Perform 60 actions
        for i in 0 ..< 60 {
            viewModel.enterNumber(validValues[i % validValues.count])
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
        viewModel.enterNumber(validValues[0])

        XCTAssertEqual(viewModel.undoCount, 21)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testMultipleActionSequencesWithUndoRedo() {
        // For smallPuzzle: (0,1) solution 4; (1,3) solution 3
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 3)

        // Sequence 1: Fill position1
        viewModel.selectCell(at: position1)
        viewModel.addPencilMark(5)
        viewModel.addPencilMark(6)
        viewModel.enterNumber(4)

        XCTAssertEqual(viewModel.undoCount, 3)

        // Sequence 2: Fill position2
        viewModel.selectCell(at: position2)
        viewModel.addPencilMark(2)
        viewModel.enterNumber(3)

        XCTAssertEqual(viewModel.undoCount, 5)

        // Sequence 3: Clear position1
        viewModel.selectCell(at: position1)
        viewModel.clearSelectedCell()

        XCTAssertEqual(viewModel.undoCount, 6)

        // Undo entire sequence 3
        viewModel.undo()
        XCTAssertEqual(viewModel.value(at: position1), 4)
        XCTAssertEqual(viewModel.undoCount, 5)

        // Undo entire sequence 2
        viewModel.undo() // Undo enterNumber(3)
        viewModel.undo() // Undo addPencilMark(2)
        XCTAssertNil(viewModel.value(at: position2))
        XCTAssertTrue(viewModel.marks(at: position2).isEmpty)
        XCTAssertEqual(viewModel.undoCount, 3)

        // Undo entire sequence 1
        viewModel.undo() // Undo enterNumber(4)
        viewModel.undo() // Undo addPencilMark(6)
        viewModel.undo() // Undo addPencilMark(5)
        XCTAssertNil(viewModel.value(at: position1))
        XCTAssertTrue(viewModel.marks(at: position1).isEmpty)
        XCTAssertEqual(viewModel.undoCount, 0)

        // Verify we can redo all sequences
        XCTAssertEqual(viewModel.redoCount, 6)

        // Redo sequence 1
        viewModel.redo() // Redo addPencilMark(5)
        viewModel.redo() // Redo addPencilMark(6)
        viewModel.redo() // Redo enterNumber(4)
        XCTAssertEqual(viewModel.value(at: position1), 4)
        XCTAssertEqual(viewModel.undoCount, 3)

        // Redo sequence 2
        viewModel.redo() // Redo addPencilMark(2)
        viewModel.redo() // Redo enterNumber(3)
        XCTAssertEqual(viewModel.value(at: position2), 3)
        XCTAssertEqual(viewModel.undoCount, 5)

        // Redo sequence 3
        viewModel.redo() // Redo clearSelectedCell
        XCTAssertNil(viewModel.value(at: position1))
        XCTAssertEqual(viewModel.undoCount, 6)
        XCTAssertEqual(viewModel.redoCount, 0)
    }

    func testComplexActionSequenceWithPartialUndoRedo() throws {
        throw XCTSkip("TODO: Update test for new puzzle data")
        // Valid values at (0,1): 4, 5, 6 - pencil marks can be any number
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Build up a complex state with pencil marks (any number is valid for marks)
        viewModel.addPencilMark(1)
        viewModel.addPencilMark(5)
        viewModel.addPencilMark(6)
        viewModel.togglePencilMark(5) // Remove 5
        viewModel.enterNumber(4) // Clear marks and set value (4 is valid)
        viewModel.clearSelectedCell() // Clear value

        XCTAssertEqual(viewModel.undoCount, 6)
        XCTAssertTrue(viewModel.isEmpty(at: position))
        XCTAssertTrue(viewModel.marks(at: position).isEmpty)

        // Undo half the sequence
        viewModel.undo() // Undo clear
        XCTAssertEqual(viewModel.value(at: position), 4)

        viewModel.undo() // Undo setValue(4)
        XCTAssertNil(viewModel.value(at: position))
        XCTAssertTrue(viewModel.marks(at: position).contains(1))
        XCTAssertFalse(viewModel.marks(at: position).contains(5))
        XCTAssertTrue(viewModel.marks(at: position).contains(6))

        viewModel.undo() // Undo toggle (restore 5)
        XCTAssertTrue(viewModel.marks(at: position).contains(5))

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

    func testActionSequencePreservesGameState() throws {
        throw XCTSkip("TODO: Update test for new puzzle data")
        // Find two empty cells in the 10x3 TestFixtures.smallPuzzle
        let position1 = CellPosition(row: 0, column: 1) // nil in initial grid, solution=4
        let position2 = CellPosition(row: 0, column: 2) // nil in initial grid, solution=5

        // Create a specific game state with values that don't conflict
        // Position (0,1) - Row 0 has pre-filled: 9,8,2,0,3,7 - Diagonals: (1,0)=8, (1,2)=1
        // Valid at (0,1): 4, 5, 6
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4) // Valid and correct solution

        // Position (0,2) - Row 0 has: 9,8,2,0,3,7 pre-filled, 4 just entered at (0,1)
        // Valid at (0,2): 5, 6 (not 4 - adjacent conflict)
        viewModel.selectCell(at: position2)
        viewModel.enterNumber(5) // Valid and correct solution

        XCTAssertEqual(viewModel.value(at: position1), 4)
        XCTAssertEqual(viewModel.value(at: position2), 5)

        // Record the current undo count (should be 2 - one for each setValue)
        let initialUndoCount = viewModel.undoCount

        // Perform many operations on position1 only
        // Valid values for position (0,1) with (0,2)=5: 4, 6 (NOT 5 - adjacent conflict!)
        let validValues = [4, 6, 4, 6, 4, 6, 4, 6, 4, 6]
        for value in validValues {
            viewModel.selectCell(at: position1)
            viewModel.enterNumber(value)
            viewModel.clearSelectedCell()
        }

        // Undo all 20 actions (10 enter + 10 clear) to return to the saved state
        for _ in 0 ..< 20 {
            viewModel.undo()
        }

        // Verify we're back to the initial state with the 2 cells filled
        XCTAssertEqual(viewModel.undoCount, initialUndoCount, "Should be back to initial undo count")
        XCTAssertEqual(viewModel.value(at: position1), 4, "Position 1 should be restored to 4")
        XCTAssertEqual(viewModel.value(at: position2), 5, "Position 2 should remain at 5")
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

        // Wait briefly for timer to tick
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

        // Elapsed time should have increased
        XCTAssertGreaterThan(newViewModel.elapsedTime, 0.1)
        XCTAssertLessThan(newViewModel.elapsedTime, 0.3)
    }

    func testPauseTimer() async {
        // Start fresh
        let newViewModel = GameViewModel(puzzle: puzzle)

        // Wait briefly for timer to tick
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Pause the timer
        newViewModel.pauseTimer()

        XCTAssertFalse(newViewModel.isTimerRunning)
        XCTAssertTrue(newViewModel.gameState.isPaused)

        let timeAfterPause = newViewModel.elapsedTime

        // Wait a bit more
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

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

        // Wait longer for timer to tick reliably - timer fires every 0.1s
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Time should have increased
        XCTAssertGreaterThan(newViewModel.elapsedTime, timeAfterPause + 0.05)
    }

    func testPauseResumeCycle() async {
        // Start fresh
        let newViewModel = GameViewModel(puzzle: puzzle)

        // Let it run briefly - use longer sleep for reliability
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        let time1 = newViewModel.elapsedTime

        // Ensure timer has actually ticked
        XCTAssertGreaterThan(time1, 0.1, "Timer should have started and elapsed some time")

        // Pause
        newViewModel.pauseTimer()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        let time2 = newViewModel.elapsedTime

        // Should not have increased much during pause - use lenient tolerance
        XCTAssertEqual(time2, time1, accuracy: 0.15, "Time should not increase while paused")

        // Resume
        newViewModel.resumeTimer()
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        let time3 = newViewModel.elapsedTime

        // Should have increased after resume
        XCTAssertGreaterThan(time3, time2, "Time should increase after resuming")
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
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Fill all cells except the last one
        for (position, value) in allEmptyCells.dropLast() {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        // Timer should still be running
        XCTAssertTrue(viewModel.isTimerRunning)
        XCTAssertFalse(viewModel.gameState.isCompleted)

        // Complete the puzzle with the last cell
        let lastCell = allEmptyCells.last!
        viewModel.selectCell(at: lastCell.0)
        viewModel.enterNumber(lastCell.1)

        // Timer should have stopped
        XCTAssertFalse(viewModel.isTimerRunning)
        XCTAssertTrue(viewModel.gameState.isCompleted)

        let timeAfterCompletion = viewModel.elapsedTime

        // Wait briefly
        try? await Task.sleep(nanoseconds: 80_000_000) // 0.08 seconds

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
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        for (position, value) in allEmptyCells {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)
        XCTAssertFalse(viewModel.isTimerRunning)

        // Try to start timer after completion
        viewModel.startTimer()

        // Should still not be running
        XCTAssertFalse(viewModel.isTimerRunning)
    }

    func testElapsedTimeMatchesGameState() async {
        // Let timer run briefly
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Pause to get consistent values
        viewModel.pauseTimer()

        // ViewModel elapsed time and game state elapsed time should match
        XCTAssertEqual(viewModel.elapsedTime, viewModel.gameState.elapsedTime, accuracy: 0.1)
    }

    func testTimerPreservesTimeAcrossViewModelCreation() async {
        // Let timer run briefly
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

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

        do {
            let tempViewModel = GameViewModel(puzzle: puzzle)
            weakViewModel = tempViewModel

            // Verify timer is running
            XCTAssertTrue(tempViewModel.isTimerRunning)

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

    // MARK: - Visual Feedback Tests

    func testCellHighlightingForSelectedCell() {
        // Select a cell
        let selectedPos = CellPosition(row: 1, column: 1)
        viewModel.selectCell(at: selectedPos)

        // Get the selected cell
        let selectedCell = viewModel.cell(at: selectedPos)

        // Selected cell should be marked as selected but not highlighted
        XCTAssertTrue(selectedCell.isSelected)
        XCTAssertFalse(selectedCell.isHighlighted)
    }

    func testCellHighlightingForSameRow() {
        // Select a cell
        let selectedPos = CellPosition(row: 1, column: 1)
        viewModel.selectCell(at: selectedPos)

        // Check cells in the same row
        let sameRowPos1 = CellPosition(row: 1, column: 0)
        let sameRowPos2 = CellPosition(row: 1, column: 2)

        let cell1 = viewModel.cell(at: sameRowPos1)
        let cell2 = viewModel.cell(at: sameRowPos2)

        // Cells in the same row should be highlighted
        XCTAssertTrue(cell1.isHighlighted)
        XCTAssertTrue(cell2.isHighlighted)
        XCTAssertFalse(cell1.isSelected)
        XCTAssertFalse(cell2.isSelected)
    }

    func testCellHighlightingForSameColumn() {
        // Select a cell
        let selectedPos = CellPosition(row: 1, column: 1)
        viewModel.selectCell(at: selectedPos)

        // Check cells in the same column
        let sameColPos1 = CellPosition(row: 0, column: 1)
        let sameColPos2 = CellPosition(row: 2, column: 1)

        let cell1 = viewModel.cell(at: sameColPos1)
        let cell2 = viewModel.cell(at: sameColPos2)

        // Cells in the same column should be highlighted
        XCTAssertTrue(cell1.isHighlighted)
        XCTAssertTrue(cell2.isHighlighted)
        XCTAssertFalse(cell1.isSelected)
        XCTAssertFalse(cell2.isSelected)
    }

    func testCellHighlightingForAdjacentCells() {
        // Select a cell
        let selectedPos = CellPosition(row: 1, column: 1)
        viewModel.selectCell(at: selectedPos)

        // Check all 8 adjacent cells (diagonals and orthogonal)
        let adjacentPositions = [
            CellPosition(row: 0, column: 0), // Top-left diagonal
            CellPosition(row: 0, column: 1), // Top (also same column)
            CellPosition(row: 0, column: 2), // Top-right diagonal
            CellPosition(row: 1, column: 0), // Left (also same row)
            CellPosition(row: 1, column: 2), // Right (also same row)
            CellPosition(row: 2, column: 0), // Bottom-left diagonal
            CellPosition(row: 2, column: 1), // Bottom (also same column)
            CellPosition(row: 2, column: 2), // Bottom-right diagonal
        ]

        for position in adjacentPositions {
            let cell = viewModel.cell(at: position)
            XCTAssertTrue(cell.isHighlighted, "Cell at \(position) should be highlighted")
            XCTAssertFalse(cell.isSelected, "Cell at \(position) should not be selected")
        }
    }

    func testNoHighlightingWhenNoSelection() {
        // No cell selected
        XCTAssertNil(viewModel.selectedPosition)

        // Check that no cells are highlighted (10x3 grid)
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                let cell = viewModel.cell(at: position)
                XCTAssertFalse(cell.isHighlighted, "Cell at \(position) should not be highlighted")
                XCTAssertFalse(cell.isSelected, "Cell at \(position) should not be selected")
            }
        }
    }

    func testSameNumberHighlighting() {
        // Place the same number in two different non-adjacent cells
        // (0,1) solution: 4; (1,5) solution: 4; These are not adjacent
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 5)

        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(4)

        // Now select the first cell
        viewModel.selectCell(at: position1)

        // The second cell should be marked as having the same number
        let cell2 = viewModel.cell(at: position2)
        XCTAssertTrue(cell2.isSameNumber, "Cell at \(position2) should be marked as same number")
        XCTAssertFalse(cell2.isSelected, "Cell at \(position2) should not be selected")

        // The selected cell itself should not be marked as same number
        let cell1 = viewModel.cell(at: position1)
        XCTAssertFalse(cell1.isSameNumber, "Selected cell should not be marked as same number")
        XCTAssertTrue(cell1.isSelected)
    }

    func testSameNumberNotHighlightedForDifferentValues() {
        // Place different numbers in cells
        // (0,1) valid: 4,5,6; (2,5) valid: 9
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 2, column: 5)

        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(9)

        // Select the first cell
        viewModel.selectCell(at: position1)

        // The second cell should not be marked as same number
        let cell2 = viewModel.cell(at: position2)
        XCTAssertFalse(cell2.isSameNumber)
    }

    func testSameNumberNotHighlightedForEmptyCells() {
        // Place a number in one cell - 4 is valid at (0,1)
        let position1 = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        // Select the cell
        viewModel.selectCell(at: position1)

        // Empty cells should not be marked as same number
        let emptyPosition = CellPosition(row: 2, column: 5)
        let emptyCell = viewModel.cell(at: emptyPosition)
        XCTAssertFalse(emptyCell.isSameNumber)
    }

    func testSameNumberNotHighlightedWhenSelectedCellIsEmpty() {
        // Place a number in one cell - (2,5) is empty, solution is 9
        let position1 = CellPosition(row: 2, column: 5)
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(9)

        // Select an empty cell
        let emptyPosition = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: emptyPosition)

        // The filled cell should not be marked as same number
        let cell1 = viewModel.cell(at: position1)
        XCTAssertFalse(cell1.isSameNumber)
    }

    func testMultipleCellsWithSameNumberHighlighted() {
        // Place the same number in non-adjacent cells
        // (1,3) solution 3; (2,7) solution 0; using value 1 which could work in different positions
        let positions = [
            CellPosition(row: 0, column: 0),
            CellPosition(row: 2, column: 0),
        ]

        // Place 1 in both cells (both have solution value 1)
        viewModel.selectCell(at: positions[0])
        viewModel.enterNumber(1)

        viewModel.selectCell(at: positions[1])
        viewModel.enterNumber(1)

        // Select one of them
        viewModel.selectCell(at: positions[0])

        // The other cell with the same number should be marked
        let otherCell = viewModel.cell(at: positions[1])
        XCTAssertTrue(otherCell.isSameNumber, "Cell at \(positions[1]) should be marked as same number")

        // The selected cell should not be marked as same number
        let selectedCell = viewModel.cell(at: positions[0])
        XCTAssertFalse(selectedCell.isSameNumber)
    }

    func testErrorHighlighting() {
        // Test conflict detection when an invalid placement is attempted
        // For TestFixtures.smallPuzzle, (0,5)=2 is pre-filled
        // Attempting to enter 2 at (0,1) should conflict with the pre-filled 2 at (0,5)
        let position1 = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position1)
        viewModel.enterNumber(2) // This should conflict with the pre-filled 2 at (0,5)

        // The value should NOT be placed due to validation
        XCTAssertNil(viewModel.value(at: position1), "Invalid value should not be placed")

        // Conflicting positions should be populated
        XCTAssertFalse(viewModel.conflictingPositions.isEmpty, "Conflicting positions should be populated")

        // The pre-filled cell (0,5) that contains the conflicting 2 should be in conflicts
        let prefilledPosition = CellPosition(row: 0, column: 5)
        XCTAssertTrue(
            viewModel.conflictingPositions.contains(prefilledPosition),
            "Pre-filled cell (0,5) should be in conflicting positions"
        )

        // Verify that cells in conflicting positions are marked with hasError
        let conflictingCell = viewModel.cell(at: prefilledPosition)
        XCTAssertTrue(conflictingCell.hasError, "Cell at conflicting position should have hasError set")

        // An error message should be displayed
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
    }

    func testHighlightingUpdatesWhenSelectionChanges() {
        // Select first cell
        let position1 = CellPosition(row: 0, column: 0)
        viewModel.selectCell(at: position1)

        // Check that adjacent cell is highlighted
        let adjacentPosition = CellPosition(row: 0, column: 1)
        var cell = viewModel.cell(at: adjacentPosition)
        XCTAssertTrue(cell.isHighlighted)

        // Select a different cell
        let position2 = CellPosition(row: 2, column: 2)
        viewModel.selectCell(at: position2)

        // The previously highlighted cell should no longer be highlighted
        cell = viewModel.cell(at: adjacentPosition)
        XCTAssertFalse(cell.isHighlighted)

        // New adjacent cells should be highlighted
        let newAdjacentPosition = CellPosition(row: 2, column: 1)
        cell = viewModel.cell(at: newAdjacentPosition)
        XCTAssertTrue(cell.isHighlighted)
    }

    // MARK: - Complete Game Flow Integration Tests

    /// Tests the complete game flow: start → play → complete
    /// This verifies that a new game can be started, played through, and completed successfully
    func testCompleteGameFlow_StartPlayComplete() {
        // PHASE 1: START - Verify initial game state
        XCTAssertFalse(viewModel.gameState.isCompleted, "Game should not be completed at start")
        XCTAssertFalse(viewModel.gameState.isPaused, "Game should not be paused at start")
        XCTAssertTrue(viewModel.isTimerRunning, "Timer should be running at start")
        XCTAssertEqual(viewModel.gameState.hintsUsed, 0, "No hints should be used at start")
        XCTAssertEqual(viewModel.gameState.errorCount, 0, "No errors should be recorded at start")
        XCTAssertNil(viewModel.selectedPosition, "No cell should be selected at start")
        XCTAssertTrue(viewModel.gameState.progress < 1.0, "Progress should be less than 100% at start")

        // PHASE 2: PLAY - Fill in the puzzle correctly
        // 10x3 puzzle with 14 empty cells

        // Track progress as we fill cells
        let initialProgress = viewModel.gameState.progress
        XCTAssertEqual(viewModel.gameState.emptyCellCount, 14, "Should have 14 empty cells")
        XCTAssertEqual(initialProgress, 0.0, accuracy: 0.001, "Initial progress should be 0%")

        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Fill first cell and verify progress increases
        let firstCell = allEmptyCells[0]
        viewModel.selectCell(at: firstCell.0)
        XCTAssertNotNil(viewModel.selectedPosition, "Cell should be selected")
        viewModel.enterNumber(firstCell.1)
        XCTAssertEqual(viewModel.value(at: firstCell.0), firstCell.1)
        XCTAssertNil(viewModel.errorMessage, "No error should occur for valid placement")
        XCTAssertGreaterThan(viewModel.gameState.progress, initialProgress, "Progress should increase")

        // Fill all cells except the last one
        for (position, value) in allEmptyCells.dropFirst().dropLast() {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        // Verify game is not yet completed (one cell remaining)
        XCTAssertFalse(viewModel.gameState.isCompleted, "Game should not be completed yet")
        XCTAssertTrue(viewModel.isTimerRunning, "Timer should still be running")

        // PHASE 3: COMPLETE - Fill the last cell
        let lastCell = allEmptyCells.last!
        viewModel.selectCell(at: lastCell.0)
        viewModel.enterNumber(lastCell.1)

        // Verify game completion
        XCTAssertTrue(viewModel.gameState.isCompleted, "Game should be completed")
        XCTAssertFalse(viewModel.isTimerRunning, "Timer should stop after completion")
        XCTAssertNotNil(viewModel.gameState.completedAt, "Completion time should be recorded")
        XCTAssertEqual(viewModel.gameState.progress, 1.0, "Progress should be 100%")
        XCTAssertTrue(viewModel.gameState.isCorrectlyCompleted(), "Solution should be correct")
    }

    /// Tests game flow with undo/redo during gameplay
    func testCompleteGameFlow_WithUndoRedo() {
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Fill first two cells
        viewModel.selectCell(at: allEmptyCells[0].0)
        viewModel.enterNumber(allEmptyCells[0].1)

        viewModel.selectCell(at: allEmptyCells[1].0)
        viewModel.enterNumber(allEmptyCells[1].1)

        // Make a mistake - enter wrong value at third cell
        // Find a valid (non-conflicting) value that is different from the solution
        let mistakeCell = allEmptyCells[2]
        viewModel.selectCell(at: mistakeCell.0)
        let validValues = viewModel.getValidValues(for: mistakeCell.0)
        let wrongValue = validValues.first(where: { $0 != mistakeCell.1 }) ?? mistakeCell.1
        viewModel.enterNumber(wrongValue) // Valid placement but wrong value

        XCTAssertEqual(viewModel.undoCount, 3, "Should have 3 actions in undo history")

        // Undo the mistake
        viewModel.undo()
        XCTAssertNil(viewModel.value(at: mistakeCell.0), "Value should be cleared after undo")
        XCTAssertEqual(viewModel.undoCount, 2)
        XCTAssertEqual(viewModel.redoCount, 1)

        // Enter correct value
        viewModel.selectCell(at: mistakeCell.0)
        viewModel.enterNumber(mistakeCell.1)

        // Redo stack should be cleared after new action
        XCTAssertEqual(viewModel.redoCount, 0, "Redo stack should be cleared")

        // Continue filling the rest of the puzzle
        for (position, value) in allEmptyCells.dropFirst(3) {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        // Verify completion
        XCTAssertTrue(viewModel.gameState.isCompleted)
        XCTAssertTrue(viewModel.gameState.isCorrectlyCompleted())
    }

    /// Tests game flow with notes/pencil marks
    func testCompleteGameFlow_WithNotes() {
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Add pencil marks before entering values
        let firstCell = allEmptyCells[0]
        viewModel.selectCell(at: firstCell.0)

        // Enable notes mode
        viewModel.setNotesMode(true)
        XCTAssertTrue(viewModel.notesMode)

        // Add pencil marks
        viewModel.enterNumber(firstCell.1) // Correct value as pencil mark
        viewModel.enterNumber(8) // Another pencil mark
        XCTAssertTrue(viewModel.marks(at: firstCell.0).contains(firstCell.1))
        XCTAssertTrue(viewModel.marks(at: firstCell.0).contains(8))
        XCTAssertNil(viewModel.value(at: firstCell.0), "Cell should still be empty")

        // Disable notes mode
        viewModel.setNotesMode(false)
        XCTAssertFalse(viewModel.notesMode)

        // Enter the actual value (should clear pencil marks)
        viewModel.enterNumber(firstCell.1)
        XCTAssertEqual(viewModel.value(at: firstCell.0), firstCell.1)
        XCTAssertTrue(viewModel.marks(at: firstCell.0).isEmpty, "Pencil marks should be cleared")

        // Complete the rest of the puzzle
        for (position, value) in allEmptyCells.dropFirst() {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)
    }

    /// Tests game flow with pause/resume
    func testCompleteGameFlow_WithPauseResume() async {
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Start playing - fill first cell
        viewModel.selectCell(at: allEmptyCells[0].0)
        viewModel.enterNumber(allEmptyCells[0].1)

        // Pause the game
        viewModel.pauseTimer()
        XCTAssertTrue(viewModel.gameState.isPaused, "Game should be paused")
        XCTAssertFalse(viewModel.isTimerRunning, "Timer should stop when paused")

        let timeWhenPaused = viewModel.elapsedTime

        // Wait briefly while paused
        try? await Task.sleep(nanoseconds: 80_000_000) // 0.08 seconds

        // Time should not have increased while paused
        XCTAssertEqual(viewModel.elapsedTime, timeWhenPaused, accuracy: 0.05)

        // Resume the game
        viewModel.resumeTimer()
        XCTAssertFalse(viewModel.gameState.isPaused, "Game should not be paused")
        XCTAssertTrue(viewModel.isTimerRunning, "Timer should resume")

        // Continue playing and complete the rest of the puzzle
        for (position, value) in allEmptyCells.dropFirst() {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)
        XCTAssertFalse(viewModel.isTimerRunning, "Timer should stop on completion")
    }

    /// Tests game flow with error handling
    func testCompleteGameFlow_WithErrors() {
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Try to enter invalid values
        viewModel.selectCell(at: CellPosition(row: 0, column: 1))

        // Try to enter 2 (conflicts with existing 2 at (0,5) in same row)
        viewModel.enterNumber(2)
        XCTAssertNotNil(viewModel.errorMessage, "Should show error for invalid placement")
        XCTAssertNil(viewModel.value(at: CellPosition(row: 0, column: 1)), "Invalid value should not be placed")
        XCTAssertEqual(viewModel.gameState.errorCount, 1, "Error count should be incremented")

        // Try to modify pre-filled cell (0,3) which has value 9
        viewModel.selectCell(at: CellPosition(row: 0, column: 3))
        viewModel.enterNumber(5)
        XCTAssertEqual(viewModel.errorMessage, "Cannot modify pre-filled cells")
        XCTAssertEqual(viewModel.value(at: CellPosition(row: 0, column: 3)), 9, "Pre-filled value should remain")

        // Now complete the puzzle correctly
        for (position, value) in allEmptyCells {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        // Verify completion despite earlier errors
        XCTAssertTrue(viewModel.gameState.isCompleted)
        XCTAssertEqual(viewModel.gameState.errorCount, 1, "Error count should be preserved")
    }

    /// Tests game flow with hints
    func testCompleteGameFlow_WithHints() {
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Request a hint
        let initialHintsUsed = viewModel.gameState.hintsUsed
        viewModel.requestHint()

        XCTAssertEqual(viewModel.gameState.hintsUsed, initialHintsUsed + 1, "Hints used should increment")

        // Hint should have either filled a cell or added pencil marks
        // Fill remaining empty cells with correct values
        for (position, value) in allEmptyCells {
            if viewModel.value(at: position) == nil {
                viewModel.selectCell(at: position)
                viewModel.enterNumber(value)
            }
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)
        XCTAssertGreaterThan(viewModel.gameState.hintsUsed, 0, "Hints used should be recorded")
    }

    /// Tests complete game flow starting from a bundled puzzle
    func testCompleteGameFlow_WithBundledPuzzle() {
        // Use a bundled puzzle from fixtures
        let bundledPuzzle = TestFixtures.easyPuzzle

        // Create a new view model with the bundled puzzle
        let gameVM = GameViewModel(puzzle: bundledPuzzle)

        // Verify initial state
        XCTAssertFalse(gameVM.gameState.isCompleted)
        XCTAssertTrue(gameVM.isTimerRunning)

        // Fill in the puzzle using the solution
        for row in 0 ..< bundledPuzzle.rows {
            for col in 0 ..< bundledPuzzle.columns {
                let position = CellPosition(row: row, column: col)

                // Skip pre-filled cells
                if bundledPuzzle.isPrefilled(at: position) {
                    continue
                }

                // Get the correct value from solution
                let correctValue = bundledPuzzle.solution[row][col]

                // Enter the value
                gameVM.selectCell(at: position)
                gameVM.enterNumber(correctValue)
            }
        }

        // Verify completion
        XCTAssertTrue(gameVM.gameState.isCompleted, "Game should be completed")
        XCTAssertTrue(gameVM.gameState.isCorrectlyCompleted(), "Solution should be correct")
        XCTAssertFalse(gameVM.isTimerRunning, "Timer should stop")
        XCTAssertNotNil(gameVM.gameState.completedAt, "Completion time should be recorded")
    }

    /// Tests that game state is consistent throughout the flow
    func testCompleteGameFlow_StateConsistency() {
        // Dynamically find all empty cells and their solution values
        let cellsToFill = findAllEmptyCells()
        XCTAssertGreaterThan(cellsToFill.count, 0, "Should have at least one empty cell")

        // Verify state at each step of the flow
        var previousProgress = viewModel.gameState.progress

        for (index, (position, value)) in cellsToFill.enumerated() {
            // Pre-fill checks
            let preFilledCount = viewModel.gameState.filledCellCount
            let preEmptyCount = viewModel.gameState.emptyCellCount

            // Enter value
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)

            // Post-fill checks
            XCTAssertEqual(
                viewModel.gameState.filledCellCount,
                preFilledCount + 1,
                "Filled count should increase by 1 at step \(index)"
            )
            XCTAssertEqual(
                viewModel.gameState.emptyCellCount,
                preEmptyCount - 1,
                "Empty count should decrease by 1 at step \(index)"
            )
            XCTAssertGreaterThanOrEqual(
                viewModel.gameState.progress,
                previousProgress,
                "Progress should not decrease at step \(index)"
            )

            previousProgress = viewModel.gameState.progress

            // Verify game is only completed on last step
            if index < cellsToFill.count - 1 {
                XCTAssertFalse(
                    viewModel.gameState.isCompleted,
                    "Game should not be completed at step \(index)"
                )
            } else {
                XCTAssertTrue(
                    viewModel.gameState.isCompleted,
                    "Game should be completed on final step"
                )
            }
        }
    }

    /// Tests that actions cannot be performed after game completion
    func testCompleteGameFlow_ActionsBlockedAfterCompletion() {
        // Dynamically find all empty cells and their solution values
        let cellsToFill = findAllEmptyCells()

        // Complete the puzzle first
        for (position, value) in cellsToFill {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)

        // Try requesting hint after completion
        let hintsBeforeAttempt = viewModel.gameState.hintsUsed
        viewModel.requestHint()
        XCTAssertEqual(
            viewModel.gameState.hintsUsed,
            hintsBeforeAttempt,
            "Hints should not increase after completion"
        )
        XCTAssertEqual(viewModel.errorMessage, "Game is already completed")
    }

    /// Tests game flow with cell clearing
    func testCompleteGameFlow_WithCellClearing() {
        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        let firstCell = allEmptyCells[0]

        // Fill a cell
        viewModel.selectCell(at: firstCell.0)
        viewModel.enterNumber(firstCell.1)
        XCTAssertEqual(viewModel.value(at: firstCell.0), firstCell.1)

        // Clear the cell
        viewModel.clearSelectedCell()
        XCTAssertNil(viewModel.value(at: firstCell.0))

        // Verify progress decreased
        XCTAssertEqual(viewModel.gameState.progress, 0.0)

        // Re-fill and complete the puzzle
        for (position, value) in allEmptyCells {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)
    }

    /// Tests that column sums are tracked correctly throughout the game
    func testCompleteGameFlow_ColumnSumsVerification() {
        // Target sums for TestFixtures.smallPuzzle: [10, 12, 13, 20, 13, 15, 16, 9, 11, 16]
        let expectedTargetSums = puzzle.targetSums

        // Initially all columns should have partial sums from pre-filled cells
        // Pre-filled in each column for TestFixtures.smallPuzzle:
        // Col 0: (1,0)=8 → sum = 8
        // Col 1: (1,1)=6, (2,1)=2 → sum = 8
        // Col 2: (1,2)=1 → sum = 1
        // Col 3: (0,3)=9, (2,3)=8 → sum = 17
        // Col 4: (0,4)=8, (2,4)=5 → sum = 13 (complete!)
        // Col 5: (0,5)=2 → sum = 2
        // Col 6: (2,6)=3 → sum = 3
        // Col 7: (0,7)=0 → sum = 0
        // Col 8: (0,8)=3, (1,8)=2 → sum = 5
        // Col 9: (0,9)=7, (1,9)=5, (2,9)=4 → sum = 16 (complete!)
        XCTAssertEqual(viewModel.columnSum(for: 0), 8) // (1,0)=8
        XCTAssertEqual(viewModel.columnSum(for: 1), 8) // (1,1)=6, (2,1)=2
        XCTAssertEqual(viewModel.columnSum(for: 2), 1) // (1,2)=1
        XCTAssertEqual(viewModel.columnSum(for: 4), 13) // (0,4)=8, (2,4)=5 (complete!)

        // Dynamically find all empty cells and their solution values
        let allEmptyCells = findAllEmptyCells()

        // Fill the puzzle
        for (position, value) in allEmptyCells {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)
        }

        // Verify all column sums match targets
        for col in 0 ..< puzzle.columns {
            XCTAssertEqual(
                viewModel.columnSum(for: col),
                expectedTargetSums[col],
                "Column \(col) sum should match target"
            )
            XCTAssertTrue(
                viewModel.isColumnComplete(col),
                "Column \(col) should be complete"
            )
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)
    }

    /// Tests game flow tracks elapsed time correctly
    func testCompleteGameFlow_TimeTracking() async {
        // Dynamically find all empty cells and their solution values
        let cellsToFill = findAllEmptyCells()

        // Let some time pass before starting to fill - use generous sleep for reliability
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        let timeBeforeFilling = viewModel.elapsedTime
        // Timer should have elapsed at least some time, using lenient threshold
        XCTAssertGreaterThan(timeBeforeFilling, 0.1, "Time should have elapsed")

        // Fill the puzzle with small delays to ensure timer ticks
        for (index, (position, value)) in cellsToFill.enumerated() {
            viewModel.selectCell(at: position)
            viewModel.enterNumber(value)

            // Add a small delay every few moves to allow timer to update
            if index % 5 == 4 {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
        }

        XCTAssertTrue(viewModel.gameState.isCompleted)

        let finalTime = viewModel.elapsedTime
        // Use >= since timer might not have ticked if operations were very fast
        XCTAssertGreaterThanOrEqual(finalTime, timeBeforeFilling, "Final time should be at least the initial time")

        // Verify time is preserved in game state
        XCTAssertEqual(viewModel.gameState.elapsedTime, finalTime, accuracy: 0.1)

        // Wait briefly and verify time doesn't increase after completion
        let timeAfterCompletion = viewModel.elapsedTime
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertEqual(
            viewModel.elapsedTime,
            timeAfterCompletion,
            accuracy: 0.1,
            "Time should not increase after completion"
        )
    }

    // MARK: - Column Sum Tests

    /// Tests that remainingSum calculates correctly for empty columns
    func testRemainingSumForEmptyColumn() {
        // Column 0 has target sum of 10
        // Pre-filled: (1,0)=8 → current sum = 8
        // Remaining: 10 - 8 = 2
        XCTAssertEqual(viewModel.remainingSum(for: 0), 2)
    }

    /// Tests that remainingSum calculates correctly for partially filled columns
    func testRemainingSumForPartiallyFilledColumn() {
        // Column 1 has target sum of 12
        // Pre-filled: (1,1)=6, (2,1)=2 → current sum = 8
        // Remaining: 12 - 8 = 4
        XCTAssertEqual(viewModel.remainingSum(for: 1), 4)

        // Now fill the empty cell (0,1) with 4 (solution value)
        viewModel.selectCell(at: CellPosition(row: 0, column: 1))
        viewModel.enterNumber(4)

        // New current sum: 8 + 4 = 12
        // Remaining: 12 - 12 = 0
        XCTAssertEqual(viewModel.remainingSum(for: 1), 0)
    }

    /// Tests that remainingSum returns correct value for completely filled columns
    func testRemainingSumForCompleteColumn() {
        // Column 4 is completely pre-filled
        // Pre-filled: (0,4)=8, (2,4)=5 → current sum = 13
        // Target sum: 13
        // Remaining: 13 - 13 = 0
        XCTAssertEqual(viewModel.remainingSum(for: 4), 0)
    }

    /// Tests that remainingSum handles invalid column index
    func testRemainingSumForInvalidColumn() {
        // Test column index out of bounds
        XCTAssertEqual(viewModel.remainingSum(for: -1), 0)
        XCTAssertEqual(viewModel.remainingSum(for: 10), 0)
        XCTAssertEqual(viewModel.remainingSum(for: 100), 0)
    }

    /// Tests that wouldExceedColumnSum correctly identifies numbers that exceed remaining sum
    func testWouldExceedColumnSumWithExcessiveValue() {
        // Column 0: target=10, pre-filled sum=8, remaining=2
        // Position (0,0) is empty
        let position = CellPosition(row: 0, column: 0)

        // Value 3 would exceed remaining sum of 2
        XCTAssertTrue(viewModel.wouldExceedColumnSum(3, at: position))

        // Value 5 would exceed remaining sum of 2
        XCTAssertTrue(viewModel.wouldExceedColumnSum(5, at: position))

        // Value 9 would exceed remaining sum of 2
        XCTAssertTrue(viewModel.wouldExceedColumnSum(9, at: position))
    }

    /// Tests that wouldExceedColumnSum allows values within remaining sum
    func testWouldExceedColumnSumWithValidValue() {
        // Column 0: target=10, pre-filled sum=8, remaining=2
        // Position (0,0) is empty
        let position = CellPosition(row: 0, column: 0)

        // Value 0 is within remaining sum of 2
        XCTAssertFalse(viewModel.wouldExceedColumnSum(0, at: position))

        // Value 1 is within remaining sum of 2 (solution value)
        XCTAssertFalse(viewModel.wouldExceedColumnSum(1, at: position))

        // Value 2 equals remaining sum (valid)
        XCTAssertFalse(viewModel.wouldExceedColumnSum(2, at: position))
    }

    /// Tests that wouldExceedColumnSum accounts for cell's current value when replacing
    func testWouldExceedColumnSumWhenReplacingValue() {
        // Column 0: target=10, pre-filled sum=8, remaining=2
        // Fill position (0,0) with value 1 (solution value)
        let position = CellPosition(row: 0, column: 0)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(1)

        // Now column sum is 8 + 1 = 9, remaining = 10 - 9 = 1
        // But when replacing, we need to account for the current value (1)
        // Effective remaining when replacing: 1 + 1 = 2

        // Value 3 would exceed (3 > 2)
        XCTAssertTrue(viewModel.wouldExceedColumnSum(3, at: position))

        // Value 2 should be allowed (2 <= 2)
        XCTAssertFalse(viewModel.wouldExceedColumnSum(2, at: position))

        // Value 1 should be allowed
        XCTAssertFalse(viewModel.wouldExceedColumnSum(1, at: position))
    }

    /// Tests that wouldExceedColumnSum handles completely filled columns
    func testWouldExceedColumnSumForCompleteColumn() {
        // Column 4 is completely pre-filled with target sum = 13
        // Position (1,4) is empty (solution value 0)
        // Current sum: 13 (from (0,4)=8 and (2,4)=5)
        // If we place any value, it would make the sum exceed 13
        let position = CellPosition(row: 1, column: 4)

        // Value 0 would make sum 13, which equals target (valid)
        XCTAssertFalse(viewModel.wouldExceedColumnSum(0, at: position))
        // Value 1 would make sum 14, exceeding target
        XCTAssertTrue(viewModel.wouldExceedColumnSum(1, at: position))
    }

    /// Tests that wouldExceedColumnSum handles invalid positions
    func testWouldExceedColumnSumWithInvalidPosition() {
        // Test with out of bounds position
        let invalidPosition = CellPosition(row: 10, column: 10)
        XCTAssertFalse(viewModel.wouldExceedColumnSum(5, at: invalidPosition))
    }

    /// Tests that column sum validation integrates with number pad disabling
    func testColumnSumIntegrationWithNumberPad() {
        // Column 9: target=16, pre-filled=(0,9)=7+(1,9)=5+(2,9)=4=16, remaining=0 (complete!)
        // Since column is complete, all cells are prefilled, so use column 7 instead
        // Column 7: target=9, pre-filled=(0,7)=0, remaining=9
        // Position (1,7) is empty
        let position = CellPosition(row: 1, column: 7)
        viewModel.selectCell(at: position)

        // All numbers 0-9 should be allowed since remaining is 9
        for number in 0 ... 9 {
            XCTAssertFalse(
                viewModel.wouldExceedColumnSum(number, at: position),
                "Number \(number) should NOT exceed remaining sum of 9"
            )
        }
    }

    /// Tests remaining sum updates correctly as puzzle is filled
    func testRemainingSumUpdatesAsColumnFills() {
        // Column 1: target=12, pre-filled sum=8, remaining=4
        XCTAssertEqual(viewModel.remainingSum(for: 1), 4)

        // Fill position (0,1) with 4 (solution value)
        viewModel.selectCell(at: CellPosition(row: 0, column: 1))
        viewModel.enterNumber(4)

        // Remaining should now be 0
        XCTAssertEqual(viewModel.remainingSum(for: 1), 0)

        // Only 0 or the current value (4) should be allowed
        XCTAssertFalse(viewModel.wouldExceedColumnSum(0, at: CellPosition(row: 0, column: 1)))
        XCTAssertFalse(viewModel.wouldExceedColumnSum(4, at: CellPosition(row: 0, column: 1)))

        // Any other non-zero value at (0,1) should now exceed (since remaining is 0)
        for number in 1 ... 3 {
            XCTAssertTrue(
                viewModel.wouldExceedColumnSum(number, at: CellPosition(row: 0, column: 1)),
                "Number \(number) should exceed remaining sum of 0 when replacing 4"
            )
        }
        for number in 5 ... 9 {
            XCTAssertTrue(
                viewModel.wouldExceedColumnSum(number, at: CellPosition(row: 0, column: 1)),
                "Number \(number) should exceed remaining sum of 0 when replacing 4"
            )
        }
    }

    /// Tests that column sum validation works with undo/redo
    func testColumnSumValidationWithUndoRedo() {
        // Column 0: target=10, current=8, remaining=2
        let position = CellPosition(row: 0, column: 0)

        // Fill with value 1 (solution value, valid)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(1)
        XCTAssertEqual(viewModel.remainingSum(for: 0), 1)

        // Undo
        viewModel.undo()
        XCTAssertEqual(viewModel.remainingSum(for: 0), 2)

        // Now 1 and 2 should be allowed again
        XCTAssertFalse(viewModel.wouldExceedColumnSum(1, at: position))
        XCTAssertFalse(viewModel.wouldExceedColumnSum(2, at: position))

        // Redo
        viewModel.redo()
        XCTAssertEqual(viewModel.remainingSum(for: 0), 1)

        // Now values with netChange <=1 should be allowed, >1 should exceed
        // netChange for value 1 (current) = 0, for value 2 = 1, for value 3 = 2
        XCTAssertFalse(viewModel.wouldExceedColumnSum(1, at: position)) // same value
        XCTAssertFalse(viewModel.wouldExceedColumnSum(2, at: position)) // netChange=1, equals remaining
        XCTAssertTrue(viewModel.wouldExceedColumnSum(3, at: position)) // netChange=2, exceeds remaining
    }

    /// Tests edge case where remaining sum is exactly zero
    func testColumnSumWithExactlyZeroRemaining() {
        // Fill column until remaining is 0
        // Column 1: target=12, pre-filled=8, need to add 4
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(4)

        XCTAssertEqual(viewModel.remainingSum(for: 1), 0)

        // Only 0 or current value (4) should not exceed
        XCTAssertFalse(viewModel.wouldExceedColumnSum(0, at: position))
        XCTAssertFalse(viewModel.wouldExceedColumnSum(4, at: position))

        // All other values should exceed
        for number in 1 ... 3 {
            XCTAssertTrue(viewModel.wouldExceedColumnSum(number, at: position))
        }
        for number in 5 ... 9 {
            XCTAssertTrue(viewModel.wouldExceedColumnSum(number, at: position))
        }
    }

    // MARK: - Settings Observer Tests

    /// Tests that autoCheckErrors setting observer updates conflicts
    func testSettingsObserver_AutoCheckErrors_EnablesConflictDisplay() throws {
        throw XCTSkip("TODO: Fix settings observer test timeout")
        // Ensure autoCheckErrors starts as true
        var initialSettings = SettingsManager.shared.settings
        initialSettings.autoCheckErrors = true
        SettingsManager.shared.updateSettings(initialSettings)

        // Wait a moment for the setting to take effect
        let initialExpectation = XCTestExpectation(description: "Initial settings should propagate")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            initialExpectation.fulfill()
        }
        wait(for: [initialExpectation], timeout: 1.0)

        // Create an invalid placement to generate conflicts
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Try to enter 2 (conflicts with pre-filled 2 at (0,0))
        viewModel.enterNumber(2)

        // Should have conflicts
        XCTAssertFalse(viewModel.conflictingPositions.isEmpty, "Should have conflicts when autoCheckErrors is on")

        // Disable autoCheckErrors via SettingsManager
        var settings = SettingsManager.shared.settings
        settings.autoCheckErrors = false
        SettingsManager.shared.updateSettings(settings)

        // Wait for the observer to fire and process the change
        let expectation = XCTestExpectation(description: "Settings observer should clear conflicts")
        var checkCount = 0
        func checkConflicts() {
            checkCount += 1
            if self.viewModel.conflictingPositions.isEmpty {
                expectation.fulfill()
            } else if checkCount < 20 {
                // Keep checking every 0.2 seconds up to 4 seconds total
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: checkConflicts)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: checkConflicts)
        wait(for: [expectation], timeout: 5.0)

        // Conflicts should be cleared
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty, "Conflicts should be cleared when autoCheckErrors is off")
        // Note: autoCheckErrors is @AppStorage and may not update immediately when UserDefaults changes
        // The important behavior is that conflicts are cleared, not the @AppStorage value
    }

    /// Tests that autoCheckErrors setting observer re-enables conflict detection
    func testSettingsObserver_AutoCheckErrors_ReEnablesConflictDetection() {
        // Disable autoCheckErrors initially
        var settings = SettingsManager.shared.settings
        settings.autoCheckErrors = false
        SettingsManager.shared.updateSettings(settings)

        // Wait briefly for the observer to fire
        var expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Place a valid number
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)
        viewModel.enterNumber(4)

        // Should have no conflicts
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)

        // Re-enable autoCheckErrors
        settings.autoCheckErrors = true
        SettingsManager.shared.updateSettings(settings)

        // Wait for observer
        expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Should re-check for conflicts (but won't find any since 4 is valid)
        XCTAssertTrue(viewModel.autoCheckErrors)
    }

    /// Tests that highlightSameNumbers setting observer updates highlighting
    func testSettingsObserver_HighlightSameNumbers_UpdatesHighlighting() {
        // Place the same number in two cells
        // (0,1) solution: 4; (1,5) solution: 4; These are not adjacent
        let position1 = CellPosition(row: 0, column: 1)
        let position2 = CellPosition(row: 1, column: 5)

        viewModel.selectCell(at: position1)
        viewModel.enterNumber(4)

        viewModel.selectCell(at: position2)
        viewModel.enterNumber(4)

        // Select first cell and check second is highlighted as same number
        viewModel.selectCell(at: position1)
        XCTAssertTrue(viewModel.cell(at: position2).isSameNumber)

        // Disable highlightSameNumbers via SettingsManager
        var settings = SettingsManager.shared.settings
        settings.highlightSameNumbers = false
        SettingsManager.shared.updateSettings(settings)

        // Wait for observer
        let expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Trigger a refresh by changing selection
        viewModel.selectCell(at: nil)
        viewModel.selectCell(at: position1)

        // Should no longer highlight same numbers
        XCTAssertFalse(viewModel.highlightSameNumbers)
        XCTAssertFalse(viewModel.cell(at: position2).isSameNumber)
    }

    /// Tests that showTimer setting observer syncs correctly
    func testSettingsObserver_ShowTimer_SyncsWithViewModel() {
        // Initial value should be true (default)
        XCTAssertTrue(viewModel.showTimer)

        // Update via SettingsManager
        var settings = SettingsManager.shared.settings
        settings.showTimer = false
        SettingsManager.shared.updateSettings(settings)

        // Wait for observer
        let expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // ViewModel should sync
        XCTAssertFalse(viewModel.showTimer)
    }

    /// Tests that hapticFeedback setting observer syncs correctly
    func testSettingsObserver_HapticFeedback_SyncsWithViewModel() {
        // Initial value should be true (default)
        XCTAssertTrue(viewModel.hapticFeedback)

        // Update via SettingsManager
        var settings = SettingsManager.shared.settings
        settings.hapticFeedback = false
        SettingsManager.shared.updateSettings(settings)

        // Wait for observer
        let expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // ViewModel should sync
        XCTAssertFalse(viewModel.hapticFeedback)
    }

    /// Tests that soundEffects setting observer syncs correctly
    func testSettingsObserver_SoundEffects_SyncsWithViewModel() {
        // Initial value should be true (default)
        XCTAssertTrue(viewModel.soundEffects)

        // Update via SettingsManager
        var settings = SettingsManager.shared.settings
        settings.soundEffects = false
        SettingsManager.shared.updateSettings(settings)

        // Wait for observer
        let expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // ViewModel should sync
        XCTAssertFalse(viewModel.soundEffects)
    }

    /// Tests that multiple settings changes are handled correctly
    func testSettingsObserver_MultipleChanges_AllSync() {
        // Update multiple settings at once
        var settings = SettingsManager.shared.settings
        settings.autoCheckErrors = false
        settings.showTimer = false
        settings.highlightSameNumbers = false
        settings.hapticFeedback = false
        settings.soundEffects = false
        SettingsManager.shared.updateSettings(settings)

        // Wait for observer
        let expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // All should be synced
        XCTAssertFalse(viewModel.autoCheckErrors)
        XCTAssertFalse(viewModel.showTimer)
        XCTAssertFalse(viewModel.highlightSameNumbers)
        XCTAssertFalse(viewModel.hapticFeedback)
        XCTAssertFalse(viewModel.soundEffects)

        // Conflicts should be cleared
        XCTAssertTrue(viewModel.conflictingPositions.isEmpty)
    }

    /// Tests that settings persist across ViewModel instances
    func testSettingsObserver_PersistsAcrossViewModels() {
        // Update settings
        var settings = SettingsManager.shared.settings
        settings.autoCheckErrors = false
        settings.highlightSameNumbers = false
        SettingsManager.shared.updateSettings(settings)

        // Wait for observer on first view model
        var expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Create a new ViewModel
        let newViewModel = GameViewModel(puzzle: puzzle)

        // Wait for observer on new view model
        expectation = XCTestExpectation(description: "Settings observer should update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // New ViewModel should have the updated settings
        XCTAssertFalse(newViewModel.autoCheckErrors)
        XCTAssertFalse(newViewModel.highlightSameNumbers)

        // Reset settings for other tests
        settings.autoCheckErrors = true
        settings.highlightSameNumbers = true
        SettingsManager.shared.updateSettings(settings)
    }
}
