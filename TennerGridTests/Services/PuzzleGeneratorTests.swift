//
//  PuzzleGeneratorTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

@testable import TennerGrid
import XCTest

final class PuzzleGeneratorTests: XCTestCase {
    var generator: PuzzleGenerator!
    var validationService: ValidationService!

    override func setUp() {
        super.setUp()
        generator = PuzzleGenerator()
        validationService = ValidationService()
    }

    override func tearDown() {
        generator = nil
        validationService = nil
        super.tearDown()
    }

    // MARK: - generateCompletedGrid Tests

    func testGenerateCompletedGrid_MinimumSize() {
        // Given: Minimum valid dimensions (5x5)
        let rows = 5
        let columns = 5

        // When: Generating a completed grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Should successfully generate a valid grid
        XCTAssertNotNil(grid, "Should generate a grid for minimum size")
        if let completedGrid = grid {
            XCTAssertEqual(completedGrid.count, rows, "Grid should have correct number of rows")
            XCTAssertEqual(completedGrid[0].count, columns, "Grid should have correct number of columns")

            // Verify all cells are filled with valid values (0-9)
            for row in completedGrid {
                for value in row {
                    XCTAssertTrue(value >= 0 && value <= 9, "All values should be between 0 and 9")
                }
            }

            // Verify no adjacent duplicates
            verifyNoAdjacentDuplicates(grid: completedGrid, rows: rows, columns: columns)

            // Verify no row duplicates
            verifyNoRowDuplicates(grid: completedGrid)
        }
    }

    func testGenerateCompletedGrid_MaximumSize() {
        // Given: Maximum valid dimensions (10x10)
        let rows = 10
        let columns = 10

        // When: Generating a completed grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Should successfully generate a valid grid
        XCTAssertNotNil(grid, "Should generate a grid for maximum size")
        if let completedGrid = grid {
            XCTAssertEqual(completedGrid.count, rows, "Grid should have correct number of rows")
            XCTAssertEqual(completedGrid[0].count, columns, "Grid should have correct number of columns")

            // Verify all cells are filled
            for row in completedGrid {
                for value in row {
                    XCTAssertTrue(value >= 0 && value <= 9, "All values should be between 0 and 9")
                }
            }

            // Verify no adjacent duplicates
            verifyNoAdjacentDuplicates(grid: completedGrid, rows: rows, columns: columns)

            // Verify no row duplicates
            verifyNoRowDuplicates(grid: completedGrid)
        }
    }

    func testGenerateCompletedGrid_TypicalSize() {
        // Given: Typical puzzle dimensions (6x8)
        let rows = 6
        let columns = 8

        // When: Generating a completed grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Should successfully generate a valid grid
        XCTAssertNotNil(grid, "Should generate a grid for typical size")
        if let completedGrid = grid {
            XCTAssertEqual(completedGrid.count, rows, "Grid should have correct number of rows")
            XCTAssertEqual(completedGrid[0].count, columns, "Grid should have correct number of columns")

            // Verify no adjacent duplicates
            verifyNoAdjacentDuplicates(grid: completedGrid, rows: rows, columns: columns)

            // Verify no row duplicates
            verifyNoRowDuplicates(grid: completedGrid)
        }
    }

    func testGenerateCompletedGrid_InvalidDimensions_TooSmall() {
        // Given: Dimensions too small (rows < 5)
        let rows = 3
        let columns = 5

        // When: Attempting to generate a grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Should return nil for invalid dimensions
        XCTAssertNil(grid, "Should return nil for rows < 5")
    }

    func testGenerateCompletedGrid_InvalidDimensions_TooLarge() {
        // Given: Dimensions too large (columns > 10)
        let rows = 5
        let columns = 12

        // When: Attempting to generate a grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Should return nil for invalid dimensions
        XCTAssertNil(grid, "Should return nil for columns > 10")
    }

    func testGenerateCompletedGrid_InvalidDimensions_BothInvalid() {
        // Given: Both dimensions invalid
        let rows = 2
        let columns = 15

        // When: Attempting to generate a grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Should return nil for invalid dimensions
        XCTAssertNil(grid, "Should return nil for both dimensions invalid")
    }

    func testGenerateCompletedGrid_WithSeed_Deterministic() {
        // Given: Same seed value
        let rows = 6
        let columns = 6
        let seed: UInt64 = 12345

        // When: Generating multiple grids with the same seed
        let grid1 = generator.generateCompletedGrid(rows: rows, columns: columns, seed: seed)
        let grid2 = generator.generateCompletedGrid(rows: rows, columns: columns, seed: seed)

        // Then: Should generate identical grids
        XCTAssertNotNil(grid1, "First grid should be generated")
        XCTAssertNotNil(grid2, "Second grid should be generated")

        if let g1 = grid1, let g2 = grid2 {
            XCTAssertEqual(g1, g2, "Same seed should produce identical grids")
        }
    }

    func testGenerateCompletedGrid_WithDifferentSeeds_Different() {
        // Given: Different seed values
        let rows = 5
        let columns = 5
        let seed1: UInt64 = 12345
        let seed2: UInt64 = 67890

        // When: Generating grids with different seeds
        let grid1 = generator.generateCompletedGrid(rows: rows, columns: columns, seed: seed1)
        let grid2 = generator.generateCompletedGrid(rows: rows, columns: columns, seed: seed2)

        // Then: Should generate different grids (highly likely)
        XCTAssertNotNil(grid1, "First grid should be generated")
        XCTAssertNotNil(grid2, "Second grid should be generated")

        if let g1 = grid1, let g2 = grid2 {
            XCTAssertNotEqual(g1, g2, "Different seeds should produce different grids")
        }
    }

