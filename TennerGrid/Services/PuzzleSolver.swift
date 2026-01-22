//
//  PuzzleSolver.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation

/// Service responsible for solving Tenner Grid puzzles using backtracking algorithm
struct PuzzleSolver {
    private let validationService = ValidationService()

    /// Solves a Tenner Grid puzzle using backtracking algorithm
    /// - Parameters:
    ///   - puzzle: The puzzle to solve
    ///   - initialGrid: The initial grid state (optional, defaults to puzzle's initial grid)
    /// - Returns: The solved grid if a solution exists, nil if no solution is found
    func solve(puzzle: TennerGridPuzzle, initialGrid: [[Int?]]? = nil) -> [[Int]]? {
        var grid = initialGrid ?? puzzle.initialGrid

        // Validate dimensions match
        guard grid.count == puzzle.rows,
              grid.allSatisfy({ $0.count == puzzle.columns })
        else {
            return nil
        }

        guard solveBacktrack(grid: &grid, puzzle: puzzle) else {
            return nil
        }

        // Convert [[Int?]] to [[Int]] - we know all cells are filled after successful solve
        return grid.map { row in
            row.compactMap { $0 }
        }
    }

    /// Recursive backtracking algorithm to solve the puzzle with constraint propagation
    /// - Parameters:
    ///   - grid: The current grid state (will be modified in place)
    ///   - puzzle: The puzzle definition
    /// - Returns: True if solution is found, false otherwise
    private func solveBacktrack(grid: inout [[Int?]], puzzle: TennerGridPuzzle) -> Bool {
        // Find next empty cell using MRV heuristic
        guard let position = findNextEmptyCell(in: grid, puzzle: puzzle) else {
            // No empty cells left - check if solution is valid
            return validationService.isPuzzleComplete(grid: grid, puzzle: puzzle)
        }

        // Get possible values using constraint propagation
        let possibleValues = getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Early termination if no valid values (constraint propagation detected impossibility)
        guard !possibleValues.isEmpty else {
            return false
        }

        // Try each possible value (already filtered by constraints)
        for value in possibleValues.sorted() {
            // Place the value
            grid[position.row][position.column] = value

            // Forward checking: verify all adjacent cells still have at least one possible value
            if forwardCheck(grid: grid, changedPosition: position, puzzle: puzzle) {
                // Recursively try to solve the rest
                if solveBacktrack(grid: &grid, puzzle: puzzle) {
                    return true
                }
            }

            // Backtrack - remove the value
            grid[position.row][position.column] = nil
        }

        // No valid value found for this cell
        return false
    }

    /// Forward checking: verifies that placing a value doesn't eliminate all possibilities for adjacent cells
    /// This is an advanced constraint propagation technique
    /// - Parameters:
    ///   - grid: The current grid state
    ///   - changedPosition: The position that was just filled
    ///   - puzzle: The puzzle definition
    /// - Returns: True if forward check passes (all empty neighbors still have valid values), false otherwise
    private func forwardCheck(grid: [[Int?]], changedPosition: CellPosition, puzzle: TennerGridPuzzle) -> Bool {
        // Check all cells in the same row
        for col in 0 ..< puzzle.columns {
            let pos = CellPosition(row: changedPosition.row, column: col)
            if grid[pos.row][pos.column] == nil {
                let possibleValues = getPossibleValues(for: pos, in: grid, puzzle: puzzle)
                if possibleValues.isEmpty {
                    return false
                }
            }
        }

        // Check all adjacent cells (8 neighbors)
        let adjacentOffsets = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1), (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]

        for (rowOffset, colOffset) in adjacentOffsets {
            let neighborRow = changedPosition.row + rowOffset
            let neighborCol = changedPosition.column + colOffset

            // Check bounds
            guard neighborRow >= 0, neighborRow < puzzle.rows,
                  neighborCol >= 0, neighborCol < puzzle.columns
            else {
                continue
            }

            let neighborPos = CellPosition(row: neighborRow, column: neighborCol)

            // If neighbor is empty, check if it still has possible values
            if grid[neighborRow][neighborCol] == nil {
                let possibleValues = getPossibleValues(for: neighborPos, in: grid, puzzle: puzzle)
                if possibleValues.isEmpty {
                    return false
                }
            }
        }

