//
//  PuzzleGenerator.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation

/// Service responsible for generating random valid Tenner Grid puzzles
struct PuzzleGenerator {
    private let solver = PuzzleSolver()
    private let validationService = ValidationService()

    /// Generates a random valid completed Tenner Grid
    /// - Parameters:
    ///   - rows: Number of rows in the grid (5-10)
    ///   - columns: Number of columns in the grid (5-10)
    ///   - seed: Optional seed for deterministic generation (useful for daily puzzles)
    /// - Returns: A completed grid as a 2D array of integers, or nil if generation fails
    func generateCompletedGrid(rows: Int, columns: Int, seed: UInt64? = nil) -> [[Int]]? {
        // Validate dimensions
        guard rows >= 5, rows <= 10 else { return nil }
        guard columns >= 5, columns <= 10 else { return nil }

        // Create seeded random number generator if seed provided
        var rng: RandomNumberGenerator = seed.map { SeededRandomNumberGenerator(seed: $0) } ?? SystemRandomNumberGenerator()

        // Initialize empty grid
        var grid: [[Int?]] = Array(repeating: Array(repeating: nil, count: columns), count: rows)

        // Generate target sums first to constrain the generation
        // Each column sum should be reasonable (between rows*0 and rows*9)
        // We'll use random but achievable sums
        var targetSums: [Int] = []
        for _ in 0 ..< columns {
            // Generate a sum between (rows * 2) and (rows * 7) for good variety
            // This ensures we don't get all 0s or all 9s which would be too easy
            let minSum = rows * 2
            let maxSum = rows * 7
            let targetSum = Int.random(in: minSum ... maxSum, using: &rng)
            targetSums.append(targetSum)
        }

        // Try to fill the grid row by row with backtracking
        if fillGridRecursively(
            grid: &grid,
            row: 0,
            column: 0,
            rows: rows,
            columns: columns,
            targetSums: targetSums,
            rng: &rng
        ) {
            // Convert [[Int?]] to [[Int]]
            return grid.map { row in
                row.compactMap { $0 }
            }
        }

        // If generation failed, return nil
        return nil
    }

    /// Recursively fills the grid using backtracking with randomization
    /// - Parameters:
    ///   - grid: The current grid state
    ///   - row: Current row position
    ///   - column: Current column position
    ///   - rows: Total number of rows
    ///   - columns: Total number of columns
    ///   - targetSums: Target sums for each column
    ///   - rng: Random number generator for deterministic behavior
    /// - Returns: True if grid was successfully filled, false otherwise
    private func fillGridRecursively(
        grid: inout [[Int?]],
        row: Int,
        column: Int,
        rows: Int,
        columns: Int,
        targetSums: [Int],
        rng: inout RandomNumberGenerator
    ) -> Bool {
        // Base case: we've filled all cells
        if row >= rows {
            // Verify all column sums match targets
            return verifyColumnSums(grid: grid, targetSums: targetSums, rows: rows, columns: columns)
        }

        // Calculate next position
        let nextColumn = (column + 1) % columns
        let nextRow = nextColumn == 0 ? row + 1 : row

        let position = CellPosition(row: row, column: column)

        // Get shuffled list of possible values (0-9) for randomness
        var possibleValues = Array(0 ... 9).shuffled(using: &rng)

        // If this is the last row, prioritize values that help reach column sum targets
        if row == rows - 1 {
            // Calculate required value to reach target sum
            var currentSum = 0
            for r in 0 ..< row {
                if let val = grid[r][column] {
                    currentSum += val
                }
            }

            let requiredValue = targetSums[column] - currentSum

            // If required value is valid (0-9), try it first
            if requiredValue >= 0, requiredValue <= 9 {
                possibleValues.removeAll { $0 == requiredValue }
                possibleValues.insert(requiredValue, at: 0)
            }
        }

        // Try each possible value
        for value in possibleValues {
            // Check if value can be placed according to Tenner Grid rules
            if canPlaceValue(
                value: value,
                at: position,
                in: grid,
                rows: rows,
                columns: columns
            ) {
                // Check column sum constraint
                if isColumnSumPossible(
                    column: column,
                    currentRow: row,
                    value: value,
                    in: grid,
                    targetSum: targetSums[column],
                    rows: rows
                ) {
                    // Place the value
                    grid[row][column] = value

                    // Recursively try to fill the rest
                    if fillGridRecursively(
                        grid: &grid,
                        row: nextRow,
                        column: nextColumn,
                        rows: rows,
                        columns: columns,
                        targetSums: targetSums,
                        rng: &rng
                    ) {
                        return true
                    }

                    // Backtrack
                    grid[row][column] = nil
                }
            }
        }

        // No valid value found for this cell
        return false
    }