    func testGenerateCompletedGrid_WithoutSeed_Random() {
        // Given: No seed (random generation)
        let rows = 5
        let columns = 5

        // When: Generating multiple grids without seed
        let grid1 = generator.generateCompletedGrid(rows: rows, columns: columns)
        let grid2 = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Should generate different grids (highly likely, not guaranteed)
        XCTAssertNotNil(grid1, "First grid should be generated")
        XCTAssertNotNil(grid2, "Second grid should be generated")

        // Note: There's a tiny chance they could be the same due to randomness
        // This test verifies that generation works, not that they're always different
        if let g1 = grid1, let g2 = grid2 {
            // Just verify both are valid
            XCTAssertEqual(g1.count, rows, "First grid has correct rows")
            XCTAssertEqual(g2.count, rows, "Second grid has correct rows")
        }
    }

    func testGenerateCompletedGrid_ColumnSumsAreValid() {
        // Given: Standard dimensions
        let rows = 7
        let columns = 6

        // When: Generating a completed grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: Each column sum should be within reasonable range
        XCTAssertNotNil(grid, "Should generate a grid")
        if let completedGrid = grid {
            for col in 0 ..< columns {
                var sum = 0
                for row in 0 ..< rows {
                    sum += completedGrid[row][col]
                }

                // Column sum should be between rows*2 and rows*7 (as per generator logic)
                let minSum = rows * 2
                let maxSum = rows * 7
                XCTAssertTrue(
                    sum >= minSum && sum <= maxSum,
                    "Column \(col) sum (\(sum)) should be between \(minSum) and \(maxSum)"
                )
            }
        }
    }

    func testGenerateCompletedGrid_AllRowsHaveValidLength() {
        // Given: Standard dimensions
        let rows = 8
        let columns = 7

        // When: Generating a completed grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: All rows should have the correct number of columns
        XCTAssertNotNil(grid, "Should generate a grid")
        if let completedGrid = grid {
            for (index, row) in completedGrid.enumerated() {
                XCTAssertEqual(
                    row.count,
                    columns,
                    "Row \(index) should have \(columns) columns"
                )
            }
        }
    }

    func testGenerateCompletedGrid_NoOutOfBoundsValues() {
        // Given: Standard dimensions
        let rows = 6
        let columns = 6

        // When: Generating a completed grid
        let grid = generator.generateCompletedGrid(rows: rows, columns: columns)

        // Then: All values should be between 0 and 9 inclusive
        XCTAssertNotNil(grid, "Should generate a grid")
        if let completedGrid = grid {
            for (rowIndex, row) in completedGrid.enumerated() {
                for (colIndex, value) in row.enumerated() {
                    XCTAssertTrue(
                        value >= 0 && value <= 9,
                        "Value at (\(rowIndex), \(colIndex)) should be between 0 and 9, got \(value)"
                    )
                }
            }
        }
    }

    func testGenerateCompletedGrid_MultipleGenerations_AllValid() {
        // Given: Standard dimensions
        let rows = 5
        let columns = 5

        // When: Generating multiple grids
        let attempts = 10
        var successCount = 0

        for _ in 0 ..< attempts {
            if let grid = generator.generateCompletedGrid(rows: rows, columns: columns) {
                successCount += 1

                // Verify each grid is valid
                verifyNoAdjacentDuplicates(grid: grid, rows: rows, columns: columns)
                verifyNoRowDuplicates(grid: grid)

                // Verify all values are in valid range
                for row in grid {
                    for value in row {
                        XCTAssertTrue(value >= 0 && value <= 9, "All values should be 0-9")
                    }
                }
            }
        }

        // Then: Should successfully generate most or all grids
        XCTAssertTrue(
            successCount >= attempts / 2,
            "Should successfully generate at least half of the attempts"
        )
    }

    func testGenerateCompletedGrid_LargeGrid_Performance() {
        // Given: Large grid dimensions
        let rows = 10
        let columns = 10

        // When: Measuring generation time
        measure {
            _ = generator.generateCompletedGrid(rows: rows, columns: columns)
        }

        // Then: Performance is measured (no explicit assertion, XCTest tracks this)
    }

    func testGenerateCompletedGrid_SmallGrid_Performance() {
        // Given: Small grid dimensions
        let rows = 5
        let columns = 5

        // When: Measuring generation time
        measure {
            _ = generator.generateCompletedGrid(rows: rows, columns: columns)
        }

        // Then: Performance is measured (no explicit assertion, XCTest tracks this)
    }

    // MARK: - Helper Methods

    /// Verifies that no adjacent cells (including diagonals) have the same value
    private func verifyNoAdjacentDuplicates(grid: [[Int]], rows: Int, columns: Int) {
        let adjacentOffsets = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1), (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]

