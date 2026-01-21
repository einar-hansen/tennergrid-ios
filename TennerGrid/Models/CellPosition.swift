//
//  CellPosition.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation

/// Represents a position in the Tenner Grid puzzle
struct CellPosition: Equatable, Hashable, Codable {
    /// The row index (0-based)
    let row: Int

    /// The column index (0-based)
    let column: Int

    /// Creates a new cell position
    /// - Parameters:
    ///   - row: The row index (0-based)
    ///   - column: The column index (0-based)
    init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    /// Returns all adjacent positions (including diagonals)
    /// - Parameters:
    ///   - maxRows: Maximum number of rows in the grid
    ///   - maxColumns: Maximum number of columns in the grid
    /// - Returns: Array of adjacent cell positions
    func adjacentPositions(maxRows: Int, maxColumns: Int) -> [CellPosition] {
        var adjacent: [CellPosition] = []

        // Define all 8 possible adjacent positions (including diagonals)
        let offsets = [
            (-1, -1), (-1, 0), (-1, 1), // Top-left, top, top-right
            (0, -1), (0, 1), // Left, right
            (1, -1), (1, 0), (1, 1), // Bottom-left, bottom, bottom-right
        ]

        for (rowOffset, colOffset) in offsets {
            let newRow = row + rowOffset
            let newCol = column + colOffset

            // Check if the new position is within bounds
            if newRow >= 0, newRow < maxRows,
               newCol >= 0, newCol < maxColumns
            {
                adjacent.append(CellPosition(row: newRow, column: newCol))
            }
        }

        return adjacent
    }

    /// Returns positions in the same row
    /// - Parameter maxColumns: Maximum number of columns in the grid
    /// - Returns: Array of positions in the same row (excluding self)
    func rowPositions(maxColumns: Int) -> [CellPosition] {
        (0 ..< maxColumns)
            .filter { $0 != column }
            .map { CellPosition(row: row, column: $0) }
    }

    /// Returns positions in the same column
    /// - Parameter maxRows: Maximum number of rows in the grid
    /// - Returns: Array of positions in the same column (excluding self)
    func columnPositions(maxRows: Int) -> [CellPosition] {
        (0 ..< maxRows)
            .filter { $0 != row }
            .map { CellPosition(row: $0, column: column) }
    }

    /// Checks if this position is adjacent to another position (including diagonals)
    /// - Parameter other: The other position to check
    /// - Returns: True if positions are adjacent
    func isAdjacent(to other: CellPosition) -> Bool {
        let rowDiff = abs(row - other.row)
        let colDiff = abs(column - other.column)

        // Adjacent if within 1 row and 1 column (but not the same position)
        return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0)
    }
}

// MARK: - CustomStringConvertible

extension CellPosition: CustomStringConvertible {
    var description: String {
        "(\(row), \(column))"
    }
}
