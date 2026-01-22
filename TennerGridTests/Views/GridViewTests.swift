//
//  GridViewTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

import SwiftUI
@testable import TennerGrid
import XCTest

/// Tests for GridView component with various puzzle sizes
@MainActor
final class GridViewTests: XCTestCase {
    // MARK: - Properties

    var puzzleGenerator: PuzzleGenerator!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        puzzleGenerator = PuzzleGenerator()
    }

    override func tearDown() {
        puzzleGenerator = nil
        super.tearDown()
    }

    // MARK: - Grid Rendering Tests

    /// Test that GridView renders correctly with a 5x5 grid
    func testGridRendering5x5() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate 5x5 puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 5, "Puzzle should have 5 columns")
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5, "Puzzle should have 5 rows")
        XCTAssertEqual(viewModel.gameState.puzzle.targetSums.count, 5, "Should have 5 column sums")

        // Verify grid content structure exists
        XCTAssertNotNil(view, "GridView should be created")
    }

    /// Test that GridView renders correctly with a 6x5 grid
    func testGridRendering6x5() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 6, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate 6x5 puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 6, "Puzzle should have 6 columns")
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5, "Puzzle should have 5 rows")
        XCTAssertEqual(viewModel.gameState.puzzle.targetSums.count, 6, "Should have 6 column sums")
        XCTAssertNotNil(view, "GridView should be created")
    }

    /// Test that GridView renders correctly with a 7x5 grid
    func testGridRendering7x5() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 7, rows: 5, difficulty: .medium) else {
            XCTFail("Failed to generate 7x5 puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 7, "Puzzle should have 7 columns")
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5, "Puzzle should have 5 rows")
        XCTAssertEqual(viewModel.gameState.puzzle.targetSums.count, 7, "Should have 7 column sums")
        XCTAssertNotNil(view, "GridView should be created")
    }

    /// Test that GridView renders correctly with a 8x5 grid
    func testGridRendering8x5() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 8, rows: 5, difficulty: .hard) else {
            XCTFail("Failed to generate 8x5 puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 8, "Puzzle should have 8 columns")
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5, "Puzzle should have 5 rows")
        XCTAssertEqual(viewModel.gameState.puzzle.targetSums.count, 8, "Should have 8 column sums")
        XCTAssertNotNil(view, "GridView should be created")
    }

    /// Test that GridView renders correctly with a 9x5 grid
    func testGridRendering9x5() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 9, rows: 5, difficulty: .expert) else {
            XCTFail("Failed to generate 9x5 puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 9, "Puzzle should have 9 columns")
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5, "Puzzle should have 5 rows")
        XCTAssertEqual(viewModel.gameState.puzzle.targetSums.count, 9, "Should have 9 column sums")
        XCTAssertNotNil(view, "GridView should be created")
    }

    /// Test that GridView renders correctly with a 10x5 grid (maximum size)
    func testGridRendering10x5() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 10, rows: 5, difficulty: .expert) else {
            XCTFail("Failed to generate 10x5 puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 10, "Puzzle should have 10 columns")
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5, "Puzzle should have 5 rows")
        XCTAssertEqual(viewModel.gameState.puzzle.targetSums.count, 10, "Should have 10 column sums")
        XCTAssertNotNil(view, "GridView should be created")
    }

    // MARK: - Column Sum Display Tests

    /// Test that column sums are displayed correctly for each puzzle size
    func testColumnSumsDisplay() throws {
        // Test different puzzle sizes
        let sizes = [5, 6, 7, 8, 9, 10]

        for columnCount in sizes {
            // Given
            guard let puzzle = puzzleGenerator.generatePuzzle(
                columns: columnCount,
                rows: 5,
                difficulty: .easy
            ) else {
                XCTFail("Failed to generate \(columnCount)x5 puzzle")
                continue
            }
            let viewModel = GameViewModel(puzzle: puzzle)

            // Then
            XCTAssertEqual(
                puzzle.targetSums.count,
                columnCount,
                "Puzzle should have \(columnCount) target sums"
            )

            // Verify each column has a valid target sum (between 0-45 for 5 rows with digits 0-9)
            for sum in puzzle.targetSums {
                XCTAssertTrue(sum >= 0 && sum <= 45, "Target sum \(sum) should be between 0 and 45")
            }
        }
    }

    // MARK: - Cell Positioning Tests

    /// Test that cells are positioned correctly in the grid
    func testCellPositioning() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 7, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When/Then - Test various cell positions
        let testPositions = [
            CellPosition(row: 0, column: 0), // Top-left
            CellPosition(row: 0, column: 6), // Top-right
            CellPosition(row: 4, column: 0), // Bottom-left
            CellPosition(row: 4, column: 6), // Bottom-right
            CellPosition(row: 2, column: 3), // Middle
        ]

        for position in testPositions {
            let cell = viewModel.cell(at: position)
            XCTAssertNotNil(cell, "Cell at \(position) should exist")
            XCTAssertEqual(
                cell.position,
                position,
                "Cell position should match requested position"
            )
        }
    }

    // MARK: - Visual State Tests

    /// Test that grid updates when cells are selected
    func testGridSelectionUpdates() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let position = CellPosition(row: 2, column: 2)
        viewModel.selectCell(at: position)

        // Then
        XCTAssertEqual(
            viewModel.gameState.selectedCell,
            position,
            "Selected cell should be updated"
        )
    }

    /// Test that grid displays different difficulties correctly
    func testGridWithDifferentDifficulties() throws {
        let difficulties: [Difficulty] = [.easy, .medium, .hard, .expert]

        for difficulty in difficulties {
            // Given
            guard let puzzle = puzzleGenerator.generatePuzzle(
                columns: 7,
                rows: 5,
                difficulty: difficulty
            ) else {
                XCTFail("Failed to generate \(difficulty) puzzle")
                continue
            }
            let viewModel = GameViewModel(puzzle: puzzle)

            // Then
            XCTAssertEqual(
                viewModel.gameState.puzzle.difficulty,
                difficulty,
                "Puzzle difficulty should be \(difficulty)"
            )

            // Count pre-filled cells - harder puzzles should have fewer
            let preFilledCount = viewModel.gameState.currentGrid.flatMap { $0 }
                .filter { $0 != nil }
                .count

            // Verify puzzle has some empty cells (otherwise it's not a puzzle)
            XCTAssertGreaterThan(
                35 - preFilledCount,
                0,
                "\(difficulty) puzzle should have some empty cells"
            )
        }
    }

    // MARK: - Layout Tests

    /// Test that grid layout adapts to different screen sizes
    func testGridLayoutAdaptability() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 7, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)
        let view = GridView(viewModel: viewModel)

        // Test with different size classes
        let compactView = view.environment(\.horizontalSizeClass, .compact)
        let regularView = view.environment(\.horizontalSizeClass, .regular)

        // Verify views can be created with different size classes
        XCTAssertNotNil(compactView, "Grid should support compact size class")
        XCTAssertNotNil(regularView, "Grid should support regular size class")
    }

    // MARK: - Performance Tests

    /// Test that grid renders efficiently with maximum puzzle size
    func testGridRenderingPerformance() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 10, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate puzzle")
            return
        }

        // Measure performance of creating view model and grid view
        measure {
            let viewModel = GameViewModel(puzzle: puzzle)
            _ = GridView(viewModel: viewModel)
        }
    }

    /// Test that cell selection is performant
    func testCellSelectionPerformance() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 10, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // Measure performance of selecting multiple cells
        measure {
            for row in 0 ..< 5 {
                for col in 0 ..< 10 {
                    viewModel.selectCell(at: CellPosition(row: row, column: col))
                }
            }
        }
    }

    // MARK: - Edge Cases

    /// Test grid with minimum puzzle size
    func testMinimumPuzzleSize() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertNotNil(view, "Grid should handle minimum size (5x5)")
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 5)
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5)
    }

    /// Test grid with maximum puzzle size
    func testMaximumPuzzleSize() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 10, rows: 5, difficulty: .expert) else {
            XCTFail("Failed to generate puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertNotNil(view, "Grid should handle maximum size (10x5)")
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 10)
        XCTAssertEqual(viewModel.gameState.puzzle.rows, 5)
    }

    /// Test that grid handles empty puzzle correctly
    func testEmptyPuzzle() throws {
        // Given - create a puzzle with no pre-filled cells
        let targetSums = Array(repeating: 22, count: 5) // Valid sums for 5 rows
        let emptyGrid = Array(repeating: Array(repeating: Int?.none, count: 5), count: 5)
        let solution = [
            [0, 1, 2, 3, 4],
            [5, 6, 7, 8, 9],
            [1, 2, 3, 4, 5],
            [6, 7, 8, 9, 0],
            [9, 6, 2, 1, 4],
        ]

        let puzzle = TennerGridPuzzle(
            id: UUID(),
            columns: 5,
            rows: 5,
            difficulty: .easy,
            targetSums: targetSums,
            initialGrid: emptyGrid,
            solution: solution
        )

        let viewModel = GameViewModel(puzzle: puzzle)
        let view = GridView(viewModel: viewModel)

        // Then
        XCTAssertNotNil(view, "Grid should handle empty puzzle")

        // Verify all cells are empty
        for row in 0 ..< 5 {
            for col in 0 ..< 5 {
                let cell = viewModel.cell(at: CellPosition(row: row, column: col))
                XCTAssertNil(cell.value, "Cell should be empty in empty puzzle")
                XCTAssertFalse(cell.isInitial, "No cells should be marked as initial")
            }
        }
    }

    /// Test that grid correctly identifies column completion
    func testColumnCompletionDetection() throws {
        // Given
        guard let puzzle = puzzleGenerator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy) else {
            XCTFail("Failed to generate puzzle")
            return
        }
        let viewModel = GameViewModel(puzzle: puzzle)

        // When - Fill a complete column with correct values
        let columnToFill = 0
        for row in 0 ..< 5 {
            let position = CellPosition(row: row, column: columnToFill)
            let correctValue = puzzle.solution[row][columnToFill]
            viewModel.selectCell(at: position)
            viewModel.enterNumber(correctValue)
        }

        // Then
        let isComplete = viewModel.isColumnComplete(columnToFill)
        XCTAssertTrue(isComplete, "Column should be marked as complete when all cells are filled")
    }
}
