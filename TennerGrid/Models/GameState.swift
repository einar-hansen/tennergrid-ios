//
//  GameState.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation

/// Represents the current state of a game in progress
struct GameState: Equatable, Codable {
    /// The puzzle being played
    let puzzle: TennerGridPuzzle

    /// Current state of the grid (2D array of cells)
    /// Format: currentGrid[row][column]
    var currentGrid: [[Int?]]

    /// Selected cell position (nil if no cell is selected)
    var selectedCell: CellPosition?

    /// Whether notes/pencil marks mode is enabled
    var notesMode: Bool

    /// Pencil marks for each cell
    /// Dictionary mapping cell positions to sets of possible values
    var pencilMarks: [CellPosition: Set<Int>]

    /// Total time elapsed in seconds
    var elapsedTime: TimeInterval

    /// Whether the game is currently paused
    var isPaused: Bool

    /// Whether the puzzle has been completed correctly
    var isCompleted: Bool

    /// Date when the game was started
    let startedAt: Date

    /// Date when the game was completed (nil if not completed)
    var completedAt: Date?

    /// Number of hints used in this game
    var hintsUsed: Int

    /// Number of errors made (incorrect placements)
    var errorCount: Int

    /// Creates a new game state from a puzzle
    /// - Parameters:
    ///   - puzzle: The puzzle to play
    ///   - startedAt: When the game was started (defaults to now)
    init(puzzle: TennerGridPuzzle, startedAt: Date = Date()) {
        self.puzzle = puzzle
        currentGrid = puzzle.initialGrid
        selectedCell = nil
        notesMode = false
        pencilMarks = [:]
        elapsedTime = 0
        isPaused = false
        isCompleted = false
        self.startedAt = startedAt
        completedAt = nil
        hintsUsed = 0
        errorCount = 0
    }
}

// MARK: - Computed Properties

extension GameState {
    /// Number of cells filled by the player (excluding initial cells)
    var filledCellCount: Int {
        var count = 0
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                // Count cells that have values and weren't pre-filled
                if currentGrid[row][col] != nil, !puzzle.isPrefilled(at: position) {
                    count += 1
                }
            }
        }
        return count
    }

    /// Number of empty cells remaining
    var emptyCellCount: Int {
        puzzle.emptyCellCount - filledCellCount
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        guard puzzle.emptyCellCount > 0 else { return 1.0 }
        return Double(filledCellCount) / Double(puzzle.emptyCellCount)
    }

    /// Formatted elapsed time string (MM:SS)
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Whether the game can be resumed (was in progress)
    var canResume: Bool {
        !isCompleted && filledCellCount > 0
    }
}

// MARK: - Grid Access

extension GameState {
    /// Gets the current value at a position
    /// - Parameter position: The cell position
    /// - Returns: The current value (nil if empty)
    func value(at position: CellPosition) -> Int? {
        guard puzzle.isValidPosition(position) else { return nil }
        return currentGrid[position.row][position.column]
    }

    /// Gets pencil marks for a cell
    /// - Parameter position: The cell position
    /// - Returns: Set of pencil marks (empty set if none)
    func marks(at position: CellPosition) -> Set<Int> {
        pencilMarks[position] ?? []
    }

    /// Checks if a cell is editable (not pre-filled)
    /// - Parameter position: The cell position
    /// - Returns: True if the cell can be edited
    func isEditable(at position: CellPosition) -> Bool {
        !puzzle.isPrefilled(at: position)
    }

    /// Checks if a cell is empty
    /// - Parameter position: The cell position
    /// - Returns: True if the cell has no value
    func isEmpty(at position: CellPosition) -> Bool {
        value(at: position) == nil
    }
}

// MARK: - Grid Modification

extension GameState {
    /// Sets a value at a position
    /// - Parameters:
    ///   - value: The value to set (nil to clear)
    ///   - position: The cell position
    /// - Returns: A new GameState with the updated value
    mutating func setValue(_ value: Int?, at position: CellPosition) {
        guard puzzle.isValidPosition(position) else { return }
        guard isEditable(at: position) else { return }

        currentGrid[position.row][position.column] = value

        // Clear pencil marks when setting a value
        if value != nil {
            pencilMarks[position] = nil
        }
    }

