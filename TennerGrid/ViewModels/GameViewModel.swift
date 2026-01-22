//
//  GameViewModel.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Combine
import Foundation

/// ViewModel managing the game state and user interactions
@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current game state
    @Published private(set) var gameState: GameState

    /// Currently selected cell position
    @Published private(set) var selectedPosition: CellPosition?

    /// Whether notes/pencil marks mode is enabled
    @Published private(set) var notesMode: Bool = false

    /// Current error message (nil if no error)
    @Published private(set) var errorMessage: String?

    /// Positions with conflicts/errors
    @Published private(set) var conflictingPositions: Set<CellPosition> = []

    // MARK: - Private Properties

    private let validationService = ValidationService()
    private let hintService = HintService()

    // MARK: - Initialization

    /// Creates a new GameViewModel with the given game state
    /// - Parameter gameState: The initial game state
    init(gameState: GameState) {
        self.gameState = gameState
        selectedPosition = gameState.selectedCell
        notesMode = gameState.notesMode
    }

    /// Creates a new GameViewModel from a puzzle
    /// - Parameter puzzle: The puzzle to play
    convenience init(puzzle: TennerGridPuzzle) {
        let gameState = GameState(puzzle: puzzle)
        self.init(gameState: gameState)
    }

    // MARK: - Cell Selection

    /// Selects a cell at the given position
    /// - Parameter position: The position to select (nil to clear selection)
    func selectCell(at position: CellPosition?) {
        // Validate position if not nil
        if let position {
            guard gameState.puzzle.isValidPosition(position) else {
                errorMessage = "Invalid cell position"
                return
            }
        }

        // Update selection
        selectedPosition = position
        gameState.selectCell(at: position)

        // Clear error message when changing selection
        errorMessage = nil
    }

    /// Toggles selection for a cell (selects if unselected, deselects if selected)
    /// - Parameter position: The position to toggle
    func toggleCellSelection(at position: CellPosition) {
        if selectedPosition == position {
            selectCell(at: nil)
        } else {
            selectCell(at: position)
        }
    }

    // MARK: - Number Entry

    /// Enters a number at the currently selected cell
    /// - Parameter value: The value to enter (0-9)
    func enterNumber(_ value: Int) {
        // Validate value range
        guard value >= 0, value <= 9 else {
            errorMessage = "Invalid number: must be 0-9"
            return
        }

        // Check if a cell is selected
        guard let position = selectedPosition else {
            errorMessage = "No cell selected"
            return
        }

        // Check if cell is editable
        guard gameState.isEditable(at: position) else {
            errorMessage = "Cannot modify pre-filled cells"
            return
        }

        // Check if we're in notes mode
        if notesMode {
            // Toggle pencil mark
            gameState.togglePencilMark(value, at: position)
            errorMessage = nil
        } else {
            // Validate placement
            let isValid = validationService.isValidPlacement(
                value: value,
                at: position,
                in: gameState.currentGrid,
                puzzle: gameState.puzzle
            )

            if isValid {
                // Place the number
                gameState.setValue(value, at: position)
                errorMessage = nil

                // Update conflicts
                updateConflicts()

                // Check for completion
                checkCompletion()
            } else {
                // Record error
                gameState.recordError()
                errorMessage = "Invalid placement: violates game rules"

                // Show conflicts
                let conflicts = validationService.detectConflicts(
                    at: position,
                    in: {
                        var tempGrid = gameState.currentGrid
                        tempGrid[position.row][position.column] = value
                        return tempGrid
                    }(),
                    puzzle: gameState.puzzle
                )
                conflictingPositions = Set(conflicts)
            }
        }
    }

    /// Clears the currently selected cell
    func clearSelectedCell() {
        guard let position = selectedPosition else {
            errorMessage = "No cell selected"
            return
        }

        guard gameState.isEditable(at: position) else {
            errorMessage = "Cannot modify pre-filled cells"
            return
        }

        // Clear the cell
        gameState.clearCell(at: position)
        errorMessage = nil

        // Update conflicts
        updateConflicts()
    }

    // MARK: - Notes Mode

    /// Toggles notes/pencil marks mode
    func toggleNotesMode() {
        notesMode.toggle()
        gameState.notesMode = notesMode
    }

    /// Sets notes mode to a specific value
    /// - Parameter enabled: Whether notes mode should be enabled
    func setNotesMode(_ enabled: Bool) {
        notesMode = enabled
        gameState.notesMode = enabled
    }

    // MARK: - Pencil Marks

    /// Adds a pencil mark to the selected cell
    /// - Parameter mark: The mark to add (0-9)
    func addPencilMark(_ mark: Int) {
        guard let position = selectedPosition else {
            errorMessage = "No cell selected"
            return
        }

        guard mark >= 0, mark <= 9 else {
            errorMessage = "Invalid mark: must be 0-9"
            return
        }

        guard gameState.isEditable(at: position) else {
            errorMessage = "Cannot modify pre-filled cells"
            return
        }

        guard gameState.isEmpty(at: position) else {
            errorMessage = "Cannot add marks to filled cells"
            return
        }

        var marks = gameState.marks(at: position)
        marks.insert(mark)
        gameState.setPencilMarks(marks, at: position)
        errorMessage = nil
    }

    /// Removes a pencil mark from the selected cell
    /// - Parameter mark: The mark to remove (0-9)
    func removePencilMark(_ mark: Int) {
        guard let position = selectedPosition else {
            errorMessage = "No cell selected"
            return
        }

        guard mark >= 0, mark <= 9 else { return }

        var marks = gameState.marks(at: position)
        marks.remove(mark)
        gameState.setPencilMarks(marks, at: position)
        errorMessage = nil
    }

    /// Toggles a pencil mark at the selected cell
    /// - Parameter mark: The mark to toggle (0-9)
    func togglePencilMark(_ mark: Int) {
        guard let position = selectedPosition else {
            errorMessage = "No cell selected"
            return
        }

        guard mark >= 0, mark <= 9 else {
            errorMessage = "Invalid mark: must be 0-9"
            return
        }

        guard gameState.isEditable(at: position) else {
            errorMessage = "Cannot modify pre-filled cells"
            return
        }

        guard gameState.isEmpty(at: position) else {
            errorMessage = "Cannot add marks to filled cells"
            return
        }

        gameState.togglePencilMark(mark, at: position)
        errorMessage = nil
    }

    /// Clears all pencil marks from the selected cell
    func clearPencilMarks() {
        guard let position = selectedPosition else {
            errorMessage = "No cell selected"
            return
        }

        guard gameState.isEditable(at: position) else {
            errorMessage = "Cannot modify pre-filled cells"
            return
        }

        gameState.setPencilMarks([], at: position)
        errorMessage = nil
    }

    // MARK: - Validation

    /// Updates the set of conflicting positions based on current grid state
    private func updateConflicts() {
        var allConflicts = Set<CellPosition>()

        for row in 0 ..< gameState.puzzle.rows {
            for col in 0 ..< gameState.puzzle.columns {
                let position = CellPosition(row: row, column: col)

                // Skip empty cells
                guard gameState.value(at: position) != nil else { continue }

                // Get conflicts for this cell
                let conflicts = validationService.detectConflicts(
                    at: position,
                    in: gameState.currentGrid,
                    puzzle: gameState.puzzle
                )

                if !conflicts.isEmpty {
                    // Add the cell itself and all its conflicts
                    allConflicts.insert(position)
                    allConflicts.formUnion(conflicts)
                }
            }
        }

        conflictingPositions = allConflicts
    }

    /// Checks if a value can be placed at a position
    /// - Parameters:
    ///   - value: The value to check
    ///   - position: The position to check
    /// - Returns: True if the placement is valid
    func canPlaceValue(_ value: Int, at position: CellPosition) -> Bool {
        guard gameState.puzzle.isValidPosition(position) else { return false }
        guard gameState.isEditable(at: position) else { return false }

        return validationService.isValidPlacement(
            value: value,
            at: position,
            in: gameState.currentGrid,
            puzzle: gameState.puzzle
        )
    }

    /// Gets all valid values that can be placed at a position
    /// - Parameter position: The position to check
    /// - Returns: Set of valid values (0-9)
    func getValidValues(for position: CellPosition) -> Set<Int> {
        guard gameState.puzzle.isValidPosition(position) else { return [] }
        guard gameState.isEditable(at: position) else { return [] }
        guard gameState.isEmpty(at: position) else { return [] }

        return hintService.getPossibleValues(for: position, in: gameState)
    }

    // MARK: - Game Completion

    /// Checks if the puzzle is completed and updates state accordingly
    private func checkCompletion() {
        // Check if grid is complete
        guard gameState.isGridComplete() else { return }

        // Check if solution is correct
        if gameState.isCorrectlyCompleted() {
            gameState.complete()
        }
    }

    // MARK: - Error Management

    /// Clears the current error message
    func clearError() {
        errorMessage = nil
        conflictingPositions = []
    }

    /// Checks if a position has a conflict
    /// - Parameter position: The position to check
    /// - Returns: True if the position has a conflict
    func hasConflict(at position: CellPosition) -> Bool {
        conflictingPositions.contains(position)
    }

    // MARK: - Game State Queries

    /// Gets the value at a position
    /// - Parameter position: The position to query
    /// - Returns: The value at the position (nil if empty)
    func value(at position: CellPosition) -> Int? {
        gameState.value(at: position)
    }

    /// Gets pencil marks at a position
    /// - Parameter position: The position to query
    /// - Returns: Set of pencil marks
    func marks(at position: CellPosition) -> Set<Int> {
        gameState.marks(at: position)
    }

    /// Checks if a cell is editable
    /// - Parameter position: The position to check
    /// - Returns: True if the cell can be edited
    func isEditable(at position: CellPosition) -> Bool {
        gameState.isEditable(at: position)
    }

    /// Checks if a cell is selected
    /// - Parameter position: The position to check
    /// - Returns: True if the cell is selected
    func isSelected(at position: CellPosition) -> Bool {
        selectedPosition == position
    }

    /// Checks if a cell is empty
    /// - Parameter position: The position to check
    /// - Returns: True if the cell is empty
    func isEmpty(at position: CellPosition) -> Bool {
        gameState.isEmpty(at: position)
    }
}

// MARK: - CustomStringConvertible

extension GameViewModel: CustomStringConvertible {
    var description: String {
        """
        GameViewModel(
            state: \(gameState),
            selectedPosition: \(selectedPosition?.description ?? "none"),
            notesMode: \(notesMode),
            conflicts: \(conflictingPositions.count)
        )
        """
    }
}
