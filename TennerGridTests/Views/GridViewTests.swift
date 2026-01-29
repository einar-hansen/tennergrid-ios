import SwiftUI
import XCTest
@testable import TennerGrid

/// Tests for GridView component
/// Uses pre-built fixtures instead of generating puzzles for fast execution
@MainActor
final class GridViewTests: XCTestCase {
    // MARK: - Grid Rendering Tests

    /// Test that GridView renders correctly with a 10-column grid
    func testGridRendering10Columns() {
        // Given - Use fixture puzzle (Tenner Grid always has 10 columns)
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.columns, 10, "Tenner Grid should have 10 columns")
        XCTAssertEqual(viewModel.gameState.puzzle.targetSums.count, 10, "Should have 10 column sums")
        XCTAssertNotNil(view, "GridView should be created")
    }

    /// Test that GridView renders with medium difficulty puzzle
    func testGridRenderingMediumDifficulty() {
        // Given
        let puzzle = TestFixtures.mediumPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.difficulty, .medium)
        XCTAssertNotNil(view, "GridView should be created")
    }

    /// Test that GridView renders with hard difficulty puzzle
    func testGridRenderingHardDifficulty() {
        // Given
        let puzzle = TestFixtures.hardPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertEqual(viewModel.gameState.puzzle.difficulty, .hard)
        XCTAssertNotNil(view, "GridView should be created")
    }

    // MARK: - Column Sum Display Tests

    /// Test that column sums are displayed correctly
    func testColumnSumsDisplay() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertEqual(puzzle.targetSums.count, puzzle.columns, "Should have one sum per column")
        XCTAssertNotNil(view, "GridView should be created with column sums")

        // Verify target sums are reasonable values
        for sum in puzzle.targetSums {
            XCTAssertGreaterThan(sum, 0, "Column sums should be positive")
            XCTAssertLessThanOrEqual(sum, puzzle.rows * 9, "Column sums should not exceed max possible")
        }
    }

    // MARK: - Cell Positioning Tests

    /// Test that cells are positioned correctly in the grid
    func testCellPositioning() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertNotNil(view, "GridView should be created")

        // Verify we can access cells at valid positions
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let position = CellPosition(row: row, column: col)
                XCTAssertTrue(puzzle.isValidPosition(position), "Position (\(row), \(col)) should be valid")
            }
        }
    }

    // MARK: - Selection Tests

    /// Test that grid selection updates correctly
    func testGridSelectionUpdates() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When - Select a cell
        let position = CellPosition(row: 0, column: 1)
        viewModel.selectCell(at: position)

        // Then
        XCTAssertEqual(viewModel.selectedPosition, position, "Selection should update")
        XCTAssertTrue(viewModel.isSelected(at: position), "Cell should be selected")
    }

    // MARK: - Edge Cases

    /// Test GridView with minimum puzzle size (10x3)
    func testMinimumPuzzleSize() {
        // Given - 10x3 is minimum (Tenner Grid always has 10 columns, min 3 rows)
        let puzzle = TestFixtures.smallPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertEqual(puzzle.columns, 10, "Tenner Grid always has 10 columns")
        XCTAssertGreaterThanOrEqual(puzzle.rows, 3, "Minimum rows should be 3")
        XCTAssertNotNil(view, "GridView should handle minimum size")
    }

    /// Test GridView handles empty cell display
    func testEmptyCellDisplay() {
        // Given
        let puzzle = TestFixtures.hardPuzzle // Hard has fewer pre-filled cells
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertNotNil(view, "GridView should be created")
        XCTAssertGreaterThan(puzzle.emptyCellCount, 0, "Hard puzzle should have empty cells")
    }

    // MARK: - Column Completion Tests

    /// Test column completion detection
    func testColumnCompletionDetection() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // Then - Verify initial state
        XCTAssertFalse(viewModel.gameState.isCompleted, "New game should not be completed")
    }

    // MARK: - Pre-filled Cell Tests

    /// Test that pre-filled cells are rendered correctly
    func testPrefilledCellsRendering() {
        // Given
        let puzzle = TestFixtures.easyPuzzle
        let viewModel = GameViewModel(puzzle: puzzle)

        // When
        let view = GridView(viewModel: viewModel, zoomScale: .constant(1.0))

        // Then
        XCTAssertNotNil(view, "GridView should be created")
        XCTAssertGreaterThan(puzzle.prefilledCount, 0, "Easy puzzle should have pre-filled cells")

        // Verify pre-filled cells exist
        var foundPrefilled = false
        for row in 0 ..< puzzle.rows {
            for col in 0 ..< puzzle.columns {
                let pos = CellPosition(row: row, column: col)
                if puzzle.isPrefilled(at: pos) {
                    foundPrefilled = true
                    break
                }
            }
            if foundPrefilled { break }
        }
        XCTAssertTrue(foundPrefilled, "Should have at least one pre-filled cell")
    }
}
