import Foundation
import Testing
@testable import TennerGrid

struct GameStateTests {
    // MARK: - Test Helpers

    private func createTestPuzzle(
        rows: Int = 3,
        columns: Int = 10,
        difficulty: Difficulty = .easy
    ) -> TennerGridPuzzle {
        // Create a simple test puzzle
        let solution = (0 ..< rows).map { row in
            (0 ..< columns).map { col in
                (row + col) % 10
            }
        }

        let targetSums = (0 ..< columns).map { col in
            (0 ..< rows).reduce(0) { sum, row in
                sum + solution[row][col]
            }
        }

        // Create initial grid with some prefilled cells
        var initialGrid: [[Int?]] = solution.map { $0.map { _ in nil } }
        initialGrid[0][0] = solution[0][0] // Prefill first cell

        return TennerGridPuzzle(
            id: UUID(),
            columns: columns,
            rows: rows,
            difficulty: difficulty,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: solution
        )
    }

    // MARK: - Initialization Tests

    @Test func initializationWithDefaultValues() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)

        #expect(state.puzzle == puzzle)
        #expect(state.currentGrid == puzzle.initialGrid)
        #expect(state.selectedCell == nil)
        #expect(state.notesMode == false)
        #expect(state.pencilMarks.isEmpty)
        #expect(state.elapsedTime == 0)
        #expect(state.isPaused == false)
        #expect(state.isCompleted == false)
        #expect(state.completedAt == nil)
        #expect(state.hintsUsed == 0)
        #expect(state.errorCount == 0)
    }

    @Test func initializationWithCustomStartDate() {
        let puzzle = createTestPuzzle()
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        let state = GameState(puzzle: puzzle, startedAt: customDate)

        #expect(state.startedAt == customDate)
    }

    @Test func initializationSetsStartedAtToNow() {
        let beforeCreation = Date()
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)
        let afterCreation = Date()

        #expect(state.startedAt >= beforeCreation)
        #expect(state.startedAt <= afterCreation)
    }

    @Test func newFactoryMethod() {
        let puzzle = createTestPuzzle()
        let state = GameState.new(from: puzzle)

        #expect(state.puzzle == puzzle)
        #expect(state.elapsedTime == 0)
        #expect(state.isCompleted == false)
    }

    // MARK: - Computed Properties Tests

    @Test func filledCellCountWithEmptyGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Clear all cells (except prefilled)
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                if !puzzle.isPrefilled(at: position) {
                    state.currentGrid[row][col] = nil
                }
            }
        }

        #expect(state.filledCellCount == 0)
    }

    @Test func filledCellCountWithPartiallyFilled() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill one non-prefilled cell
        state.setValue(5, at: CellPosition(row: 1, column: 1))

        #expect(state.filledCellCount == 1)
    }

    @Test func filledCellCountExcludesPrefilledCells() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)

        // The initial grid has one prefilled cell, but it shouldn't count
        #expect(state.filledCellCount == 0)
    }

    @Test func emptyCellCount() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        let totalEmpty = puzzle.emptyCellCount
        #expect(state.emptyCellCount == totalEmpty)

        // Fill one cell
        state.setValue(5, at: CellPosition(row: 1, column: 1))
        #expect(state.emptyCellCount == totalEmpty - 1)
    }

    @Test func progressWithNoFilledCells() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)

        #expect(state.progress == 0.0)
    }

    @Test func progressWithPartiallyFilled() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        let totalEmpty = puzzle.emptyCellCount
        let halfEmpty = totalEmpty / 2

        // Fill half the cells
        var filled = 0
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                if !puzzle.isPrefilled(at: position), filled < halfEmpty {
                    state.setValue(5, at: position)
                    filled += 1
                }
            }
        }

        let expectedProgress = Double(halfEmpty) / Double(totalEmpty)
        #expect(abs(state.progress - expectedProgress) < 0.01)
    }

    @Test func progressWithAllFilledCells() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill all empty cells
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                if !puzzle.isPrefilled(at: position) {
                    state.setValue(puzzle.solution[row][col], at: position)
                }
            }
        }

        #expect(state.progress == 1.0)
    }

    @Test func formattedTimeZero() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)

        #expect(state.formattedTime == "00:00")
    }

    @Test func formattedTimeMinutesAndSeconds() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        state.addTime(125) // 2:05

        #expect(state.formattedTime == "02:05")
    }

    @Test func formattedTimeLargeValues() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        state.addTime(3661) // 61:01

        #expect(state.formattedTime == "61:01")
    }

    @Test func canResumeWhenNotCompleted() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        state.setValue(5, at: CellPosition(row: 1, column: 1))

        #expect(state.canResume)
    }

    @Test func cannotResumeWhenCompleted() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        state.setValue(5, at: CellPosition(row: 1, column: 1))
        state.complete()

        #expect(!state.canResume)
    }

    @Test func cannotResumeWithNoProgress() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)

        #expect(!state.canResume)
    }

    // MARK: - Grid Access Tests

    @Test func valueAtPosition() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        #expect(state.value(at: position) == nil)

        state.setValue(7, at: position)
        #expect(state.value(at: position) == 7)
    }

    @Test func valueAtInvalidPositionReturnsNil() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)
        let invalidPosition = CellPosition(row: 10, column: 10)

        #expect(state.value(at: invalidPosition) == nil)
    }

    @Test func marksAtPosition() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        #expect(state.marks(at: position).isEmpty)

        let marks: Set<Int> = [1, 2, 3]
        state.setPencilMarks(marks, at: position)
        #expect(state.marks(at: position) == marks)
    }

    @Test func isEditableForPrefilledCell() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)
        let prefilledPosition = CellPosition(row: 0, column: 0)

        #expect(!state.isEditable(at: prefilledPosition))
    }

    @Test func isEditableForEmptyCell() {
        let puzzle = createTestPuzzle()
        let state = GameState(puzzle: puzzle)
        let emptyPosition = CellPosition(row: 1, column: 1)

        #expect(state.isEditable(at: emptyPosition))
    }

    @Test func isEmptyChecks() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        #expect(state.isEmpty(at: position))

        state.setValue(5, at: position)
        #expect(!state.isEmpty(at: position))
    }

    // MARK: - Grid Modification Tests

    @Test func setValueOnEmptyCell() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setValue(7, at: position)
        #expect(state.value(at: position) == 7)
    }

    @Test func setValueChangesExistingValue() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setValue(5, at: position)
        state.setValue(8, at: position)
        #expect(state.value(at: position) == 8)
    }

    @Test func setValueClearsPencilMarks() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setPencilMarks([1, 2, 3], at: position)
        state.setValue(5, at: position)

        #expect(state.marks(at: position).isEmpty)
    }

    @Test func setValueToNilClearsCell() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setValue(7, at: position)
        state.setValue(nil, at: position)

        #expect(state.value(at: position) == nil)
    }

    @Test func setValueOnPrefilledCellDoesNothing() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let prefilledPosition = CellPosition(row: 0, column: 0)
        let originalValue = state.value(at: prefilledPosition)

        state.setValue(9, at: prefilledPosition)
        #expect(state.value(at: prefilledPosition) == originalValue)
    }

    @Test func setValueOnInvalidPositionDoesNothing() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let invalidPosition = CellPosition(row: 10, column: 10)

        state.setValue(5, at: invalidPosition)
        // Should not crash or cause issues
    }

    @Test func setPencilMarks() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)
        let marks: Set<Int> = [1, 2, 3]

        state.setPencilMarks(marks, at: position)
        #expect(state.marks(at: position) == marks)
    }

    @Test func setPencilMarksWithEmptySetClearsMarks() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setPencilMarks([1, 2, 3], at: position)
        state.setPencilMarks([], at: position)

        #expect(state.marks(at: position).isEmpty)
    }

    @Test func setPencilMarksOnFilledCellDoesNothing() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setValue(5, at: position)
        state.setPencilMarks([1, 2, 3], at: position)

        #expect(state.marks(at: position).isEmpty)
    }

    @Test func setPencilMarksOnPrefilledCellDoesNothing() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let prefilledPosition = CellPosition(row: 0, column: 0)

        state.setPencilMarks([1, 2, 3], at: prefilledPosition)
        #expect(state.marks(at: prefilledPosition).isEmpty)
    }

    @Test func togglePencilMarkAddsNewMark() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.togglePencilMark(5, at: position)
        #expect(state.marks(at: position).contains(5))
    }

    @Test func togglePencilMarkRemovesExistingMark() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setPencilMarks([1, 2, 5], at: position)
        state.togglePencilMark(5, at: position)

        #expect(!state.marks(at: position).contains(5))
        #expect(state.marks(at: position) == [1, 2])
    }

    @Test func togglePencilMarkWithInvalidNumberDoesNothing() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.togglePencilMark(10, at: position) // Invalid
        state.togglePencilMark(-1, at: position) // Invalid

        #expect(state.marks(at: position).isEmpty)
    }

    @Test func togglePencilMarkOnFilledCellDoesNothing() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setValue(7, at: position)
        state.togglePencilMark(5, at: position)

        #expect(state.marks(at: position).isEmpty)
    }

    @Test func clearCellRemovesValueAndMarks() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        state.setValue(7, at: position)
        state.clearCell(at: position)
        state.setPencilMarks([1, 2, 3], at: position)

        let position2 = CellPosition(row: 1, column: 2)
        state.setPencilMarks([4, 5, 6], at: position2)
        state.clearCell(at: position2)

        #expect(state.value(at: position) == nil)
        #expect(state.value(at: position2) == nil)
        #expect(state.marks(at: position2).isEmpty)
    }

    // MARK: - Selection Management Tests

    @Test func selectCell() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 2)

        state.selectCell(at: position)
        #expect(state.selectedCell == position)
    }

    @Test func selectCellWithNilClearsSelection() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        state.selectCell(at: CellPosition(row: 1, column: 2))
        state.selectCell(at: nil)

        #expect(state.selectedCell == nil)
    }

    @Test func isSelectedChecksCurrentSelection() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 2)

        state.selectCell(at: position)
        #expect(state.isSelected(position))
        #expect(!state.isSelected(CellPosition(row: 0, column: 0)))
    }

    // MARK: - Game Flow Tests

    @Test func pauseSetsFlag() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        #expect(!state.isPaused)
        state.pause()
        #expect(state.isPaused)
    }

    @Test func resumeClearsFlag() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        state.pause()
        state.resume()
        #expect(!state.isPaused)
    }

    @Test func addTimeIncreasesElapsedTime() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        state.addTime(30)
        #expect(state.elapsedTime == 30)

        state.addTime(45)
        #expect(state.elapsedTime == 75)
    }

    @Test func completeMarksAsCompleted() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        state.complete()

        #expect(state.isCompleted)
        #expect(state.completedAt != nil)
        #expect(state.isPaused)
        #expect(state.selectedCell == nil)
    }

    @Test func completeSetCompletionDate() throws {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        let beforeCompletion = Date()
        state.complete()
        let afterCompletion = Date()

        #expect(try #require(state.completedAt) >= beforeCompletion)
        #expect(try #require(state.completedAt) <= afterCompletion)
    }

    @Test func useHintIncrementsCount() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        #expect(state.hintsUsed == 0)
        state.useHint()
        #expect(state.hintsUsed == 1)
        state.useHint()
        #expect(state.hintsUsed == 2)
    }

    @Test func recordErrorIncrementsCount() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        #expect(state.errorCount == 0)
        state.recordError()
        #expect(state.errorCount == 1)
        state.recordError()
        #expect(state.errorCount == 2)
    }

    // MARK: - Validation Tests

    @Test func checkSolutionWithEmptyGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Clear prefilled cells for testing
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                state.currentGrid[row][col] = nil
            }
        }

        #expect(state.checkSolution())
    }

    @Test func checkSolutionWithCorrectPartialSolution() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill one cell correctly
        let position = CellPosition(row: 1, column: 1)
        state.setValue(puzzle.solution[1][1], at: position)

        #expect(state.checkSolution())
    }

    @Test func checkSolutionWithIncorrectValue() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill one cell incorrectly
        let position = CellPosition(row: 1, column: 1)
        let wrongValue = (puzzle.solution[1][1] + 1) % 10
        state.setValue(wrongValue, at: position)

        #expect(!state.checkSolution())
    }

    @Test func checkSolutionWithCompleteSolution() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill entire grid with solution
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                state.currentGrid[row][col] = puzzle.solution[row][col]
            }
        }

        #expect(state.checkSolution())
    }

    @Test func isGridCompleteWithEmptyGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Clear all cells
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                state.currentGrid[row][col] = nil
            }
        }

        #expect(!state.isGridComplete())
    }

    @Test func isGridCompleteWithPartialGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill half the grid
        state.setValue(5, at: CellPosition(row: 1, column: 1))

        #expect(!state.isGridComplete())
    }

    @Test func isGridCompleteWithFullGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill entire grid
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                state.currentGrid[row][col] = 5
            }
        }

        #expect(state.isGridComplete())
    }

    @Test func isCorrectlyCompletedWithEmptyGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Clear all cells
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                state.currentGrid[row][col] = nil
            }
        }

        #expect(!state.isCorrectlyCompleted())
    }

    @Test func isCorrectlyCompletedWithPartialCorrectGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        state.setValue(puzzle.solution[1][1], at: CellPosition(row: 1, column: 1))

        #expect(!state.isCorrectlyCompleted())
    }

    @Test func isCorrectlyCompletedWithFullCorrectGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill entire grid with solution
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                state.currentGrid[row][col] = puzzle.solution[row][col]
            }
        }

        #expect(state.isCorrectlyCompleted())
    }

    @Test func isCorrectlyCompletedWithFullIncorrectGrid() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Fill entire grid with wrong values
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                state.currentGrid[row][col] = (puzzle.solution[row][col] + 1) % 10
            }
        }

        #expect(!state.isCorrectlyCompleted())
    }

    // MARK: - Equatable Tests

    @Test func equalityWithIdenticalStates() {
        let puzzle = createTestPuzzle()
        let date = Date()
        let state1 = GameState(puzzle: puzzle, startedAt: date)
        let state2 = GameState(puzzle: puzzle, startedAt: date)

        #expect(state1 == state2)
    }

    @Test func equalityWithDifferentPuzzles() {
        let puzzle1 = createTestPuzzle(difficulty: .easy)
        let puzzle2 = createTestPuzzle(difficulty: .medium)
        let state1 = GameState(puzzle: puzzle1)
        let state2 = GameState(puzzle: puzzle2)

        #expect(state1 != state2)
    }

    @Test func equalityAfterModification() {
        let puzzle = createTestPuzzle()
        let date = Date()
        var state1 = GameState(puzzle: puzzle, startedAt: date)
        let state2 = GameState(puzzle: puzzle, startedAt: date)

        state1.setValue(5, at: CellPosition(row: 1, column: 1))

        #expect(state1 != state2)
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        state.setValue(5, at: CellPosition(row: 1, column: 1))
        state.setPencilMarks([1, 2, 3], at: CellPosition(row: 1, column: 2))

        let encoder = JSONEncoder()
        let data = try encoder.encode(state)

        #expect(!data.isEmpty)
    }

    @Test func codableDecoding() throws {
        let puzzle = createTestPuzzle()
        var original = GameState(puzzle: puzzle)
        original.setValue(5, at: CellPosition(row: 1, column: 1))
        original.setPencilMarks([1, 2, 3], at: CellPosition(row: 1, column: 2))
        original.addTime(120)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(GameState.self, from: data)

        #expect(decoded == original)
    }

    @Test func codableRoundTrip() throws {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        state.setValue(7, at: CellPosition(row: 1, column: 1))
        state.setPencilMarks([2, 4, 6], at: CellPosition(row: 2, column: 2))
        state.selectCell(at: CellPosition(row: 1, column: 1))
        state.notesMode = true
        state.addTime(300)
        state.useHint()
        state.recordError()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(state)
        let decoded = try decoder.decode(GameState.self, from: encoded)

        #expect(decoded.puzzle == state.puzzle)
        #expect(decoded.currentGrid == state.currentGrid)
        #expect(decoded.selectedCell == state.selectedCell)
        #expect(decoded.notesMode == state.notesMode)
        #expect(decoded.pencilMarks == state.pencilMarks)
        #expect(decoded.elapsedTime == state.elapsedTime)
        #expect(decoded.hintsUsed == state.hintsUsed)
        #expect(decoded.errorCount == state.errorCount)
    }

    // MARK: - CustomStringConvertible Tests

    @Test func descriptionContainsKeyInfo() {
        let puzzle = createTestPuzzle(difficulty: .medium)
        var state = GameState(puzzle: puzzle)
        state.setValue(5, at: CellPosition(row: 1, column: 1))
        state.addTime(125)

        let description = state.description

        #expect(description.contains("GameState"))
        #expect(description.contains("Medium"))
        #expect(description.contains("progress"))
        #expect(description.contains("time"))
        #expect(description.contains("02:05"))
    }

    // MARK: - Edge Cases

    @Test func modifyingLargeGrid() {
        let puzzle = createTestPuzzle(rows: 5, columns: 10)
        var state = GameState(puzzle: puzzle)

        // Fill all editable cells
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                if state.isEditable(at: position) {
                    state.setValue((row + col) % 10, at: position)
                }
            }
        }

        #expect(state.filledCellCount > 0)
    }

    @Test func multipleOperationsSequence() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)
        let position = CellPosition(row: 1, column: 1)

        // Set value
        state.setValue(5, at: position)
        #expect(state.value(at: position) == 5)

        // Clear
        state.clearCell(at: position)
        #expect(state.value(at: position) == nil)

        // Set pencil marks
        state.setPencilMarks([1, 2, 3], at: position)
        #expect(state.marks(at: position).count == 3)

        // Toggle mark
        state.togglePencilMark(4, at: position)
        #expect(state.marks(at: position).count == 4)

        // Set value (should clear marks)
        state.setValue(7, at: position)
        #expect(state.marks(at: position).isEmpty)
        #expect(state.value(at: position) == 7)
    }

    @Test func stateTransitionsForGameFlow() {
        let puzzle = createTestPuzzle()
        var state = GameState(puzzle: puzzle)

        // Start playing
        #expect(!state.isPaused)
        #expect(!state.isCompleted)

        // Add some time
        state.addTime(60)
        #expect(state.elapsedTime == 60)

        // Pause
        state.pause()
        #expect(state.isPaused)

        // Resume
        state.resume()
        #expect(!state.isPaused)

        // Use hints
        state.useHint()
        state.useHint()
        #expect(state.hintsUsed == 2)

        // Complete
        state.complete()
        #expect(state.isCompleted)
        #expect(state.isPaused)
        #expect(state.completedAt != nil)
    }
}
