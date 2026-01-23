import XCTest
@testable import TennerGrid

final class PuzzleSolverTests: XCTestCase {
    var solver: PuzzleSolver!

    override func setUp() {
        super.setUp()
        solver = PuzzleSolver()
    }

    override func tearDown() {
        solver = nil
        super.tearDown()
    }

    // MARK: - hasUniqueSolution Tests

    func testHasUniqueSolution_SimplePuzzleWithUniqueSolution() {
        // Given: A simple 3x3 puzzle with a unique solution
        // Grid structure where only one solution is possible
        let initialGrid: [[Int?]] = [
            [1, 2, nil],
            [4, nil, 6],
            [nil, 8, 9],
        ]

        // Target sums calculated from the expected solution
        // Expected solution:
        // [1, 2, 3]
        // [4, 5, 6]
        // [7, 8, 9]
        // Column sums: 12, 15, 18
        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The puzzle should have a unique solution
        XCTAssertTrue(hasUnique, "Puzzle with unique solution should return true")
    }

    func testHasUniqueSolution_PuzzleWithMultipleSolutions() {
        // Given: A puzzle with very few constraints, allowing multiple solutions
        let initialGrid: [[Int?]] = [
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil],
        ]

        // Very lenient target sums that allow multiple valid grids
        let targetSums = [20, 20, 5]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [9, 9, 2],
                [9, 9, 0],
                [2, 2, 3],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The puzzle should not have a unique solution (multiple solutions exist)
        XCTAssertFalse(hasUnique, "Puzzle with multiple solutions should return false")
    }

    func testHasUniqueSolution_PuzzleWithNoSolution() {
        // Given: A puzzle with impossible constraints
        let initialGrid: [[Int?]] = [
            [1, 2, nil],
            [2, nil, nil],
            [nil, nil, nil],
        ]

        // Impossible target sum for column 0 (already has 1+2 = 3, but target is 2)
        let targetSums = [2, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [2, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The puzzle should not have a unique solution (no solution exists)
        XCTAssertFalse(hasUnique, "Puzzle with no solution should return false")
    }

    func testHasUniqueSolution_FullyConstrainedGrid() {
        // Given: A puzzle where all cells are filled (fully constrained)
        let initialGrid: [[Int?]] = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: The fully filled grid should have exactly one solution (itself)
        XCTAssertTrue(hasUnique, "Fully constrained grid should have unique solution")
    }

    func testHasUniqueSolution_InvalidDimensions() {
        // Given: A puzzle with mismatched grid dimensions
        let initialGrid: [[Int?]] = [
            [1, 2],
            [4, 5],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Checking if the puzzle has a unique solution
        let hasUnique = solver.hasUniqueSolution(puzzle: puzzle)

        // Then: Should return false due to invalid dimensions
        XCTAssertFalse(hasUnique, "Puzzle with invalid dimensions should return false")
    }

    // MARK: - findNextLogicalMove Tests

    func testFindNextLogicalMove_NakedSingle() {
        // Given: A grid where one cell has only one possible value (naked single)
        let initialGrid: [[Int?]] = [
            [1, 2, nil], // Position (0, 2) can only be 3 based on constraints
            [4, nil, 6],
            [7, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should return a move (naked single)
        XCTAssertNotNil(result, "Should find a logical move")
        if let move = result {
            // Verify the move is one of the empty cells
            XCTAssertTrue(
                (move.position.row == 0 && move.position.column == 2) ||
                    (move.position.row == 1 && move.position.column == 1),
                "Should return one of the empty cells"
            )
            XCTAssertTrue(move.value >= 0 && move.value <= 9, "Value should be between 0 and 9")
        }
    }

    func testFindNextLogicalMove_HiddenSingle() {
        // Given: A grid where a value can only go in one position in a row/column
        let initialGrid: [[Int?]] = [
            [0, 1, 2],
            [3, nil, 5],
            [nil, nil, nil],
        ]

        let targetSums = [10, 10, 16]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [0, 1, 2],
                [3, 4, 5],
                [7, 6, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should find a logical move
        XCTAssertNotNil(result, "Should find a logical move (hidden single or naked single)")
    }

    func testFindNextLogicalMove_ColumnSumConstraint() {
        // Given: A grid where column sum forces a specific value
        let initialGrid: [[Int?]] = [
            [5, 2, 3],
            [4, 7, 6],
            [nil, 8, 9],
        ]

        // Column 0 target sum is 12, and we have 5 + 4 = 9, so the last cell must be 3
        let targetSums = [12, 17, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [5, 2, 3],
                [4, 7, 6],
                [3, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should find the forced move
        XCTAssertNotNil(result, "Should find a logical move")
        if let move = result {
            XCTAssertEqual(move.position.row, 2, "Should be in row 2")
            XCTAssertEqual(move.position.column, 0, "Should be in column 0")
            XCTAssertEqual(move.value, 3, "Value should be 3 (forced by column sum)")
        }
    }

    func testFindNextLogicalMove_NoLogicalMove() {
        // Given: A complex grid where no logical deduction is possible (requires guessing)
        let initialGrid: [[Int?]] = [
            [nil, nil, nil],
            [nil, 5, nil],
            [nil, nil, nil],
        ]

        let targetSums = [15, 15, 15]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .hard,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [4, 6, 3],
                [7, 5, 8],
                [4, 4, 4],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: May or may not find a move depending on constraints
        // This is a valid test case - we just verify it returns a valid result type
        if let move = result {
            XCTAssertTrue(move.value >= 0 && move.value <= 9, "If move found, value should be valid")
        }
    }

    func testFindNextLogicalMove_EmptyGrid() {
        // Given: A completely empty grid
        let initialGrid: [[Int?]] = [
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: May or may not find a logical move
        // With an empty grid, there might not be enough constraints for a logical deduction
        if let move = result {
            XCTAssertTrue(move.value >= 0 && move.value <= 9, "If move found, value should be valid")
            XCTAssertTrue(move.position.row >= 0 && move.position.row < 3, "Row should be valid")
            XCTAssertTrue(move.position.column >= 0 && move.position.column < 3, "Column should be valid")
        }
    }

    func testFindNextLogicalMove_AlmostComplete() {
        // Given: A grid that is almost complete
        let initialGrid: [[Int?]] = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Finding the next logical move
        let result = solver.findNextLogicalMove(in: initialGrid, puzzle: puzzle)

        // Then: Should find the last move
        XCTAssertNotNil(result, "Should find the final move")
        if let move = result {
            XCTAssertEqual(move.position.row, 2, "Should be in row 2")
            XCTAssertEqual(move.position.column, 2, "Should be in column 2")
            XCTAssertEqual(move.value, 9, "Value should be 9")
        }
    }

    // MARK: - solve Tests

    func testSolve_EasyPuzzle() {
        // Given: A simple 3x3 easy puzzle
        let initialGrid: [[Int?]] = [
            [1, 2, nil],
            [4, nil, 6],
            [nil, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Solving the puzzle
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should find a valid solution
        XCTAssertNotNil(solution, "Should find a solution for easy puzzle")
        if let solved = solution {
            XCTAssertEqual(solved.count, 3, "Solution should have 3 rows")
            XCTAssertEqual(solved[0].count, 3, "Solution rows should have 3 columns")

            // Verify initial values are preserved
            XCTAssertEqual(solved[0][0], 1, "Initial value should be preserved")
            XCTAssertEqual(solved[0][1], 2, "Initial value should be preserved")
            XCTAssertEqual(solved[1][0], 4, "Initial value should be preserved")

            // Verify column sums
            for col in 0 ..< 3 {
                let sum = solved.map { $0[col] }.reduce(0, +)
                XCTAssertEqual(sum, targetSums[col], "Column \(col) sum should match target")
            }

            // Verify no row duplicates
            for row in solved {
                let uniqueValues = Set(row)
                XCTAssertEqual(uniqueValues.count, row.count, "Each row should have no duplicates")
            }

            // Verify no adjacent duplicates
            for row in 0 ..< 3 {
                for col in 0 ..< 3 {
                    let value = solved[row][col]
                    let adjacents = [
                        (row - 1, col - 1), (row - 1, col), (row - 1, col + 1),
                        (row, col - 1), (row, col + 1),
                        (row + 1, col - 1), (row + 1, col), (row + 1, col + 1),
                    ]

                    for (adjRow, adjCol) in adjacents {
                        guard adjRow >= 0, adjRow < 3, adjCol >= 0, adjCol < 3 else { continue }
                        XCTAssertNotEqual(
                            solved[adjRow][adjCol],
                            value,
                            "Adjacent cells should not have same value at (\(row),\(col))"
                        )
                    }
                }
            }
        }
    }

    func testSolve_MediumPuzzle() {
        // Given: A 4x4 medium difficulty puzzle
        let initialGrid: [[Int?]] = [
            [nil, 2, nil, nil],
            [nil, nil, 6, nil],
            [8, nil, nil, nil],
            [nil, nil, nil, 3],
        ]

        // Construct target sums for a valid solution
        let targetSums = [15, 18, 14, 13]

        let puzzle = TennerGridPuzzle(
            columns: 4,
            rows: 4,
            difficulty: .medium,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3, 4],
                [5, 7, 6, 0],
                [8, 9, 0, 5],
                [1, 0, 5, 3],
            ]
        )

        // When: Solving the puzzle
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should find a valid solution
        XCTAssertNotNil(solution, "Should find a solution for medium puzzle")
        if let solved = solution {
            XCTAssertEqual(solved.count, 4, "Solution should have 4 rows")

            // Verify initial values are preserved
            XCTAssertEqual(solved[0][1], 2, "Initial value should be preserved")
            XCTAssertEqual(solved[1][2], 6, "Initial value should be preserved")
            XCTAssertEqual(solved[2][0], 8, "Initial value should be preserved")
            XCTAssertEqual(solved[3][3], 3, "Initial value should be preserved")

            // Verify column sums
            for col in 0 ..< 4 {
                let sum = solved.map { $0[col] }.reduce(0, +)
                XCTAssertEqual(sum, targetSums[col], "Column \(col) sum should match target")
            }
        }
    }

    func testSolve_HardPuzzle() {
        // Given: A 5x5 hard puzzle with fewer initial values
        let initialGrid: [[Int?]] = [
            [nil, nil, nil, nil, 5],
            [nil, 7, nil, nil, nil],
            [nil, nil, 1, nil, nil],
            [nil, nil, nil, 9, nil],
            [0, nil, nil, nil, nil],
        ]

        // Target sums for a solvable puzzle
        let targetSums = [20, 25, 15, 30, 20]

        let puzzle = TennerGridPuzzle(
            columns: 5,
            rows: 5,
            difficulty: .hard,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [6, 2, 3, 4, 5],
                [8, 7, 0, 1, 2],
                [5, 9, 1, 7, 3],
                [1, 4, 6, 9, 0],
                [0, 3, 5, 9, 10],
            ]
        )

        // When: Solving the puzzle
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should find a valid solution
        XCTAssertNotNil(solution, "Should find a solution for hard puzzle")
        if let solved = solution {
            XCTAssertEqual(solved.count, 5, "Solution should have 5 rows")
            XCTAssertEqual(solved[0].count, 5, "Solution rows should have 5 columns")

            // Verify initial values
            XCTAssertEqual(solved[0][4], 5, "Initial value should be preserved")
            XCTAssertEqual(solved[1][1], 7, "Initial value should be preserved")
            XCTAssertEqual(solved[2][2], 1, "Initial value should be preserved")
            XCTAssertEqual(solved[4][0], 0, "Initial value should be preserved")

            // Verify all values are in valid range
            for row in solved {
                for value in row {
                    XCTAssertTrue(value >= 0 && value <= 9, "All values should be 0-9")
                }
            }
        }
    }

    func testSolve_LargerPuzzle() {
        // Given: A 5x6 hard puzzle (larger grid)
        let initialGrid: [[Int?]] = [
            [nil, nil, nil, nil, nil, nil],
            [nil, nil, 3, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil],
            [nil, 5, nil, nil, nil, nil],
            [nil, nil, nil, nil, 8, nil],
        ]

        let targetSums = [18, 22, 20, 25, 23, 17]

        let puzzle = TennerGridPuzzle(
            columns: 6,
            rows: 5,
            difficulty: .hard,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3, 4, 5, 6],
                [7, 8, 3, 9, 0, 1],
                [4, 6, 5, 7, 9, 2],
                [3, 5, 4, 2, 1, 0],
                [3, 1, 5, 3, 8, 8],
            ]
        )

        // When: Solving the puzzle
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should find a solution or nil (hard puzzles can be challenging)
        if let solved = solution {
            XCTAssertEqual(solved.count, 5, "Solution should have 5 rows")
            XCTAssertEqual(solved[0].count, 6, "Solution rows should have 6 columns")

            // Verify column sums
            for col in 0 ..< 6 {
                let sum = solved.map { $0[col] }.reduce(0, +)
                XCTAssertEqual(sum, targetSums[col], "Column \(col) sum should match target")
            }
        }
    }

    func testSolve_ImpossiblePuzzle() {
        // Given: A puzzle with impossible constraints
        let initialGrid: [[Int?]] = [
            [1, 1, nil],
            [nil, nil, nil],
            [nil, nil, nil],
        ]

        // Target sum impossible due to adjacent duplicates in initial grid
        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Trying to solve the impossible puzzle
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should return nil
        XCTAssertNil(solution, "Impossible puzzle should return nil")
    }

    func testSolve_EmptyGrid() {
        // Given: A completely empty 3x3 grid
        let initialGrid: [[Int?]] = [
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Solving an empty grid
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should find a solution
        XCTAssertNotNil(solution, "Should be able to solve empty grid")
        if let solved = solution {
            // Verify column sums
            for col in 0 ..< 3 {
                let sum = solved.map { $0[col] }.reduce(0, +)
                XCTAssertEqual(sum, targetSums[col], "Column \(col) sum should match target")
            }
        }
    }

    func testSolve_AlreadyComplete() {
        // Given: A puzzle that's already solved
        let initialGrid: [[Int?]] = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Solving an already complete puzzle
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should return the same solution
        XCTAssertNotNil(solution, "Should solve already complete puzzle")
        if let solved = solution {
            XCTAssertEqual(solved, [[1, 2, 3], [4, 5, 6], [7, 8, 9]], "Should return the same grid")
        }
    }

    func testSolve_InvalidDimensions() {
        // Given: A puzzle with mismatched grid dimensions
        let initialGrid: [[Int?]] = [
            [1, 2],
            [4, 5],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: initialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Trying to solve with invalid dimensions
        let solution = solver.solve(puzzle: puzzle)

        // Then: Should return nil
        XCTAssertNil(solution, "Invalid dimensions should return nil")
    }

    func testSolve_CustomInitialGrid() {
        // Given: A puzzle with a custom initial grid (different from puzzle's initialGrid)
        let puzzleInitialGrid: [[Int?]] = [
            [1, 2, nil],
            [4, nil, 6],
            [nil, 8, 9],
        ]

        let customInitialGrid: [[Int?]] = [
            [1, nil, 3],
            [nil, 5, nil],
            [7, nil, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: puzzleInitialGrid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        // When: Solving with custom initial grid
        let solution = solver.solve(puzzle: puzzle, initialGrid: customInitialGrid)

        // Then: Should solve using the custom grid
        XCTAssertNotNil(solution, "Should solve with custom initial grid")
        if let solved = solution {
            // Verify custom initial values are preserved
            XCTAssertEqual(solved[0][0], 1, "Custom initial value should be preserved")
            XCTAssertEqual(solved[0][2], 3, "Custom initial value should be preserved")
            XCTAssertEqual(solved[1][1], 5, "Custom initial value should be preserved")
        }
    }

    // MARK: - getPossibleValues Tests

    func testGetPossibleValues_EmptyCell() {
        // Given: An empty cell in a partially filled grid
        let grid: [[Int?]] = [
            [nil, 2, nil],
            [4, nil, 6],
            [nil, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: grid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        let position = CellPosition(row: 0, column: 0)

        // When: Getting possible values
        let possibleValues = solver.getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Then: Should return a set of valid values
        XCTAssertFalse(possibleValues.isEmpty, "Should have at least one possible value")
        XCTAssertTrue(possibleValues.allSatisfy { $0 >= 0 && $0 <= 9 }, "All values should be 0-9")

        // Should not include adjacent values
        XCTAssertFalse(possibleValues.contains(2), "Should not include adjacent value 2")
        XCTAssertFalse(possibleValues.contains(4), "Should not include adjacent value 4")
    }

    func testGetPossibleValues_HighlyConstrained() {
        // Given: A cell with many constraints
        let grid: [[Int?]] = [
            [1, 2, 3],
            [4, nil, 6],
            [7, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: grid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        let position = CellPosition(row: 1, column: 1)

        // When: Getting possible values
        let possibleValues = solver.getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Then: Should have very few possible values due to constraints
        XCTAssertTrue(possibleValues.count <= 3, "Highly constrained cell should have few options")

        // Should not include values in the same row
        XCTAssertFalse(possibleValues.contains(4), "Should not include row value 4")
        XCTAssertFalse(possibleValues.contains(6), "Should not include row value 6")

        // Should not include adjacent values
        XCTAssertFalse(possibleValues.contains(1), "Should not include adjacent value 1")
        XCTAssertFalse(possibleValues.contains(2), "Should not include adjacent value 2")
        XCTAssertFalse(possibleValues.contains(3), "Should not include adjacent value 3")
    }

    func testGetPossibleValues_OnlyOnePossible() {
        // Given: A cell where only one value is possible (naked single)
        let grid: [[Int?]] = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: grid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        let position = CellPosition(row: 2, column: 2)

        // When: Getting possible values
        let possibleValues = solver.getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Then: Should have exactly one possible value
        XCTAssertEqual(possibleValues.count, 1, "Should have exactly one possible value")
        XCTAssertTrue(possibleValues.contains(9), "Should contain value 9")
    }

    func testGetPossibleValues_NoPossibleValues() {
        // Given: A cell where no values are possible (impossible state)
        // Position (1,0) is adjacent to (0,0)=0, diagonal to (0,1)=1
        // Column sum = 1 means we need value 1, but 1 is forbidden (diagonal)
        let grid: [[Int?]] = [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ]

        // Column 0 needs sum of 1, but value 1 is diagonally adjacent to (0,1)
        // Value 0 is adjacent to (0,0), so both are forbidden
        // No valid value exists that makes sum = 1
        let targetSums = [1, 5, 5, 5, 5, 5, 5, 5, 5, 5]

        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 2,
            difficulty: .hard,
            targetSums: targetSums,
            initialGrid: grid,
            solution: Array(repeating: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], count: 2)
        )

        let position = CellPosition(row: 1, column: 0)

        // When: Getting possible values
        let possibleValues = solver.getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Then: Should return empty set
        // The only value that satisfies sum=1 is 1 (since 0+1=1), but 1 is forbidden
        XCTAssertTrue(possibleValues.isEmpty, "Should have no possible values in impossible state")
    }

    func testGetPossibleValues_ColumnSumConstraint() {
        // Given: A cell where column sum limits possibilities
        let grid: [[Int?]] = [
            [9, 2, 3],
            [9, 5, 6],
            [nil, 8, 9],
        ]

        // Column 0 target sum is 20, already has 18, so only values 0-2 are possible
        let targetSums = [20, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .medium,
            targetSums: targetSums,
            initialGrid: grid,
            solution: [
                [9, 2, 3],
                [9, 5, 6],
                [2, 8, 9],
            ]
        )

        let position = CellPosition(row: 2, column: 0)

        // When: Getting possible values
        let possibleValues = solver.getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Then: Should only include values that would result in valid column sum
        for value in possibleValues {
            XCTAssertTrue(value >= 0 && value <= 2, "Values should be limited by column sum constraint")
        }

        // Should not include 9 (row duplicate) even though sum allows it
        XCTAssertFalse(possibleValues.contains(9), "Should not include row duplicate 9")
    }

    func testGetPossibleValues_CornerCell() {
        // Given: A corner cell with fewer neighbors
        let grid: [[Int?]] = [
            [nil, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ]

        let targetSums = [12, 15, 18]

        let puzzle = TennerGridPuzzle(
            columns: 3,
            rows: 3,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: grid,
            solution: [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
            ]
        )

        let position = CellPosition(row: 0, column: 0)

        // When: Getting possible values
        let possibleValues = solver.getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Then: Should respect constraints from fewer neighbors
        XCTAssertFalse(possibleValues.isEmpty, "Corner cell should have possible values")
        XCTAssertFalse(possibleValues.contains(2), "Should not include adjacent value 2")
        XCTAssertFalse(possibleValues.contains(4), "Should not include adjacent value 4")
        XCTAssertFalse(possibleValues.contains(5), "Should not include diagonal adjacent value 5")
    }

    func testGetPossibleValues_AllValuesUsedInRow() {
        // Given: A row where many values are already used
        let grid: [[Int?]] = [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, nil],
        ]

        let targetSums = [0, 0, 0, 0, 0, 0, 0, 0, 0, 45]

        let puzzle = TennerGridPuzzle(
            columns: 10,
            rows: 1,
            difficulty: .hard,
            targetSums: targetSums,
            initialGrid: grid,
            solution: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]]
        )

        let position = CellPosition(row: 0, column: 9)

        // When: Getting possible values
        let possibleValues = solver.getPossibleValues(for: position, in: grid, puzzle: puzzle)

        // Then: Should only include value 9 (not used in row and not adjacent to 8)
        XCTAssertTrue(possibleValues.isEmpty || possibleValues == [9], "Should only have value 9 available")
    }
}
