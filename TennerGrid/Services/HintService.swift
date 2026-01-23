import Foundation

/// Type of hint provided to the player
enum HintType {
    /// A cell that can be logically determined
    case logicalMove(position: CellPosition, value: Int)
    /// The correct value for the selected cell
    case revealValue(position: CellPosition, value: Int)
    /// All possible valid values for a cell
    case possibleValues(position: CellPosition, values: Set<Int>)
}

/// Service responsible for providing hints during gameplay
struct HintService {
    private let solver = PuzzleSolver()
    private let validationService = ValidationService()

    /// Identifies the next cell(s) that can be logically filled
    /// This finds cells where there's only one possible value (naked singles)
    /// or uses other logical deduction techniques
    /// - Parameters:
    ///   - gameState: The current game state
    /// - Returns: Position and value of the next logical move, or nil if no logical move exists
    func identifyNextCell(in gameState: GameState) -> (position: CellPosition, value: Int)? {
        // Use the solver's findNextLogicalMove method to identify cells that can be
        // determined through logical deduction without guessing
        solver.findNextLogicalMove(in: gameState.currentGrid, puzzle: gameState.puzzle)
    }

    /// Gets all possible valid values for a selected cell
    /// Returns values that don't violate any Tenner Grid rules
    /// - Parameters:
    ///   - position: The cell position to check
    ///   - gameState: The current game state
    /// - Returns: Set of valid values (0-9) that can be placed at this position
    func getPossibleValues(for position: CellPosition, in gameState: GameState) -> Set<Int> {
        // Check if position is valid and editable
        guard gameState.puzzle.isValidPosition(position) else { return [] }
        guard gameState.isEditable(at: position) else { return [] }

        // If cell is already filled, return empty set
        guard gameState.isEmpty(at: position) else { return [] }

        // Use solver's constraint propagation to get possible values
        return solver.getPossibleValues(
            for: position,
            in: gameState.currentGrid,
            puzzle: gameState.puzzle
        )
    }

    /// Reveals the correct value for a cell from the puzzle solution
    /// This is a "cheat" hint that directly shows the answer
    /// - Parameters:
    ///   - position: The cell position to reveal
    ///   - gameState: The current game state
    /// - Returns: The correct value for this cell, or nil if position is invalid
    func revealValue(for position: CellPosition, in gameState: GameState) -> Int? {
        // Check if position is valid and editable
        guard gameState.puzzle.isValidPosition(position) else { return nil }
        guard gameState.isEditable(at: position) else { return nil }

        // Return the solution value for this position
        return gameState.puzzle.solution[position.row][position.column]
    }

    /// Provides a hint based on the current game state
    /// Strategy:
    /// 1. If a cell is selected and empty, provide possible values
    /// 2. Otherwise, find the next logical move
    /// 3. If no logical move exists, find any empty cell and provide its possible values
    /// - Parameters:
    ///   - gameState: The current game state
    /// - Returns: A hint for the player, or nil if the puzzle is complete
    func provideHint(for gameState: GameState) -> HintType? {
        // If puzzle is already complete, no hint needed
        guard !gameState.isCompleted else { return nil }

        // Strategy 1: If a cell is selected and empty, show possible values
        if let selectedPosition = gameState.selectedCell,
           gameState.isEmpty(at: selectedPosition),
           gameState.isEditable(at: selectedPosition)
        {
            let possibleValues = getPossibleValues(for: selectedPosition, in: gameState)
            return .possibleValues(position: selectedPosition, values: possibleValues)
        }

        // Strategy 2: Try to find a logical move
        if let logicalMove = identifyNextCell(in: gameState) {
            return .logicalMove(position: logicalMove.position, value: logicalMove.value)
        }

        // Strategy 3: If no logical move, find the first empty cell with fewest possibilities
        var bestCell: (position: CellPosition, values: Set<Int>)?
        var minPossibilities = Int.max

        for row in 0 ..< gameState.puzzle.rows {
            for col in 0 ..< gameState.puzzle.columns {
                let position = CellPosition(row: row, column: col)

                // Skip filled cells and non-editable cells
                guard gameState.isEmpty(at: position) else { continue }
                guard gameState.isEditable(at: position) else { continue }

                let possibleValues = getPossibleValues(for: position, in: gameState)

                // Find cell with minimum possibilities (most constrained)
                if !possibleValues.isEmpty, possibleValues.count < minPossibilities {
                    minPossibilities = possibleValues.count
                    bestCell = (position: position, values: possibleValues)
                }
            }
        }

        if let cell = bestCell {
            return .possibleValues(position: cell.position, values: cell.values)
        }

        // No hint available (shouldn't happen if puzzle isn't complete)
        return nil
    }

    /// Validates that a hint is still relevant after game state changes
    /// This helps ensure hints don't become stale
    /// - Parameters:
    ///   - hint: The hint to validate
    ///   - gameState: The current game state
    /// - Returns: True if the hint is still valid and useful
    func isHintStillValid(_ hint: HintType, in gameState: GameState) -> Bool {
        switch hint {
        case let .logicalMove(position, value):
            // Check if the cell is still empty and editable
            guard gameState.isEmpty(at: position) else { return false }
            guard gameState.isEditable(at: position) else { return false }

            // Check if the value is still valid
            let possibleValues = getPossibleValues(for: position, in: gameState)
            return possibleValues.contains(value)

        case let .revealValue(position, value):
            // Check if the cell is still empty and editable
            guard gameState.isEmpty(at: position) else { return false }
            guard gameState.isEditable(at: position) else { return false }

            // Check if the revealed value matches the solution
            return gameState.puzzle.solution[position.row][position.column] == value

        case let .possibleValues(position, values):
            // Check if the cell is still empty and editable
            guard gameState.isEmpty(at: position) else { return false }
            guard gameState.isEditable(at: position) else { return false }

            // Check if at least some of the values are still valid
            let currentPossibleValues = getPossibleValues(for: position, in: gameState)
            return !values.intersection(currentPossibleValues).isEmpty
        }
    }

    /// Gets a difficulty rating for the current puzzle state
    /// This can help adjust hint frequency or type
    /// - Parameter gameState: The current game state
    /// - Returns: A difficulty score (0.0 = easy, 1.0 = very hard)
    func estimateDifficulty(for gameState: GameState) -> Double {
        var totalCells = 0
        var constrainedCells = 0
        var cellsWithSingleOption = 0

        for row in 0 ..< gameState.puzzle.rows {
            for col in 0 ..< gameState.puzzle.columns {
                let position = CellPosition(row: row, column: col)

                // Skip filled cells
                guard gameState.isEmpty(at: position) else { continue }
                guard gameState.isEditable(at: position) else { continue }

                totalCells += 1

                let possibleValues = getPossibleValues(for: position, in: gameState)

                // Cell with few options is more constrained
                if possibleValues.count <= 3 {
                    constrainedCells += 1
                }

                // Cell with single option is trivial
                if possibleValues.count == 1 {
                    cellsWithSingleOption += 1
                }
            }
        }

        guard totalCells > 0 else { return 0.0 }

        // If many cells have single options, it's easier
        let easyFactor = Double(cellsWithSingleOption) / Double(totalCells)

        // If few cells are constrained, it's harder (requires more guessing)
        let hardFactor = 1.0 - (Double(constrainedCells) / Double(totalCells))

        // Combine factors: high hard factor and low easy factor = difficult
        return (hardFactor + (1.0 - easyFactor)) / 2.0
    }
}