        return true
    }

    /// Finds the next empty cell in the grid using MRV (Minimum Remaining Values) heuristic
    /// This constraint propagation optimization selects the cell with the fewest possible valid values
    /// - Parameters:
    ///   - grid: The current grid state
    ///   - puzzle: The puzzle definition
    /// - Returns: Position of the next empty cell, or nil if grid is full
    private func findNextEmptyCell(in grid: [[Int?]], puzzle: TennerGridPuzzle) -> CellPosition? {
        var bestCell: CellPosition?
        var minPossibleValues = Int.max

        for row in 0 ..< puzzle.rows {
            for column in 0 ..< puzzle.columns {
                if grid[row][column] == nil {
                    let position = CellPosition(row: row, column: column)
                    let possibleValues = getPossibleValues(for: position, in: grid, puzzle: puzzle)

                    // If no possible values, this path is invalid - return immediately
                    if possibleValues.isEmpty {
                        return position
                    }

                    // Select cell with minimum remaining values (MRV heuristic)
                    if possibleValues.count < minPossibleValues {
                        minPossibleValues = possibleValues.count
                        bestCell = position
                    }
                }
            }
        }

        return bestCell
    }

    /// Gets all possible valid values for a cell position
    /// This is a key part of constraint propagation - we precompute which values are valid
    /// - Parameters:
    ///   - position: The cell position to check
    ///   - grid: The current grid state
    ///   - puzzle: The puzzle definition
    /// - Returns: Set of valid values (0-9) that can be placed at this position
    func getPossibleValues(for position: CellPosition, in grid: [[Int?]], puzzle: TennerGridPuzzle) -> Set<Int> {
        var possibleValues: Set<Int> = []

        for value in 0 ... 9 {
            if validationService.isValidPlacement(
                value: value,
                at: position,
                in: grid,
                puzzle: puzzle
            ) {
                // Additional check: would placing this value make the column sum impossible?
                var testGrid = grid
                testGrid[position.row][position.column] = value
                if canColumnSumBeReached(column: position.column, in: testGrid, puzzle: puzzle) {
                    possibleValues.insert(value)
                }
            }
        }

        return possibleValues
    }

    /// Constraint propagation: checks if a column sum can still reach the target
    /// This is an early pruning optimization to avoid exploring invalid branches
    /// - Parameters:
    ///   - column: The column index to check
    ///   - grid: The current grid state
    ///   - puzzle: The puzzle definition
    /// - Returns: True if the column sum can potentially reach the target, false if it's impossible
    private func canColumnSumBeReached(column: Int, in grid: [[Int?]], puzzle: TennerGridPuzzle) -> Bool {
        guard column >= 0, column < puzzle.columns else { return false }
        guard column < puzzle.targetSums.count else { return false }

        let targetSum = puzzle.targetSums[column]
        var currentSum = 0
        var emptyCount = 0

        // Calculate current sum and count empty cells
        for row in 0 ..< puzzle.rows {
            if let value = grid[row][column] {
                currentSum += value
            } else {
                emptyCount += 1
            }
        }

        // If column is fully filled, check if sum matches target
        if emptyCount == 0 {
            return currentSum == targetSum
        }

        // Check if current sum already exceeds target (impossible to reach)
        if currentSum > targetSum {
            return false
        }

        // Check if we can reach the target with remaining cells
        // Minimum possible: current sum + (empty cells * 0)
        // Maximum possible: current sum + (empty cells * 9)
        let remainingSum = targetSum - currentSum
        let maxPossible = emptyCount * 9
        let minPossible = 0

        // The target is reachable if it's within the possible range
        return remainingSum >= minPossible && remainingSum <= maxPossible
    }

    /// Verifies that a puzzle has exactly one unique solution
    /// - Parameters:
    ///   - puzzle: The puzzle to verify
    ///   - initialGrid: The initial grid state (optional, defaults to puzzle's initial grid)
    /// - Returns: True if the puzzle has exactly one unique solution, false if it has zero or multiple solutions
    func hasUniqueSolution(puzzle: TennerGridPuzzle, initialGrid: [[Int?]]? = nil) -> Bool {
        var grid = initialGrid ?? puzzle.initialGrid

        // Validate dimensions match
        guard grid.count == puzzle.rows,
              grid.allSatisfy({ $0.count == puzzle.columns })
        else {
            return false
        }

        var solutionCount = 0
        var firstSolution: [[Int]]?

        // Find all solutions (up to 2 - we only need to know if there's more than one)
        _ = countSolutions(
            grid: &grid,
            puzzle: puzzle,
            maxSolutions: 2,
            foundSolutions: &solutionCount,
            firstSolution: &firstSolution
        )

        return solutionCount == 1
    }

    /// Recursively counts solutions for a puzzle using backtracking
    /// Stops when maxSolutions is reached for efficiency
    /// - Parameters:
    ///   - grid: The current grid state (will be modified in place)
    ///   - puzzle: The puzzle definition
    ///   - maxSolutions: Maximum number of solutions to find before stopping
    ///   - foundSolutions: Counter for number of solutions found (inout)
    ///   - firstSolution: The first solution found (inout, optional)
    /// - Returns: True if should continue searching, false if maxSolutions reached
    private func countSolutions(
        grid: inout [[Int?]],
        puzzle: TennerGridPuzzle,
        maxSolutions: Int,
        foundSolutions: inout Int,
        firstSolution: inout [[Int]]?
    ) -> Bool {
        // If we've found enough solutions, stop searching
        if foundSolutions >= maxSolutions {
            return false
        }

        // Find next empty cell
        guard let position = findNextEmptyCell(in: grid, puzzle: puzzle) else {
            // No empty cells left - check if solution is valid
            if validationService.isPuzzleComplete(grid: grid, puzzle: puzzle) {
                foundSolutions += 1
                if firstSolution == nil {
                    // Store the first solution
                    firstSolution = grid.map { row in
                        row.compactMap { $0 }
                    }
                }
            }
            return foundSolutions < maxSolutions
        }

        // Get possible values using constraint propagation
        let possibleValues = getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Early termination if no valid values
        guard !possibleValues.isEmpty else {
            return true
        }

        // Try each possible value
        for value in possibleValues.sorted() {
            // Place the value
            grid[position.row][position.column] = value

            // Forward checking
            if forwardCheck(grid: grid, changedPosition: position, puzzle: puzzle) {
                // Recursively try to solve the rest
                let shouldContinue = countSolutions(
                    grid: &grid,
                    puzzle: puzzle,
                    maxSolutions: maxSolutions,
                    foundSolutions: &foundSolutions,
                    firstSolution: &firstSolution
                )

                // If we've found enough solutions, stop
                if !shouldContinue {
                    grid[position.row][position.column] = nil
                    return false
                }
            }

            // Backtrack - remove the value
            grid[position.row][position.column] = nil
        }

        return true
    }
}