    /// Checks if a value can be placed at a position according to Tenner Grid rules
    /// - Parameters:
    ///   - value: The value to place
    ///   - position: The position to place it
    ///   - grid: The current grid state
    ///   - rows: Total number of rows
    ///   - columns: Total number of columns
    /// - Returns: True if the value can be placed, false otherwise
    private func canPlaceValue(
        value: Int,
        at position: CellPosition,
        in grid: [[Int?]],
        rows: Int,
        columns: Int
    ) -> Bool {
        // Check no adjacent duplicates (including diagonals)
        let adjacentOffsets = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1), (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]

        for (rowOffset, colOffset) in adjacentOffsets {
            let adjacentRow = position.row + rowOffset
            let adjacentCol = position.column + colOffset

            // Check bounds
            guard adjacentRow >= 0, adjacentRow < rows,
                  adjacentCol >= 0, adjacentCol < columns
            else {
                continue
            }

            // Check if adjacent cell has the same value
            if let adjacentValue = grid[adjacentRow][adjacentCol],
               adjacentValue == value
            {
                return false
            }
        }

        // Check no row duplicates
        for col in 0 ..< columns {
            if col == position.column {
                continue
            }

            if let existingValue = grid[position.row][col],
               existingValue == value
            {
                return false
            }
        }

