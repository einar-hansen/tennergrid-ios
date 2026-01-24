import Combine
import Foundation
import SwiftUI

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

    // MARK: - Settings (AppStorage)

    /// Automatically highlight invalid moves
    @AppStorage("autoCheckErrors") var autoCheckErrors: Bool = true

    /// Display elapsed time during gameplay
    @AppStorage("showTimer") var showTimer: Bool = true

    /// Highlight all cells with the same number
    @AppStorage("highlightSameNumbers") var highlightSameNumbers: Bool = true

    /// Vibrate on selections and actions
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true

    /// Play sounds for actions and events
    @AppStorage("soundEffects") var soundEffects: Bool = true

    // MARK: - Private Properties

    private let validationService = ValidationService()
    private let hintService = HintService()

    /// Cached set of neighbor positions for performance optimization
    /// Updated whenever selectedPosition changes to avoid redundant calculations
    private var cachedNeighborPositions: Set<CellPosition> = []

    /// Cached set of highlighted positions (same row/column as selected)
    /// Updated whenever selectedPosition changes to avoid redundant calculations
    private var cachedHighlightedPositions: Set<CellPosition> = []

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

        // Update cached positions for performance
        updateCachedPositions(for: position)

        // Clear error message when changing selection
        errorMessage = nil
    }

    /// Updates cached neighbor and highlighted positions for performance optimization
    /// This method is called whenever the selected cell changes to pre-compute which cells
    /// should be highlighted or marked as neighbors, avoiding redundant calculations during rendering
    /// - Parameter position: The selected position (nil if no selection)
    private func updateCachedPositions(for position: CellPosition?) {
        // Clear caches if no selection
        guard let position else {
            cachedNeighborPositions.removeAll()
            cachedHighlightedPositions.removeAll()
            return
        }

        // Pre-compute neighbor positions (the 8 adjacent cells)
        var neighbors = Set<CellPosition>()
        for rowOffset in -1 ... 1 {
            for colOffset in -1 ... 1 {
                // Skip the selected cell itself
                guard rowOffset != 0 || colOffset != 0 else { continue }

                let neighborRow = position.row + rowOffset
                let neighborCol = position.column + colOffset
                let neighborPos = CellPosition(row: neighborRow, column: neighborCol)

                // Only include valid positions
                if gameState.puzzle.isValidPosition(neighborPos) {
                    neighbors.insert(neighborPos)
                }
            }
        }
        cachedNeighborPositions = neighbors

        // Pre-compute highlighted positions (same row, same column, or adjacent)
        // Note: Neighbors are also included in highlighted set for consistency with game rules
        // The visual styling gives neighbors higher priority (purple vs blue background)
        var highlighted = Set<CellPosition>()

        // Add all neighbors to highlighted set
        highlighted = neighbors

        // Add cells in the same row or column
        for row in 0 ..< gameState.puzzle.rows {
            for col in 0 ..< gameState.puzzle.columns {
                let pos = CellPosition(row: row, column: col)

                // Skip the selected cell itself
                guard pos != position else { continue }

                // Highlight cells in same row or column
                if pos.row == position.row || pos.column == position.column {
                    highlighted.insert(pos)
                }
            }
        }
        cachedHighlightedPositions = highlighted
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

    /// Gets the count of conflicts that would occur if a value were placed at a position
    /// - Parameters:
    ///   - value: The value to check
    ///   - position: The position to check
    /// - Returns: The number of conflicts (0 if placement is valid)
    func conflictCount(for value: Int, at position: CellPosition) -> Int {
        guard gameState.puzzle.isValidPosition(position) else { return 0 }
        guard gameState.isEditable(at: position) else { return 0 }

        // Create a temporary grid with the value placed
        var tempGrid = gameState.currentGrid
        tempGrid[position.row][position.column] = value

        // Detect conflicts at the position
        let conflicts = validationService.detectConflicts(
            at: position,
            in: tempGrid,
            puzzle: gameState.puzzle
        )

        return conflicts.count
    }

    // MARK: - Hint System

    /// Requests a hint for the current puzzle state
    /// Uses the hint service to find the next logical move or reveal possible values
    func requestHint() {
        // Don't provide hints if game is completed
        guard !gameState.isCompleted else {
            errorMessage = "Game is already completed"
            return
        }

        // Get a hint from the hint service
        guard let hint = hintService.provideHint(for: gameState) else {
            errorMessage = "No hint available"
            return
        }

        // Record hint usage
        gameState.useHint()

        // Apply the hint based on type
        switch hint {
        case let .logicalMove(position, value):
            // Select the cell and enter the value
            selectCell(at: position)

            // Record old state for undo
            let oldValue = gameState.value(at: position)
            let oldMarks = gameState.marks(at: position)

            // Set the value
            gameState.setValue(value, at: position)

            // Record action for undo
            let action = GameAction.setValue(
                at: position,
                from: oldValue,
                to: value,
                clearingMarks: oldMarks
            )
            recordAction(action)

            // Update conflicts and check completion
            updateConflicts()
            checkCompletion()

        case let .revealValue(position, value):
            // Select the cell and enter the revealed value
            selectCell(at: position)

            // Record old state for undo
            let oldValue = gameState.value(at: position)
            let oldMarks = gameState.marks(at: position)

            // Set the value
            gameState.setValue(value, at: position)

            // Record action for undo
            let action = GameAction.setValue(
                at: position,
                from: oldValue,
                to: value,
                clearingMarks: oldMarks
            )
            recordAction(action)

            // Update conflicts and check completion
            updateConflicts()
            checkCompletion()

        case let .possibleValues(position, values):
            // Select the cell and set pencil marks to show possible values
            selectCell(at: position)

            // Record old state for undo
            let oldMarks = gameState.marks(at: position)

            // Set pencil marks with possible values
            gameState.setPencilMarks(values, at: position)

            // Record action for undo
            let action = GameAction.setPencilMarks(
                at: position,
                from: oldMarks,
                to: values
            )
            recordAction(action)
        }

        // Clear any error messages
        errorMessage = nil
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
            if isUndo {
                // Restore both value and marks
                if let value = targetValue {
                    gameState.setValue(value, at: action.position)
                }
                if !targetMarks.isEmpty {
                    gameState.setPencilMarks(targetMarks, at: action.position)
                }
            } else {
                // Redo: actually clear the cell
                gameState.clearCell(at: action.position)
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
        let value = gameState.currentGrid[position.row][position.column]
        let isInitial = gameState.puzzle.isPrefilled(at: position)
        let pencilMarks = gameState.marks(at: position)
        let isSelected = gameState.selectedCell == position

        // Check if this cell has validation errors
        let hasError = conflictingPositions.contains(position)

        // Check if this cell should be highlighted
        let isHighlighted = shouldHighlight(position: position)

        // Check if this cell has the same number as the selected cell
        let isSameNumber = shouldMarkAsSameNumber(position: position, value: value)

        // Check if this cell is a neighbor to the selected cell
        let isNeighbor = shouldMarkAsNeighbor(position: position)

        return Cell(
            position: position,
            value: value,
            isInitial: isInitial,
            pencilMarks: pencilMarks,
            isSelected: isSelected,
            hasError: hasError,
            isHighlighted: isHighlighted,
            isSameNumber: isSameNumber,
            isNeighbor: isNeighbor
        )
    }

    // MARK: - Cell Highlighting Logic

    /// Determines if a cell should be highlighted (in same row/column as selected cell)
    /// Uses cached positions for O(1) lookup performance
    /// - Parameter position: The position to check
    /// - Returns: True if the cell should be highlighted
    private func shouldHighlight(position: CellPosition) -> Bool {
        // Use cached set for O(1) lookup instead of computing each time
        cachedHighlightedPositions.contains(position)
    }

    /// Determines if a cell is a neighbor (one of the 8 adjacent cells) to the selected cell
    /// Uses cached positions for O(1) lookup performance
    /// - Parameter position: The position to check
    /// - Returns: True if the cell is one of the 8 adjacent neighbors
    private func shouldMarkAsNeighbor(position: CellPosition) -> Bool {
        // Use cached set for O(1) lookup instead of computing each time
        cachedNeighborPositions.contains(position)
    }

    /// Determines if a cell should be marked as "same number" (matching the selected cell's value)
    /// - Parameters:
    ///   - position: The position to check
    ///   - value: The value at this position
    /// - Returns: True if the cell has the same value as the selected cell
    private func shouldMarkAsSameNumber(position: CellPosition, value: Int?) -> Bool {
        guard let selected = selectedPosition,
              let selectedValue = gameState.currentGrid[selected.row][selected.column],
              let currentValue = value,
              position != selected
        else {
            return false
        }

        return currentValue == selectedValue
    }

    /// Calculate the current sum for a column
    /// - Parameter column: The column index
    /// - Returns: The sum of all values in the column
    func columnSum(for column: Int) -> Int {
        var sum = 0
        for row in 0 ..< gameState.puzzle.rows {
            if let value = gameState.currentGrid[row][column] {
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
            if gameState.currentGrid[row][column] == nil {
                return false
            }
        }
        return true
    }

    /// Calculate the remaining sum needed for a column
    /// - Parameter column: The column index
    /// - Returns: The remaining sum needed (target - current sum)
    func remainingSum(for column: Int) -> Int {
        guard column >= 0, column < gameState.puzzle.columns else { return 0 }
        let target = gameState.puzzle.targetSums[column]
        let current = columnSum(for: column)
        return target - current
    }

    /// Check if placing a number at a position would exceed the column's remaining sum
    /// - Parameters:
    ///   - value: The value to check
    ///   - position: The position to check
    /// - Returns: True if the value would exceed the remaining sum
    func wouldExceedColumnSum(_ value: Int, at position: CellPosition) -> Bool {
        guard gameState.puzzle.isValidPosition(position) else { return false }

        let column = position.column
        let currentValue = gameState.value(at: position)

        // Value 0 is always allowed (it clears the cell)
        if value == 0 {
            return false
        }

        // If replacing with the same value, it doesn't exceed
        if let currentValue, currentValue == value {
            return false
        }

        // Calculate the net change in the column sum
        let netChange: Int = if let currentValue {
            value - currentValue
        } else {
            value
        }

        // Get the remaining sum for the column
        let remaining = remainingSum(for: column)

        // If remaining is 0 and we're replacing with a different value, it would break the exact sum
        if remaining == 0, currentValue != nil {
            return true
        }

        // Check if the net change would exceed the remaining sum
        return netChange > remaining
    }

    // MARK: - Game Reset

    /// Resets the game to a new state
    /// This clears all progress and starts fresh with the new state
    /// - Parameter newState: The new game state to use
    func resetToState(_ newState: GameState) {
        // Stop the current timer
        timer?.invalidate()
        timer = nil
        lastTimerUpdate = nil

        // Clear history
        undoStack.removeAll()
        redoStack.removeAll()

        // Reset state
        gameState = newState
        selectedPosition = newState.selectedCell
        notesMode = newState.notesMode
        elapsedTime = newState.elapsedTime
        conflictingPositions.removeAll()

        // Clear cached positions
        cachedNeighborPositions.removeAll()
        cachedHighlightedPositions.removeAll()

        // Update cached positions for the new selection
        updateCachedPositions(for: newState.selectedCell)

        // Start timer if game is not paused or completed
        if !newState.isPaused, !newState.isCompleted {
            startTimer()
        }
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
