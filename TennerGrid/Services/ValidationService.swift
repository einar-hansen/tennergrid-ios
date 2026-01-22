//
//  ValidationService.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation

/// Service responsible for validating Tenner Grid puzzle rules
struct ValidationService {
    /// Validates if placing a number at a position is valid according to Tenner Grid rules
    /// - Parameters:
    ///   - value: The number to place (0-9)
    ///   - position: The position where the number will be placed
    ///   - grid: The current grid state (2D array where nil represents empty cells)
    ///   - puzzle: The puzzle definition (contains dimensions)
    /// - Returns: True if the placement is valid, false if it violates any rule
    func isValidPlacement(
        value: Int,
        at position: CellPosition,
        in grid: [[Int?]],
        puzzle: TennerGridPuzzle
    ) -> Bool {
        // Check if value is in valid range
        guard value >= 0, value <= 9 else { return false }

        // Check if position is within bounds
        guard puzzle.isValidPosition(position) else { return false }

        // Check for adjacent duplicates (including diagonals)
        if hasAdjacentDuplicate(value: value, at: position, in: grid, puzzle: puzzle) {
            return false
        }

        // Check for row duplicates
        if hasRowDuplicate(value: value, at: position, in: grid, puzzle: puzzle) {
            return false
        }

        return true
    }

    /// Detects all conflicts for a cell at the given position
    /// - Parameters:
    ///   - position: The position to check for conflicts
    ///   - grid: The current grid state
    ///   - puzzle: The puzzle definition
    /// - Returns: Array of positions that conflict with the cell at the given position
    func detectConflicts(
        at position: CellPosition,
        in grid: [[Int?]],
        puzzle: TennerGridPuzzle
    ) -> [CellPosition] {
        guard puzzle.isValidPosition(position) else { return [] }
        guard let value = grid[position.row][position.column] else { return [] }

        var conflicts: [CellPosition] = []

        // Check adjacent cells for duplicates
        let adjacentPositions = position.adjacentPositions(maxRows: puzzle.rows, maxColumns: puzzle.columns)
        for adjacentPos in adjacentPositions {
            if let adjacentValue = grid[adjacentPos.row][adjacentPos.column],
               adjacentValue == value
            {
                conflicts.append(adjacentPos)
            }
        }

        // Check row for duplicates
        let rowPositions = position.rowPositions(maxColumns: puzzle.columns)
        for rowPos in rowPositions {
            if let rowValue = grid[rowPos.row][rowPos.column],
               rowValue == value
            {
                conflicts.append(rowPos)
            }
        }

        return conflicts
    }

    /// Validates if a column sum matches the target sum
    /// - Parameters:
    ///   - column: The column index to validate
    ///   - grid: The current grid state
    ///   - puzzle: The puzzle definition
    /// - Returns: True if the column sum equals the target, false otherwise or if column is incomplete
    func isColumnSumValid(
        column: Int,
        in grid: [[Int?]],
        puzzle: TennerGridPuzzle
    ) -> Bool {
        guard column >= 0, column < puzzle.columns else { return false }
        guard column < puzzle.targetSums.count else { return false }

        var sum = 0

        // Calculate the sum of all values in the column
        for row in 0 ..< puzzle.rows {
            guard let value = grid[row][column] else {
                // Column is incomplete
                return false
            }
            sum += value
        }

        return sum == puzzle.targetSums[column]
    }

    /// Checks if the entire puzzle is correctly completed
    /// - Parameters:
    ///   - grid: The current grid state
    ///   - puzzle: The puzzle definition
    /// - Returns: True if the puzzle is complete and correct, false otherwise
    func isPuzzleComplete(
        grid: [[Int?]],
        puzzle: TennerGridPuzzle
    ) -> Bool {
        // Check if all cells are filled
        for row in grid {
            for value in row {
                if value == nil {
                    return false
                }
            }
        }

        // Check all cells for conflicts
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                let conflicts = detectConflicts(at: position, in: grid, puzzle: puzzle)
                if !conflicts.isEmpty {
                    return false
                }
            }
        }

        // Check all column sums
        for col in 0 ..< puzzle.columns {
            if !isColumnSumValid(column: col, in: grid, puzzle: puzzle) {
                return false
            }
        }

        return true
    }

    // MARK: - Private Helper Methods

    /// Checks if placing a value would create an adjacent duplicate
    private func hasAdjacentDuplicate(
        value: Int,
        at position: CellPosition,
        in grid: [[Int?]],
        puzzle: TennerGridPuzzle
    ) -> Bool {
        let adjacentPositions = position.adjacentPositions(
            maxRows: puzzle.rows,
            maxColumns: puzzle.columns
        )

        for adjacentPos in adjacentPositions {
            if let adjacentValue = grid[adjacentPos.row][adjacentPos.column],
               adjacentValue == value
            {
                return true
            }
        }

        return false
    }

    /// Checks if placing a value would create a row duplicate
    private func hasRowDuplicate(
        value: Int,
        at position: CellPosition,
        in grid: [[Int?]],
        puzzle: TennerGridPuzzle
    ) -> Bool {
        let rowPositions = position.rowPositions(maxColumns: puzzle.columns)

        for rowPos in rowPositions {
            if let rowValue = grid[rowPos.row][rowPos.column],
               rowValue == value
            {
                return true
            }
        }

        return false
    }
}
