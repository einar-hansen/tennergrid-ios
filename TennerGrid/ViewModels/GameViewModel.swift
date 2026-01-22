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

    /// Current elapsed time (published for UI updates)
    @Published private(set) var elapsedTime: TimeInterval = 0

    /// Whether the timer is currently running
    @Published private(set) var isTimerRunning: Bool = false

    // MARK: - Private Properties

    private let validationService = ValidationService()
    private let hintService = HintService()

    /// Maximum number of actions to keep in history (to manage memory)
    private let maxHistorySize = 50

    /// Stack of actions that can be undone (most recent at end)
    private var undoStack: [GameAction] = []

    /// Stack of actions that can be redone (most recent at end)
    private var redoStack: [GameAction] = []

    /// Timer for tracking elapsed time
    private var timer: Timer?

    /// Last time the timer was updated (for calculating elapsed intervals)
    private var lastTimerUpdate: Date?

    // MARK: - Initialization

    /// Creates a new GameViewModel with the given game state
    /// - Parameter gameState: The initial game state
    init(gameState: GameState) {
        self.gameState = gameState
        selectedPosition = gameState.selectedCell
        notesMode = gameState.notesMode
        elapsedTime = gameState.elapsedTime

        // Start timer if game is not paused or completed
        if !gameState.isPaused, !gameState.isCompleted {
            startTimer()
        }
    }

    /// Creates a new GameViewModel from a puzzle
    /// - Parameter puzzle: The puzzle to play
    convenience init(puzzle: TennerGridPuzzle) {
        let gameState = GameState(puzzle: puzzle)
        self.init(gameState: gameState)
    }

    deinit {
        timer?.invalidate()
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
            // Record old marks
            let oldMarks = gameState.marks(at: position)

            // Toggle pencil mark
            gameState.togglePencilMark(value, at: position)

            // Record action
            let newMarks = gameState.marks(at: position)
            let action = GameAction.togglePencilMark(
                value,
                at: position,
                from: oldMarks,
                to: newMarks
            )
            recordAction(action)

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
                // Record old state
                let oldValue = gameState.value(at: position)
                let oldMarks = gameState.marks(at: position)

                // Place the number
                gameState.setValue(value, at: position)

                // Record action
                let action = GameAction.setValue(
                    at: position,
                    from: oldValue,
                    to: value,
                    clearingMarks: oldMarks
                )
                recordAction(action)

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

        // Record old state
        let oldValue = gameState.value(at: position)
        let oldMarks = gameState.marks(at: position)

        // Clear the cell
        gameState.clearCell(at: position)

        // Record action
        let action = GameAction.clearCell(
            at: position,
            from: oldValue,
            clearingMarks: oldMarks
        )
        recordAction(action)

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

        // Record old marks
        let oldMarks = gameState.marks(at: position)
        var marks = oldMarks
        marks.insert(mark)

        // Update marks
        gameState.setPencilMarks(marks, at: position)

        // Record action
        let action = GameAction.setPencilMarks(
            at: position,
            from: oldMarks,
            to: marks
        )
        recordAction(action)

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

        // Record old marks
        let oldMarks = gameState.marks(at: position)
        var marks = oldMarks
        marks.remove(mark)

        // Update marks
        gameState.setPencilMarks(marks, at: position)

        // Record action
        let action = GameAction.setPencilMarks(
            at: position,
            from: oldMarks,
            to: marks
        )
        recordAction(action)

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

        // Record old marks
        let oldMarks = gameState.marks(at: position)

        // Toggle mark
        gameState.togglePencilMark(mark, at: position)

        // Record action
        let newMarks = gameState.marks(at: position)
        let action = GameAction.togglePencilMark(
            mark,
            at: position,
            from: oldMarks,
            to: newMarks
        )
        recordAction(action)

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

        // Record old marks
        let oldMarks = gameState.marks(at: position)

        // Clear marks
        gameState.setPencilMarks([], at: position)

        // Record action
        let action = GameAction.setPencilMarks(
            at: position,
            from: oldMarks,
            to: []
        )
        recordAction(action)

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

    // MARK: - Timer Management

    /// Starts the game timer
    func startTimer() {
        // Don't start if already running or game is completed
        guard !isTimerRunning, !gameState.isCompleted else { return }

        // Record the current time
        lastTimerUpdate = Date()

        // Resume game state if paused
        if gameState.isPaused {
            gameState.resume()
        }

        // Create and schedule timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimer()
            }
        }

        isTimerRunning = true
    }

    /// Pauses the game timer
    func pauseTimer() {
        // Update one last time before pausing
        updateTimer()

        // Stop the timer
        stopTimer()

        // Pause game state
        gameState.pause()
    }

    /// Resumes the game timer
    func resumeTimer() {
        // Resume is the same as start - it handles the state correctly
        startTimer()
    }

    /// Stops the timer (internal use)
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        lastTimerUpdate = nil
        isTimerRunning = false
    }

    /// Updates the elapsed time based on the timer
    private func updateTimer() {
        guard let lastUpdate = lastTimerUpdate else { return }

        let now = Date()
        let interval = now.timeIntervalSince(lastUpdate)

        // Update elapsed time
        elapsedTime += interval
        gameState.addTime(interval)

        // Record new update time
        lastTimerUpdate = now
    }

    /// Formatted elapsed time string (MM:SS)
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Game Completion

    /// Checks if the puzzle is completed and updates state accordingly
    private func checkCompletion() {
        // Check if grid is complete
        guard gameState.isGridComplete() else { return }

        // Check if solution is correct
        if gameState.isCorrectlyCompleted() {
            // Stop the timer before completing
            stopTimer()

            // Mark game as complete
            gameState.complete()
        }
    }

    // MARK: - Undo/Redo Management

    /// Records an action in the undo history
    /// - Parameter action: The action to record
    private func recordAction(_ action: GameAction) {
        // Only record actions that made actual changes
        guard action.madeChanges else { return }

        // Add to undo stack
        undoStack.append(action)

        // Limit history size
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        // Clear redo stack when a new action is performed
        redoStack.removeAll()
    }

    /// Whether there are actions available to undo
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// Whether there are actions available to redo
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// Returns the number of actions in the undo history
    var undoCount: Int {
        undoStack.count
    }

    /// Returns the number of actions in the redo history
    var redoCount: Int {
        redoStack.count
    }

    /// Undoes the last action and restores the previous game state
    func undo() {
        // Check if there's anything to undo
        guard !undoStack.isEmpty else {
            errorMessage = "Nothing to undo"
            return
        }

        // Pop the last action
        let action = undoStack.removeLast()

        // Apply the inverse action to restore previous state
        applyAction(action, isUndo: true)

        // Add to redo stack
        redoStack.append(action)

        // Clear any error messages
        errorMessage = nil

        // Update conflicts
        updateConflicts()
    }

    /// Redoes the last undone action
    func redo() {
        // Check if there's anything to redo
        guard !redoStack.isEmpty else {
            errorMessage = "Nothing to redo"
            return
        }

        // Pop the last undone action
        let action = redoStack.removeLast()

        // Replay the action (use new values)
        applyAction(action, isUndo: false)

        // Add back to undo stack
        undoStack.append(action)

        // Clear any error messages
        errorMessage = nil

        // Update conflicts
        updateConflicts()
    }

    /// Applies an action to the game state
    /// - Parameters:
    ///   - action: The action to apply
    ///   - isUndo: True if this is being applied as an undo (use old values), false for redo (use new values)
    private func applyAction(_ action: GameAction, isUndo: Bool) {
        let targetValue = isUndo ? action.oldValue : action.newValue
        let targetMarks = isUndo ? action.oldPencilMarks : action.newPencilMarks

        // Apply based on action type
        switch action.type {
        case .setValue:
            // Restore value (may be nil)
            gameState.setValue(targetValue, at: action.position)
            // Restore pencil marks if we're undoing
            if isUndo, !action.oldPencilMarks.isEmpty {
                gameState.setPencilMarks(action.oldPencilMarks, at: action.position)
            }

        case .clearValue:
            // Restore value
            gameState.setValue(targetValue, at: action.position)

        case .setPencilMarks, .togglePencilMark:
            // Restore pencil marks
            gameState.setPencilMarks(targetMarks, at: action.position)

        case .clearPencilMarks:
            // Restore pencil marks
            gameState.setPencilMarks(targetMarks, at: action.position)

        case .clearCell:
            // Restore both value and marks
            if let value = targetValue {
                gameState.setValue(value, at: action.position)
            } else if !targetMarks.isEmpty {
                gameState.setPencilMarks(targetMarks, at: action.position)
            }
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

    // MARK: - Grid Support

    /// Get the cell at a specific position
    /// - Parameter position: The cell position
    /// - Returns: The cell at that position
    func cell(at position: CellPosition) -> Cell {
        gameState.currentGrid[position.row][position.column]
    }

    /// Calculate the current sum for a column
    /// - Parameter column: The column index
    /// - Returns: The sum of all values in the column
    func columnSum(for column: Int) -> Int {
        var sum = 0
        for row in 0 ..< gameState.puzzle.rows {
            if let value = gameState.currentGrid[row][column].value {
                sum += value
            }
        }
        return sum
    }

    /// Check if a column is completely filled
    /// - Parameter column: The column index
    /// - Returns: True if all cells in the column have values
    func isColumnComplete(_ column: Int) -> Bool {
        for row in 0 ..< gameState.puzzle.rows {
            if gameState.currentGrid[row][column].value == nil {
                return false
            }
        }
        return true
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