    /// Sets pencil marks at a position
    /// - Parameters:
    ///   - marks: Set of pencil marks to set
    ///   - position: The cell position
    mutating func setPencilMarks(_ marks: Set<Int>, at position: CellPosition) {
        guard puzzle.isValidPosition(position) else { return }
        guard isEditable(at: position) else { return }
        guard isEmpty(at: position) else { return } // Only set marks on empty cells

        if marks.isEmpty {
            pencilMarks[position] = nil
        } else {
            pencilMarks[position] = marks
        }
    }

    /// Toggles a pencil mark at a position
    /// - Parameters:
    ///   - mark: The mark to toggle (0-9)
    ///   - position: The cell position
    mutating func togglePencilMark(_ mark: Int, at position: CellPosition) {
        guard mark >= 0, mark <= 9 else { return }
        guard puzzle.isValidPosition(position) else { return }
        guard isEditable(at: position) else { return }
        guard isEmpty(at: position) else { return }

        var marks = marks(at: position)
        if marks.contains(mark) {
            marks.remove(mark)
        } else {
            marks.insert(mark)
        }
        setPencilMarks(marks, at: position)
    }

    /// Clears a cell (value and pencil marks)
    /// - Parameter position: The cell position
    mutating func clearCell(at position: CellPosition) {
        setValue(nil, at: position)
        setPencilMarks([], at: position)
    }
}

// MARK: - Selection Management

extension GameState {
    /// Selects a cell
    /// - Parameter position: The position to select (nil to clear selection)
    mutating func selectCell(at position: CellPosition?) {
        selectedCell = position
    }

    /// Checks if a position is currently selected
    /// - Parameter position: The position to check
    /// - Returns: True if the position is selected
    func isSelected(_ position: CellPosition) -> Bool {
        selectedCell == position
    }
}

// MARK: - Game Flow

extension GameState {
    /// Pauses the game
    mutating func pause() {
        isPaused = true
    }

    /// Resumes the game
    mutating func resume() {
        isPaused = false
    }

    /// Adds elapsed time
    /// - Parameter interval: Time interval to add in seconds
    mutating func addTime(_ interval: TimeInterval) {
        elapsedTime += interval
    }

    /// Marks the game as completed
    mutating func complete() {
        isCompleted = true
        completedAt = Date()
        isPaused = true
        selectedCell = nil
    }

    /// Increments hint usage count
    mutating func useHint() {
        hintsUsed += 1
    }

    /// Increments error count
    mutating func recordError() {
        errorCount += 1
    }
}

// MARK: - Validation

extension GameState {
    /// Checks if the current grid matches the solution
    /// - Returns: True if all filled cells match the solution
    func checkSolution() -> Bool {
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                if let currentValue = currentGrid[row][col] {
                    if currentValue != puzzle.solution[row][col] {
                        return false
                    }
                }
            }
        }
        return true
    }

    /// Checks if the puzzle is completely filled
    /// - Returns: True if all cells have values
    func isGridComplete() -> Bool {
        for row in currentGrid {
            for cell in row {
                if cell == nil {
                    return false
                }
            }
        }
        return true
    }

    /// Checks if the puzzle is correctly completed
    /// - Returns: True if grid is complete and matches solution
    func isCorrectlyCompleted() -> Bool {
        isGridComplete() && checkSolution()
    }
}

// MARK: - Factory Methods

extension GameState {
    /// Creates a new game from a puzzle
    /// - Parameter puzzle: The puzzle to play
    /// - Returns: A new GameState
    static func new(from puzzle: TennerGridPuzzle) -> GameState {
        GameState(puzzle: puzzle)
    }
}

// MARK: - CustomStringConvertible

extension GameState: CustomStringConvertible {
    var description: String {
        """
        GameState(
            puzzle: \(puzzle.difficulty.displayName) \(puzzle.rows)x\(puzzle.columns),
            progress: \(filledCellCount)/\(puzzle.emptyCellCount) (\(String(format: "%.1f", progress * 100))%),
            time: \(formattedTime),
            hints: \(hintsUsed),
            errors: \(errorCount),
            paused: \(isPaused),
            completed: \(isCompleted)
        )
        """
    }
}
