//
//  TennerGridPuzzle.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation

/// Represents a complete Tenner Grid puzzle with initial state and solution
struct TennerGridPuzzle: Codable, Identifiable {
    /// Unique identifier for the puzzle
    let id: UUID

    /// Number of columns in the puzzle (typically 5-10)
    let columns: Int

    /// Number of rows in the puzzle (typically 5-10)
    let rows: Int

    /// Difficulty level of the puzzle
    let difficulty: Difficulty

    /// Target sums for each column
    /// Array of integers where each element represents the sum that column should add up to
    let targetSums: [Int]

    /// Initial grid state with pre-filled numbers
    /// 2D array where nil represents an empty cell, and Int represents a pre-filled cell
    /// Format: grid[row][column]
    let initialGrid: [[Int?]]

    /// Complete solution to the puzzle
    /// 2D array with all cells filled with correct values
    /// Format: solution[row][column]
    let solution: [[Int]]

    /// Date when the puzzle was created
    let createdAt: Date

    /// Creates a new Tenner Grid puzzle
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - columns: Number of columns in the puzzle
    ///   - rows: Number of rows in the puzzle
    ///   - difficulty: Difficulty level
    ///   - targetSums: Array of target sums for each column
    ///   - initialGrid: 2D array with pre-filled cells (nil for empty)
    ///   - solution: 2D array with complete solution
    ///   - createdAt: Creation date (defaults to current date)
    init(
        id: UUID = UUID(),
        columns: Int,
        rows: Int,
        difficulty: Difficulty,
        targetSums: [Int],
        initialGrid: [[Int?]],
        solution: [[Int]],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.columns = columns
        self.rows = rows
        self.difficulty = difficulty
        self.targetSums = targetSums
        self.initialGrid = initialGrid
        self.solution = solution
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension TennerGridPuzzle {
    /// Total number of cells in the puzzle
    var totalCells: Int {
        rows * columns
    }

    /// Number of pre-filled cells in the initial grid
    var prefilledCount: Int {
        initialGrid.flatMap { $0 }.compactMap { $0 }.count
    }

    /// Number of empty cells that need to be filled
    var emptyCellCount: Int {
        totalCells - prefilledCount
    }

    /// Percentage of cells that are pre-filled
    var prefilledPercentage: Double {
        guard totalCells > 0 else { return 0 }
        return Double(prefilledCount) / Double(totalCells)
    }
}

// MARK: - Validation

extension TennerGridPuzzle {
    /// Validates the puzzle structure and data
    /// - Returns: True if the puzzle is valid
    func isValid() -> Bool {
        // Check column and row counts are in valid range
        // Tenner Grid uses exactly 10 columns, rows can be 3-7
        guard columns == 10 else { return false }
        guard rows >= 3, rows <= 7 else { return false }

        // Check targetSums array has correct length
        guard targetSums.count == columns else { return false }

        // Check all target sums are positive
        guard targetSums.allSatisfy({ $0 > 0 }) else { return false }

        // Check initialGrid has correct dimensions
        guard initialGrid.count == rows else { return false }
        guard initialGrid.allSatisfy({ $0.count == columns }) else { return false }

        // Check solution has correct dimensions
        guard solution.count == rows else { return false }
        guard solution.allSatisfy({ $0.count == columns }) else { return false }

        // Check all pre-filled cells in initialGrid match the solution
        for row in 0 ..< rows {
            for col in 0 ..< columns {
                if let initialValue = initialGrid[row][col] {
                    guard initialValue == solution[row][col] else { return false }
                }
            }
        }

        // Check all values in solution are in valid range (0-9)
        for row in solution {
            for value in row {
                guard value >= 0, value <= 9 else { return false }
            }
        }

        return true
    }
}

// MARK: - Grid Access Helpers

extension TennerGridPuzzle {
    /// Gets the initial value at a specific position
    /// - Parameter position: The cell position
    /// - Returns: The initial value (nil if empty, Int if pre-filled)
    func initialValue(at position: CellPosition) -> Int? {
        guard isValidPosition(position) else { return nil }
        return initialGrid[position.row][position.column]
    }

    /// Gets the solution value at a specific position
    /// - Parameter position: The cell position
    /// - Returns: The correct solution value
    func solutionValue(at position: CellPosition) -> Int? {
        guard isValidPosition(position) else { return nil }
        return solution[position.row][position.column]
    }

    /// Checks if a position is within the puzzle bounds
    /// - Parameter position: The position to check
    /// - Returns: True if the position is valid
    func isValidPosition(_ position: CellPosition) -> Bool {
        position.row >= 0 && position.row < rows &&
            position.column >= 0 && position.column < columns
    }

    /// Checks if a cell is pre-filled in the initial grid
    /// - Parameter position: The cell position
    /// - Returns: True if the cell is pre-filled
    func isPrefilled(at position: CellPosition) -> Bool {
        initialValue(at: position) != nil
    }
}

// MARK: - Equatable

extension TennerGridPuzzle: Equatable {
    /// Puzzles are equal if they have the same ID
    static func == (lhs: TennerGridPuzzle, rhs: TennerGridPuzzle) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CustomStringConvertible

extension TennerGridPuzzle: CustomStringConvertible {
    var description: String {
        """
        TennerGridPuzzle(
            id: \(id),
            size: \(columns)x\(rows),
            difficulty: \(difficulty.displayName),
            prefilled: \(prefilledCount)/\(totalCells) (\(String(format: "%.1f", prefilledPercentage * 100))%),
            targetSums: \(targetSums)
        )
        """
    }
}