        return true
    }

    /// Checks if placing a value in a column can still lead to reaching the target sum
    /// - Parameters:
    ///   - column: The column index
    ///   - currentRow: The row where we're placing the value
    ///   - value: The value to place
    ///   - grid: The current grid state
    ///   - targetSum: The target sum for the column
    ///   - rows: Total number of rows
    /// - Returns: True if the column sum can still reach the target, false otherwise
    private func isColumnSumPossible(
        column: Int,
        currentRow: Int,
        value: Int,
        in grid: [[Int?]],
        targetSum: Int,
        rows: Int
    ) -> Bool {
        // Calculate current sum including the value we're about to place
        var currentSum = value
        for row in 0 ..< currentRow {
            if let val = grid[row][column] {
                currentSum += val
            }
        }

        let remainingRows = rows - currentRow - 1

        // If this is the last row, sum must exactly equal target
        if remainingRows == 0 {
            return currentSum == targetSum
        }

        // Check if target is still achievable with remaining rows
        let maxPossible = currentSum + (remainingRows * 9)
        let minPossible = currentSum + (remainingRows * 0)

        return targetSum >= minPossible && targetSum <= maxPossible
    }

    /// Verifies that all column sums match their target sums
    /// - Parameters:
    ///   - grid: The completed grid
    ///   - targetSums: Target sums for each column
    ///   - rows: Total number of rows
    ///   - columns: Total number of columns
    /// - Returns: True if all column sums match targets, false otherwise
    private func verifyColumnSums(
        grid: [[Int?]],
        targetSums: [Int],
        rows: Int,
        columns: Int
    ) -> Bool {
        for col in 0 ..< columns {
            var sum = 0
            for row in 0 ..< rows {
                guard let value = grid[row][col] else {
                    return false
                }
                sum += value
            }

            if sum != targetSums[col] {
                return false
            }
        }

        return true
    }

    /// Removes cells from a completed grid based on difficulty while maintaining a unique solution
    /// - Parameters:
    ///   - completedGrid: A fully solved grid
    ///   - targetSums: Target sums for each column
    ///   - difficulty: The desired difficulty level
    ///   - seed: Optional seed for deterministic generation
    /// - Returns: A puzzle grid with cells removed, or nil if removal fails
    func removeCells(
        from completedGrid: [[Int]],
        targetSums: [Int],
        difficulty: Difficulty,
        seed: UInt64? = nil
    ) -> [[Int?]]? {
        guard !completedGrid.isEmpty, !completedGrid[0].isEmpty else { return nil }

        let rows = completedGrid.count
        let columns = completedGrid[0].count

        // Create seeded random number generator if seed provided
        var rng: RandomNumberGenerator = seed.map { SeededRandomNumberGenerator(seed: $0) } ?? SystemRandomNumberGenerator()

        // Convert completed grid to optional grid (all cells filled initially)
        var puzzleGrid: [[Int?]] = completedGrid.map { row in
            row.map { Int?($0) }
        }

        // Calculate total cells and target number of cells to remove
        let totalCells = rows * columns
        let cellsToRemove = Int(Double(totalCells) * (1.0 - difficulty.prefilledPercentage))

        // Create list of all cell positions
        var cellPositions: [CellPosition] = []
        for row in 0 ..< rows {
            for column in 0 ..< columns {
                cellPositions.append(CellPosition(row: row, column: column))
            }
        }

        // Shuffle positions for random removal order
        cellPositions.shuffle(using: &rng)

        // Create a temporary puzzle for testing uniqueness
        let temporaryPuzzle = TennerGridPuzzle(
            id: UUID(),
            rows: rows,
            columns: columns,
            difficulty: difficulty,
            targetSums: targetSums,
            initialGrid: puzzleGrid,
            solution: completedGrid
        )

        var removedCount = 0
        var attemptedPositions: Set<CellPosition> = []

        // Try to remove cells one by one
        for position in cellPositions {
            // Skip if already attempted
            guard !attemptedPositions.contains(position) else { continue }
            attemptedPositions.insert(position)

            // Skip if cell is already empty
            guard puzzleGrid[position.row][position.column] != nil else { continue }

            // Save the current value
            let originalValue = puzzleGrid[position.row][position.column]

            // Remove the cell
            puzzleGrid[position.row][position.column] = nil

            // Create updated puzzle for testing
            let testPuzzle = TennerGridPuzzle(
                id: temporaryPuzzle.id,
                rows: rows,
                columns: columns,
                difficulty: difficulty,
                targetSums: targetSums,
                initialGrid: puzzleGrid,
                solution: completedGrid
            )

            // Check if puzzle still has unique solution
            if solver.hasUniqueSolution(puzzle: testPuzzle) {
                // Successfully removed - keep the cell empty
                removedCount += 1

                // If we've removed enough cells, we're done
                if removedCount >= cellsToRemove {
                    break
                }
            } else {
                // Removing this cell creates multiple solutions - restore it
                puzzleGrid[position.row][position.column] = originalValue
            }
        }

        // Check if we removed at least some cells (accept puzzles that are close to target)
        // We allow puzzles with at least 80% of target removed cells
        let minimumRemoved = Int(Double(cellsToRemove) * 0.8)
        guard removedCount >= minimumRemoved else {
            return nil
        }

        return puzzleGrid
    }
}

// MARK: - Seeded Random Number Generator

/// A seeded random number generator for deterministic random generation
/// This is useful for daily puzzles where we want the same seed to always generate the same puzzle
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // Linear Congruential Generator (LCG) algorithm
        // Using parameters from Numerical Recipes
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