        for row in 0 ..< rows {
            for col in 0 ..< columns {
                let value = grid[row][col]

                for (rowOffset, colOffset) in adjacentOffsets {
                    let adjRow = row + rowOffset
                    let adjCol = col + colOffset

                    // Check bounds
                    guard adjRow >= 0, adjRow < rows, adjCol >= 0, adjCol < columns else {
                        continue
                    }

                    let adjacentValue = grid[adjRow][adjCol]
                    XCTAssertNotEqual(
                        value,
                        adjacentValue,
                        "Adjacent cells at (\(row),\(col)) and (\(adjRow),\(adjCol)) have same value \(value)"
                    )
                }
            }
        }
    }

    /// Verifies that no row has duplicate values
    private func verifyNoRowDuplicates(grid: [[Int]]) {
        for (rowIndex, row) in grid.enumerated() {
            let uniqueValues = Set(row)
            XCTAssertEqual(
                uniqueValues.count,
                row.count,
                "Row \(rowIndex) has duplicate values: \(row)"
            )
        }
    }

    // MARK: - calculateColumnSums Tests

    func testCalculateColumnSums_ValidGrid() {
        // Given: A simple 3x3 grid with known values
        let grid = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: Should return correct sums [12, 15, 18]
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, 3, "Should have 3 column sums")
        XCTAssertEqual(sums?[0], 12, "Column 0 sum should be 1+4+7=12")
        XCTAssertEqual(sums?[1], 15, "Column 1 sum should be 2+5+8=15")
        XCTAssertEqual(sums?[2], 18, "Column 2 sum should be 3+6+9=18")
    }

    func testCalculateColumnSums_SingleRow() {
        // Given: A grid with a single row
        let grid = [[5, 3, 7, 2]]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: Column sums should equal the row values
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, 4, "Should have 4 column sums")
        XCTAssertEqual(sums?[0], 5, "Column 0 sum should be 5")
        XCTAssertEqual(sums?[1], 3, "Column 1 sum should be 3")
        XCTAssertEqual(sums?[2], 7, "Column 2 sum should be 7")
        XCTAssertEqual(sums?[3], 2, "Column 3 sum should be 2")
    }

    func testCalculateColumnSums_SingleColumn() {
        // Given: A grid with a single column
        let grid = [
            [3],
            [7],
            [2],
            [9],
        ]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: Should return sum of all values
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, 1, "Should have 1 column sum")
        XCTAssertEqual(sums?[0], 21, "Column 0 sum should be 3+7+2+9=21")
    }

    func testCalculateColumnSums_AllZeros() {
        // Given: A grid with all zeros
        let grid = [
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0],
        ]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: All sums should be zero
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, 3, "Should have 3 column sums")
        XCTAssertEqual(sums?[0], 0, "Column 0 sum should be 0")
        XCTAssertEqual(sums?[1], 0, "Column 1 sum should be 0")
        XCTAssertEqual(sums?[2], 0, "Column 2 sum should be 0")
    }

    func testCalculateColumnSums_AllNines() {
        // Given: A grid with all nines
        let grid = [
            [9, 9, 9, 9],
            [9, 9, 9, 9],
        ]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: All column sums should be 18 (2 rows * 9)
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, 4, "Should have 4 column sums")
        for (index, sum) in sums!.enumerated() {
            XCTAssertEqual(sum, 18, "Column \(index) sum should be 18")
        }
    }

    func testCalculateColumnSums_MinimumTennerGridSize() {
        // Given: Minimum valid Tenner Grid size (5x5)
        let grid = [
            [1, 2, 3, 4, 5],
            [6, 7, 8, 9, 0],
            [0, 1, 2, 3, 4],
            [5, 6, 7, 8, 9],
            [9, 8, 7, 6, 5],
        ]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: Should return correct sums
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, 5, "Should have 5 column sums")
        XCTAssertEqual(sums?[0], 21, "Column 0 sum should be 1+6+0+5+9=21")
        XCTAssertEqual(sums?[1], 24, "Column 1 sum should be 2+7+1+6+8=24")
        XCTAssertEqual(sums?[2], 27, "Column 2 sum should be 3+8+2+7+7=27")
        XCTAssertEqual(sums?[3], 30, "Column 3 sum should be 4+9+3+8+6=30")
        XCTAssertEqual(sums?[4], 23, "Column 4 sum should be 5+0+4+9+5=23")
    }

    func testCalculateColumnSums_MaximumTennerGridSize() {
        // Given: Maximum valid Tenner Grid size (10x10)
        guard let grid = generator.generateCompletedGrid(rows: 10, columns: 10) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: Should return 10 column sums with valid ranges
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, 10, "Should have 10 column sums")

        for (index, sum) in sums!.enumerated() {
            // Each column sum should be between 0 (10 zeros) and 90 (10 nines)
            XCTAssertTrue(
                sum >= 0 && sum <= 90,
                "Column \(index) sum (\(sum)) should be between 0 and 90"
            )
        }
    }

    func testCalculateColumnSums_EmptyGrid() {
        // Given: An empty grid
        let emptyGrid: [[Int]] = []

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: emptyGrid)

        // Then: Should return nil
        XCTAssertNil(sums, "Should return nil for empty grid")
    }

    func testCalculateColumnSums_EmptyRow() {
        // Given: A grid with an empty row
        let gridWithEmptyRow: [[Int]] = [[]]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: gridWithEmptyRow)

        // Then: Should return nil
        XCTAssertNil(sums, "Should return nil for grid with empty row")
    }

    func testCalculateColumnSums_InconsistentRowLengths() {
        // Given: A grid with inconsistent row lengths (invalid)
        let invalidGrid = [
            [1, 2, 3],
            [4, 5],
            [6, 7, 8],
        ]

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: invalidGrid)

        // Then: Should return nil
        XCTAssertNil(sums, "Should return nil for grid with inconsistent row lengths")
    }

    func testCalculateColumnSums_WithGeneratedGrid() {
        // Given: A generated completed grid
        let rows = 7
        let columns = 8
        guard let grid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        // When: Calculating column sums
        let sums = generator.calculateColumnSums(from: grid)

        // Then: Should return valid column sums
        XCTAssertNotNil(sums, "Should return column sums")
        XCTAssertEqual(sums?.count, columns, "Should have correct number of column sums")

        // Verify sums by manually calculating them
        for col in 0 ..< columns {
            var expectedSum = 0
            for row in 0 ..< rows {
                expectedSum += grid[row][col]
            }
            XCTAssertEqual(
                sums?[col],
                expectedSum,
                "Column \(col) sum should match manually calculated sum"
            )
        }
    }

    func testCalculateColumnSums_MultipleGrids() {
        // Given: Multiple generated grids
        let attempts = 10
        var successCount = 0

        for _ in 0 ..< attempts {
            guard let grid = generator.generateCompletedGrid(rows: 6, columns: 6) else {
                continue
            }

            // When: Calculating column sums
            if let sums = generator.calculateColumnSums(from: grid) {
                successCount += 1

                // Then: Should have correct number of sums
                XCTAssertEqual(sums.count, 6, "Should have 6 column sums")

                // Verify each sum is within valid range
                for sum in sums {
                    XCTAssertTrue(
                        sum >= 0 && sum <= 54,
                        "Column sum (\(sum)) should be between 0 and 54"
                    )
                }
            }
        }

        XCTAssertEqual(successCount, attempts, "All column sum calculations should succeed")
    }

    func testCalculateColumnSums_ConsistencyWithHelperMethod() {
        // Given: A generated grid
        let rows = 5
        let columns = 5
        guard let grid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        // When: Calculating sums with both methods
        let sumsFromGenerator = generator.calculateColumnSums(from: grid)
        let sumsFromHelper = calculateColumnSums(grid: grid)

        // Then: Both should produce identical results
        XCTAssertNotNil(sumsFromGenerator, "Generator method should return sums")
        XCTAssertEqual(
            sumsFromGenerator?.count,
            sumsFromHelper.count,
            "Both methods should return same number of sums"
        )

        for col in 0 ..< columns {
            XCTAssertEqual(
                sumsFromGenerator?[col],
                sumsFromHelper[col],
                "Column \(col) sum should match between methods"
            )
        }
    }

    func testCalculateColumnSums_Performance() {
        // Given: A large grid
        guard let grid = generator.generateCompletedGrid(rows: 10, columns: 10) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        // When: Measuring calculation time
        measure {
            _ = generator.calculateColumnSums(from: grid)
        }

        // Then: Performance is measured
    }

    // MARK: - removeCells Tests

    func testRemoveCells_EasyDifficulty() {
        // Given: A completed grid and easy difficulty (45% pre-filled)
        let rows = 5
        let columns = 5
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        // Calculate column sums
        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Removing cells for easy difficulty
        let puzzleGrid = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .easy
        )

        // Then: Should successfully create a puzzle
        XCTAssertNotNil(puzzleGrid, "Should create a puzzle grid")

        if let puzzle = puzzleGrid {
            // Verify dimensions
            XCTAssertEqual(puzzle.count, rows, "Puzzle should have correct number of rows")
            XCTAssertEqual(puzzle[0].count, columns, "Puzzle should have correct number of columns")

            // Count pre-filled cells
            let filledCount = countFilledCells(grid: puzzle)
            let totalCells = rows * columns
            let filledPercentage = Double(filledCount) / Double(totalCells)

            // Should be close to 45% (allow some variance)
            XCTAssertTrue(
                filledPercentage >= 0.35 && filledPercentage <= 0.55,
                "Easy puzzle should have ~45% pre-filled cells, got \(filledPercentage * 100)%"
            )

            // Verify remaining cells match the original solution
            verifyConsistencyWithSolution(puzzleGrid: puzzle, solution: completedGrid)
        }
    }

    func testRemoveCells_MediumDifficulty() {
        // Given: A completed grid and medium difficulty (35% pre-filled)
        let rows = 6
        let columns = 6
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Removing cells for medium difficulty
        let puzzleGrid = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .medium
        )

        // Then: Should successfully create a puzzle
        XCTAssertNotNil(puzzleGrid, "Should create a puzzle grid")

        if let puzzle = puzzleGrid {
            let filledCount = countFilledCells(grid: puzzle)
            let totalCells = rows * columns
            let filledPercentage = Double(filledCount) / Double(totalCells)

            // Should be close to 35% (allow variance)
            XCTAssertTrue(
                filledPercentage >= 0.25 && filledPercentage <= 0.45,
                "Medium puzzle should have ~35% pre-filled cells, got \(filledPercentage * 100)%"
            )

            verifyConsistencyWithSolution(puzzleGrid: puzzle, solution: completedGrid)
        }
    }

    func testRemoveCells_HardDifficulty() {
        // Given: A completed grid and hard difficulty (25% pre-filled)
        let rows = 5
        let columns = 5
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Removing cells for hard difficulty
        let puzzleGrid = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .hard
        )

        // Then: Should successfully create a puzzle
        XCTAssertNotNil(puzzleGrid, "Should create a puzzle grid")

        if let puzzle = puzzleGrid {
            let filledCount = countFilledCells(grid: puzzle)
            let totalCells = rows * columns
            let filledPercentage = Double(filledCount) / Double(totalCells)

            // Should be close to 25% (allow variance)
            XCTAssertTrue(
                filledPercentage >= 0.15 && filledPercentage <= 0.35,
                "Hard puzzle should have ~25% pre-filled cells, got \(filledPercentage * 100)%"
            )

            verifyConsistencyWithSolution(puzzleGrid: puzzle, solution: completedGrid)
        }
    }

    func testRemoveCells_ExpertDifficulty() {
        // Given: A completed grid and expert difficulty (15% pre-filled)
        let rows = 5
        let columns = 5
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Removing cells for expert difficulty
        let puzzleGrid = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .expert
        )

        // Then: Should successfully create a puzzle (may be challenging)
        XCTAssertNotNil(puzzleGrid, "Should create a puzzle grid")

        if let puzzle = puzzleGrid {
            let filledCount = countFilledCells(grid: puzzle)
            let totalCells = rows * columns
            let filledPercentage = Double(filledCount) / Double(totalCells)

            // Should be close to 15% (allow variance)
            XCTAssertTrue(
                filledPercentage >= 0.10 && filledPercentage <= 0.30,
                "Expert puzzle should have ~15% pre-filled cells, got \(filledPercentage * 100)%"
            )

            verifyConsistencyWithSolution(puzzleGrid: puzzle, solution: completedGrid)
        }
    }

    func testRemoveCells_WithSeed_Deterministic() {
        // Given: Same completed grid and seed
        let rows = 5
        let columns = 5
        let seed: UInt64 = 99999
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns, seed: seed) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Removing cells with the same seed twice
        let puzzle1 = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .medium,
            seed: seed
        )

        let puzzle2 = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .medium,
            seed: seed
        )

        // Then: Should generate identical puzzles
        XCTAssertNotNil(puzzle1, "First puzzle should be generated")
        XCTAssertNotNil(puzzle2, "Second puzzle should be generated")

        if let p1 = puzzle1, let p2 = puzzle2 {
            XCTAssertEqual(p1.count, p2.count, "Puzzles should have same number of rows")
            for row in 0 ..< p1.count {
                XCTAssertEqual(p1[row].count, p2[row].count, "Rows should have same length")
                for col in 0 ..< p1[row].count {
                    XCTAssertEqual(
                        p1[row][col],
                        p2[row][col],
                        "Cell at (\(row),\(col)) should be identical"
                    )
                }
            }
        }
    }

    func testRemoveCells_InvalidGrid_Empty() {
        // Given: Empty grid
        let emptyGrid: [[Int]] = []
        let targetSums: [Int] = []

        // When: Attempting to remove cells from empty grid
        let result = generator.removeCells(
            from: emptyGrid,
            targetSums: targetSums,
            difficulty: .easy
        )

        // Then: Should return nil
        XCTAssertNil(result, "Should return nil for empty grid")
    }

    func testRemoveCells_InvalidGrid_EmptyRow() {
        // Given: Grid with empty row
        let invalidGrid: [[Int]] = [[]]
        let targetSums: [Int] = []

        // When: Attempting to remove cells
        let result = generator.removeCells(
            from: invalidGrid,
            targetSums: targetSums,
            difficulty: .easy
        )

        // Then: Should return nil
        XCTAssertNil(result, "Should return nil for grid with empty row")
    }

    func testRemoveCells_ConsistentWithSolution() {
        // Given: A completed grid
        let rows = 6
        let columns = 6
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Removing cells
        let puzzleGrid = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .medium
        )

        // Then: All remaining filled cells should match the solution
        XCTAssertNotNil(puzzleGrid, "Should create a puzzle grid")

        if let puzzle = puzzleGrid {
            for row in 0 ..< rows {
                for col in 0 ..< columns {
                    if let puzzleValue = puzzle[row][col] {
                        let solutionValue = completedGrid[row][col]
                        XCTAssertEqual(
                            puzzleValue,
                            solutionValue,
                            "Filled cell at (\(row),\(col)) should match solution"
                        )
                    }
                }
            }
        }
    }

    func testRemoveCells_UniqueSolution() {
        // Given: A completed grid
        let rows = 5
        let columns = 5
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Removing cells
        let puzzleGrid = generator.removeCells(
            from: completedGrid,
            targetSums: targetSums,
            difficulty: .medium
        )

        // Then: The resulting puzzle should have a unique solution
        XCTAssertNotNil(puzzleGrid, "Should create a puzzle grid")

        if let puzzle = puzzleGrid {
            let testPuzzle = TennerGridPuzzle(
                id: UUID(),
                columns: columns,
                rows: rows,
                difficulty: .medium,
                targetSums: targetSums,
                initialGrid: puzzle,
                solution: completedGrid
            )

            let solver = PuzzleSolver()
            XCTAssertTrue(
                solver.hasUniqueSolution(puzzle: testPuzzle),
                "Generated puzzle should have a unique solution"
            )
        }
    }

    func testRemoveCells_MultipleGenerations_AllValid() {
        // Given: Standard dimensions
        let rows = 5
        let columns = 5
        let attempts = 5

        // When: Generating multiple puzzles
        var successCount = 0

        for _ in 0 ..< attempts {
            guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
                continue
            }

            let targetSums = calculateColumnSums(grid: completedGrid)

            if let puzzle = generator.removeCells(
                from: completedGrid,
                targetSums: targetSums,
                difficulty: .medium
            ) {
                successCount += 1

                // Verify puzzle is valid
                verifyConsistencyWithSolution(puzzleGrid: puzzle, solution: completedGrid)

                // Verify some cells were removed
                let filledCount = countFilledCells(grid: puzzle)
                let totalCells = rows * columns
                XCTAssertLessThan(
                    filledCount,
                    totalCells,
                    "Should have removed at least some cells"
                )
            }
        }

        // Then: Should successfully generate most puzzles
        XCTAssertTrue(
            successCount >= attempts / 2,
            "Should successfully generate at least half of the attempts"
        )
    }

    func testRemoveCells_Performance() {
        // Given: A completed grid
        let rows = 6
        let columns = 6
        guard let completedGrid = generator.generateCompletedGrid(rows: rows, columns: columns) else {
            XCTFail("Failed to generate completed grid")
            return
        }

        let targetSums = calculateColumnSums(grid: completedGrid)

        // When: Measuring cell removal time
        measure {
            _ = generator.removeCells(
                from: completedGrid,
                targetSums: targetSums,
                difficulty: .medium
            )
        }

        // Then: Performance is measured
    }

    // MARK: - Additional Helper Methods

    /// Calculates column sums from a completed grid
    private func calculateColumnSums(grid: [[Int]]) -> [Int] {
        guard !grid.isEmpty else { return [] }

        let rows = grid.count
        let columns = grid[0].count
        var sums: [Int] = []

        for col in 0 ..< columns {
            var sum = 0
            for row in 0 ..< rows {
                sum += grid[row][col]
            }
            sums.append(sum)
        }

        return sums
    }

    /// Counts the number of filled cells in a puzzle grid
    private func countFilledCells(grid: [[Int?]]) -> Int {
        var count = 0
        for row in grid {
            for cell in row {
                if cell != nil {
                    count += 1
                }
            }
        }
        return count
    }

    /// Verifies that all filled cells in the puzzle match the solution
    private func verifyConsistencyWithSolution(puzzleGrid: [[Int?]], solution: [[Int]]) {
        XCTAssertEqual(puzzleGrid.count, solution.count, "Should have same number of rows")

        for row in 0 ..< puzzleGrid.count {
            XCTAssertEqual(
                puzzleGrid[row].count,
                solution[row].count,
                "Row \(row) should have same number of columns"
            )

            for col in 0 ..< puzzleGrid[row].count {
                if let puzzleValue = puzzleGrid[row][col] {
                    let solutionValue = solution[row][col]
                    XCTAssertEqual(
                        puzzleValue,
                        solutionValue,
                        "Filled cell at (\(row),\(col)) should match solution"
                    )
                }
            }
        }
    }

    // MARK: - generatePuzzle Tests (Complete Puzzle Generation)

    func testGeneratePuzzle_MinimumSize_Easy() {
        // Given: Minimum dimensions and easy difficulty
        let rows = 5
        let columns = 5
        let difficulty = Difficulty.easy

        // When: Generating a complete puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: Should successfully generate a valid puzzle
        XCTAssertNotNil(puzzle, "Should generate a puzzle for minimum size")

        if let generatedPuzzle = puzzle {
            // Verify basic properties
            XCTAssertEqual(generatedPuzzle.rows, rows, "Puzzle should have correct number of rows")
            XCTAssertEqual(generatedPuzzle.columns, columns, "Puzzle should have correct number of columns")
            XCTAssertEqual(generatedPuzzle.difficulty, difficulty, "Puzzle should have correct difficulty")

            // Verify puzzle is valid
            XCTAssertTrue(generatedPuzzle.isValid(), "Generated puzzle should be valid")

            // Verify solution is complete and valid
            verifyCompleteSolution(puzzle: generatedPuzzle)

            // Verify initial grid has some empty cells
            verifyPuzzleHasEmptyCells(puzzle: generatedPuzzle)

            // Verify puzzle is solvable
            verifyPuzzleIsSolvable(puzzle: generatedPuzzle)
        }
    }

    func testGeneratePuzzle_MaximumSize_Hard() {
        // Given: Maximum dimensions and hard difficulty
        let rows = 10
        let columns = 10
        let difficulty = Difficulty.hard

        // When: Generating a complete puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: Should successfully generate a valid puzzle
        XCTAssertNotNil(puzzle, "Should generate a puzzle for maximum size")

        if let generatedPuzzle = puzzle {
            XCTAssertEqual(generatedPuzzle.rows, rows, "Puzzle should have correct number of rows")
            XCTAssertEqual(generatedPuzzle.columns, columns, "Puzzle should have correct number of columns")
            XCTAssertEqual(generatedPuzzle.difficulty, difficulty, "Puzzle should have correct difficulty")

            XCTAssertTrue(generatedPuzzle.isValid(), "Generated puzzle should be valid")
            verifyCompleteSolution(puzzle: generatedPuzzle)
            verifyPuzzleHasEmptyCells(puzzle: generatedPuzzle)
            verifyPuzzleIsSolvable(puzzle: generatedPuzzle)
        }
    }

    func testGeneratePuzzle_TypicalSize_Medium() {
        // Given: Typical dimensions and medium difficulty
        let rows = 7
        let columns = 8
        let difficulty = Difficulty.medium

        // When: Generating a complete puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: Should successfully generate a valid puzzle
        XCTAssertNotNil(puzzle, "Should generate a puzzle for typical size")

        if let generatedPuzzle = puzzle {
            XCTAssertEqual(generatedPuzzle.rows, rows, "Puzzle should have correct number of rows")
            XCTAssertEqual(generatedPuzzle.columns, columns, "Puzzle should have correct number of columns")
            XCTAssertEqual(generatedPuzzle.difficulty, difficulty, "Puzzle should have correct difficulty")

            XCTAssertTrue(generatedPuzzle.isValid(), "Generated puzzle should be valid")
            verifyCompleteSolution(puzzle: generatedPuzzle)
            verifyPuzzleHasEmptyCells(puzzle: generatedPuzzle)
            verifyPuzzleIsSolvable(puzzle: generatedPuzzle)
        }
    }

    func testGeneratePuzzle_AllDifficulties() {
        // Given: Standard dimensions and all difficulty levels
        let rows = 6
        let columns = 6
        let difficulties: [Difficulty] = [.easy, .medium, .hard, .expert]

        for difficulty in difficulties {
            // When: Generating a puzzle for each difficulty
            let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

            // Then: Should successfully generate valid puzzles for all difficulties
            XCTAssertNotNil(puzzle, "Should generate a puzzle for \(difficulty) difficulty")

            if let generatedPuzzle = puzzle {
                XCTAssertEqual(generatedPuzzle.difficulty, difficulty, "Puzzle should have correct difficulty")
                XCTAssertTrue(generatedPuzzle.isValid(), "Generated \(difficulty) puzzle should be valid")
                verifyCompleteSolution(puzzle: generatedPuzzle)
                verifyPuzzleIsSolvable(puzzle: generatedPuzzle)

                // Verify difficulty affects pre-filled percentage
                let filledCount = countFilledCells(grid: generatedPuzzle.initialGrid)
                let totalCells = rows * columns
                let filledPercentage = Double(filledCount) / Double(totalCells)
                let expectedPercentage = difficulty.prefilledPercentage

                // Allow some variance (±10%)
                XCTAssertTrue(
                    abs(filledPercentage - expectedPercentage) < 0.15,
                    "Difficulty \(difficulty) should have ~\(expectedPercentage * 100)% pre-filled, got \(filledPercentage * 100)%"
                )
            }
        }
    }

    func testGeneratePuzzle_InvalidDimensions_RowsTooSmall() {
        // Given: Invalid dimensions (rows < 5)
        let rows = 3
        let columns = 6

        // When: Attempting to generate a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: .easy)

        // Then: Should return nil for invalid dimensions
        XCTAssertNil(puzzle, "Should return nil for rows < 5")
    }

    func testGeneratePuzzle_InvalidDimensions_ColumnsTooSmall() {
        // Given: Invalid dimensions (columns < 5)
        let rows = 6
        let columns = 4

        // When: Attempting to generate a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: .easy)

        // Then: Should return nil for invalid dimensions
        XCTAssertNil(puzzle, "Should return nil for columns < 5")
    }

    func testGeneratePuzzle_InvalidDimensions_RowsTooLarge() {
        // Given: Invalid dimensions (rows > 10)
        let rows = 12
        let columns = 6

        // When: Attempting to generate a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: .easy)

        // Then: Should return nil for invalid dimensions
        XCTAssertNil(puzzle, "Should return nil for rows > 10")
    }

    func testGeneratePuzzle_InvalidDimensions_ColumnsTooLarge() {
        // Given: Invalid dimensions (columns > 10)
        let rows = 6
        let columns = 15

        // When: Attempting to generate a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: .easy)

        // Then: Should return nil for invalid dimensions
        XCTAssertNil(puzzle, "Should return nil for columns > 10")
    }

    func testGeneratePuzzle_WithSeed_Deterministic() {
        // Given: Same parameters and seed
        let rows = 6
        let columns = 6
        let difficulty = Difficulty.medium
        let seed: UInt64 = 42

        // When: Generating multiple puzzles with same seed
        let puzzle1 = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty, seed: seed)
        let puzzle2 = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty, seed: seed)

        // Then: Should generate identical puzzles
        XCTAssertNotNil(puzzle1, "First puzzle should be generated")
        XCTAssertNotNil(puzzle2, "Second puzzle should be generated")

        if let p1 = puzzle1, let p2 = puzzle2 {
            // Verify initial grids are identical
            XCTAssertEqual(p1.initialGrid.count, p2.initialGrid.count, "Should have same number of rows")
            for row in 0 ..< p1.initialGrid.count {
                XCTAssertEqual(
                    p1.initialGrid[row].count,
                    p2.initialGrid[row].count,
                    "Row \(row) should have same length"
                )
                for col in 0 ..< p1.initialGrid[row].count {
                    XCTAssertEqual(
                        p1.initialGrid[row][col],
                        p2.initialGrid[row][col],
                        "Initial grid cell at (\(row),\(col)) should be identical"
                    )
                }
            }

            // Verify solutions are identical
            XCTAssertEqual(p1.solution, p2.solution, "Solutions should be identical")

            // Verify target sums are identical
            XCTAssertEqual(p1.targetSums, p2.targetSums, "Target sums should be identical")
        }
    }

    func testGeneratePuzzle_DifferentSeeds_DifferentPuzzles() {
        // Given: Same parameters but different seeds
        let rows = 6
        let columns = 6
        let difficulty = Difficulty.medium
        let seed1: UInt64 = 12345
        let seed2: UInt64 = 67890

        // When: Generating puzzles with different seeds
        let puzzle1 = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty, seed: seed1)
        let puzzle2 = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty, seed: seed2)

        // Then: Should generate different puzzles (highly likely)
        XCTAssertNotNil(puzzle1, "First puzzle should be generated")
        XCTAssertNotNil(puzzle2, "Second puzzle should be generated")

        if let p1 = puzzle1, let p2 = puzzle2 {
            // Solutions should be different
            XCTAssertNotEqual(p1.solution, p2.solution, "Different seeds should produce different solutions")
        }
    }

    func testGeneratePuzzle_ColumnSumsMatchSolution() {
        // Given: Standard puzzle generation
        let rows = 6
        let columns = 7
        let difficulty = Difficulty.medium

        // When: Generating a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: Column sums should match the solution
        XCTAssertNotNil(puzzle, "Should generate a puzzle")

        if let generatedPuzzle = puzzle {
            // Calculate column sums from solution
            let calculatedSums = calculateColumnSums(grid: generatedPuzzle.solution)

            // Verify they match the puzzle's target sums
            XCTAssertEqual(
                calculatedSums.count,
                generatedPuzzle.targetSums.count,
                "Should have same number of column sums"
            )

            for col in 0 ..< calculatedSums.count {
                XCTAssertEqual(
                    calculatedSums[col],
                    generatedPuzzle.targetSums[col],
                    "Column \(col) sum from solution should match target sum"
                )
            }
        }
    }

    func testGeneratePuzzle_SolutionFollowsAllRules() {
        // Given: Standard puzzle generation
        let rows = 7
        let columns = 7
        let difficulty = Difficulty.medium

        // When: Generating a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: Solution should follow all Tenner Grid rules
        XCTAssertNotNil(puzzle, "Should generate a puzzle")

        if let generatedPuzzle = puzzle {
            let solution = generatedPuzzle.solution

            // Verify no adjacent duplicates in solution
            verifyNoAdjacentDuplicates(grid: solution, rows: rows, columns: columns)

            // Verify no row duplicates in solution
            verifyNoRowDuplicates(grid: solution)

            // Verify all values are 0-9
            for row in solution {
                for value in row {
                    XCTAssertTrue(value >= 0 && value <= 9, "All solution values should be 0-9")
                }
            }
        }
    }

    func testGeneratePuzzle_InitialGridMatchesSolution() {
        // Given: Standard puzzle generation
        let rows = 6
        let columns = 6
        let difficulty = Difficulty.easy

        // When: Generating a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: All filled cells in initial grid should match solution
        XCTAssertNotNil(puzzle, "Should generate a puzzle")

        if let generatedPuzzle = puzzle {
            verifyConsistencyWithSolution(
                puzzleGrid: generatedPuzzle.initialGrid,
                solution: generatedPuzzle.solution
            )
        }
    }

    func testGeneratePuzzle_HasUniqueSolution() {
        // Given: Standard puzzle generation
        let rows = 6
        let columns = 6
        let difficulty = Difficulty.medium

        // When: Generating a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: Puzzle should have a unique solution
        XCTAssertNotNil(puzzle, "Should generate a puzzle")

        if let generatedPuzzle = puzzle {
            let solver = PuzzleSolver()
            XCTAssertTrue(
                solver.hasUniqueSolution(puzzle: generatedPuzzle),
                "Generated puzzle should have a unique solution"
            )
        }
    }

    func testGeneratePuzzle_IsSolvable() {
        // Given: Standard puzzle generation
        let rows = 5
        let columns = 5
        let difficulty = Difficulty.medium

        // When: Generating a puzzle
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)

        // Then: Puzzle should be solvable
        XCTAssertNotNil(puzzle, "Should generate a puzzle")

        if let generatedPuzzle = puzzle {
            let solver = PuzzleSolver()
            if let solvedGrid = solver.solve(puzzle: generatedPuzzle) {
                // Verify solved grid matches the original solution
                XCTAssertEqual(
                    solvedGrid,
                    generatedPuzzle.solution,
                    "Solved grid should match the original solution"
                )
            } else {
                XCTFail("Generated puzzle should be solvable")
            }
        }
    }

    func testGeneratePuzzle_MultipleGenerations_AllValid() {
        // Given: Standard parameters
        let rows = 5
        let columns = 5
        let difficulty = Difficulty.easy
        let attempts = 10

        // When: Generating multiple puzzles
        var successCount = 0
        var validCount = 0
        var solvableCount = 0

        for _ in 0 ..< attempts {
            if let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty) {
                successCount += 1

                // Verify puzzle is valid
                if puzzle.isValid() {
                    validCount += 1
                }

                // Verify puzzle is solvable
                let solver = PuzzleSolver()
                if solver.solve(puzzle: puzzle) != nil {
                    solvableCount += 1
                }

                // Verify solution follows rules
                verifyNoAdjacentDuplicates(grid: puzzle.solution, rows: rows, columns: columns)
                verifyNoRowDuplicates(grid: puzzle.solution)
            }
        }

        // Then: Should successfully generate and validate all puzzles
        XCTAssertEqual(successCount, attempts, "Should generate all puzzles successfully")
        XCTAssertEqual(validCount, attempts, "All generated puzzles should be valid")
        XCTAssertEqual(solvableCount, attempts, "All generated puzzles should be solvable")
    }

    func testGeneratePuzzle_CreatedAtDate() {
        // Given: Standard puzzle generation
        let rows = 6
        let columns = 6
        let difficulty = Difficulty.medium

        // When: Generating a puzzle
        let beforeGeneration = Date()
        let puzzle = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)
        let afterGeneration = Date()

        // Then: Puzzle should have a createdAt date within the generation timeframe
        XCTAssertNotNil(puzzle, "Should generate a puzzle")

        if let generatedPuzzle = puzzle {
            XCTAssertNotNil(generatedPuzzle.createdAt, "Puzzle should have a createdAt date")

            if let createdAt = generatedPuzzle.createdAt {
                XCTAssertTrue(
                    createdAt >= beforeGeneration && createdAt <= afterGeneration,
                    "createdAt should be within generation timeframe"
                )
            }
        }
    }

    func testGeneratePuzzle_Performance_SmallGrid() {
        // Given: Small grid dimensions
        let rows = 5
        let columns = 5
        let difficulty = Difficulty.easy

        // When: Measuring puzzle generation time
        measure {
            _ = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)
        }

        // Then: Performance is measured
    }

    func testGeneratePuzzle_Performance_LargeGrid() {
        // Given: Large grid dimensions
        let rows = 10
        let columns = 10
        let difficulty = Difficulty.medium

        // When: Measuring puzzle generation time
        measure {
            _ = generator.generatePuzzle(columns: columns, rows: rows, difficulty: difficulty)
        }

        // Then: Performance is measured
    }

    func testGeneratePuzzle_DailyPuzzle_Deterministic() {
        // Given: Same seed representing a specific date
        let rows = 6
        let columns = 6
        let difficulty = Difficulty.medium

        // Simulate daily puzzle by using date as seed
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let seed = UInt64(components.year! * 10000 + components.month! * 100 + components.day!)

        // When: Generating multiple "daily" puzzles with same seed
        let dailyPuzzle1 = generator.generatePuzzle(
            columns: columns,
            rows: rows,
            difficulty: difficulty,
            seed: seed
        )
        let dailyPuzzle2 = generator.generatePuzzle(
            columns: columns,
            rows: rows,
            difficulty: difficulty,
            seed: seed
        )

        // Then: Should generate identical puzzles for the same "day"
        XCTAssertNotNil(dailyPuzzle1, "First daily puzzle should be generated")
        XCTAssertNotNil(dailyPuzzle2, "Second daily puzzle should be generated")

        if let p1 = dailyPuzzle1, let p2 = dailyPuzzle2 {
            XCTAssertEqual(p1.solution, p2.solution, "Daily puzzles with same seed should be identical")
            XCTAssertEqual(p1.targetSums, p2.targetSums, "Target sums should be identical")
        }
    }

    // MARK: - Additional Validation Helper Methods

    /// Verifies that a puzzle's solution is complete and contains all required data
    private func verifyCompleteSolution(puzzle: TennerGridPuzzle) {
        // Verify solution dimensions match puzzle dimensions
        XCTAssertEqual(
            puzzle.solution.count,
            puzzle.rows,
            "Solution should have correct number of rows"
        )

        for (index, row) in puzzle.solution.enumerated() {
            XCTAssertEqual(
                row.count,
                puzzle.columns,
                "Solution row \(index) should have correct number of columns"
            )

            // Verify all values are in valid range (0-9)
            for (colIndex, value) in row.enumerated() {
                XCTAssertTrue(
                    value >= 0 && value <= 9,
                    "Solution value at (\(index),\(colIndex)) should be between 0 and 9, got \(value)"
                )
            }
        }
    }

    /// Verifies that a puzzle has at least some empty cells (is not fully filled)
    private func verifyPuzzleHasEmptyCells(puzzle: TennerGridPuzzle) {
        let filledCount = countFilledCells(grid: puzzle.initialGrid)
        let totalCells = puzzle.rows * puzzle.columns

        XCTAssertLessThan(
            filledCount,
            totalCells,
            "Puzzle should have at least some empty cells"
        )

        XCTAssertGreaterThan(
            filledCount,
            0,
            "Puzzle should have at least some pre-filled cells"
        )
    }

    /// Verifies that a puzzle can be solved by the solver
    private func verifyPuzzleIsSolvable(puzzle: TennerGridPuzzle) {
        let solver = PuzzleSolver()
        guard let solvedGrid = solver.solve(puzzle: puzzle) else {
            XCTFail("Puzzle should be solvable")
            return
        }

        // Verify solved grid matches the original solution
        XCTAssertEqual(
            solvedGrid,
            puzzle.solution,
            "Solved grid should match the original solution"
        )
    }
}
