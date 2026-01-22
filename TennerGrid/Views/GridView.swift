//
//  GridView.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import SwiftUI

/// A view displaying the complete Tenner Grid puzzle
struct GridView: View {
    // MARK: - Properties

    /// The current game state
    @ObservedObject var viewModel: GameViewModel

    // MARK: - Constants

    private let spacing: CGFloat = 2
    private let columnSumHeight: CGFloat = 40
    private let gridPadding: CGFloat = 16

    // MARK: - Body

    var body: some View {
        VStack(spacing: spacing) {
            // Main grid
            gridContent

            // Column sums
            columnSumsView
        }
        .padding(gridPadding)
    }

    // MARK: - Subviews

    /// The main grid layout with cells
    private var gridContent: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: spacing
        ) {
            ForEach(0 ..< totalCells, id: \.self) { index in
                let position = cellPosition(for: index)
                let cell = viewModel.cell(at: position)

                CellView(cell: cell) {
                    viewModel.selectCell(at: position)
                }
            }
        }
    }

    /// Column sums display below the grid
    private var columnSumsView: some View {
        HStack(spacing: spacing) {
            ForEach(0 ..< columnCount, id: \.self) { column in
                columnSumCell(for: column)
            }
        }
    }

    /// Individual column sum cell
    /// - Parameter column: The column index
    /// - Returns: View displaying the target sum for the column
    private func columnSumCell(for column: Int) -> some View {
        let targetSum = viewModel.gameState.puzzle.targetSums[column]
        let currentSum = viewModel.columnSum(for: column)
        let isComplete = viewModel.isColumnComplete(column)
        let isValid = currentSum == targetSum

        return VStack(spacing: 4) {
            // Current sum (if any values filled)
            if currentSum > 0 {
                Text(String(currentSum))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(sumColor(isComplete: isComplete, isValid: isValid))
            }

            // Target sum
            Text(String(targetSum))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: columnSumHeight)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(sumBackgroundColor(isComplete: isComplete, isValid: isValid))
        )
    }

    // MARK: - Helper Methods

    /// Calculate grid columns for LazyVGrid
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    /// Total number of cells in the grid
    private var totalCells: Int {
        rowCount * columnCount
    }

    /// Number of columns in the puzzle
    private var columnCount: Int {
        viewModel.gameState.puzzle.columns
    }

    /// Number of rows in the puzzle
    private var rowCount: Int {
        viewModel.gameState.puzzle.rows
    }

    /// Convert flat index to cell position
    /// - Parameter index: The flat index (0-based)
    /// - Returns: The corresponding CellPosition
    private func cellPosition(for index: Int) -> CellPosition {
        let row = index / columnCount
        let column = index % columnCount
        return CellPosition(row: row, column: column)
    }

    /// Determine the color for the sum text
    /// - Parameters:
    ///   - isComplete: Whether all cells in the column are filled
    ///   - isValid: Whether the current sum matches the target
    /// - Returns: The appropriate color
    private func sumColor(isComplete: Bool, isValid: Bool) -> Color {
        if isComplete {
            isValid ? .green : .red
        } else {
            .secondary
        }
    }

    /// Determine the background color for the sum cell
    /// - Parameters:
    ///   - isComplete: Whether all cells in the column are filled
    ///   - isValid: Whether the current sum matches the target
    /// - Returns: The appropriate background color
    private func sumBackgroundColor(isComplete: Bool, isValid: Bool) -> Color {
        if isComplete, isValid {
            Color.green.opacity(0.1)
        } else if isComplete, !isValid {
            Color.red.opacity(0.1)
        } else {
            Color.gray.opacity(0.05)
        }
    }
}

// MARK: - Previews

#Preview("5x5 Grid") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy)!
    GridView(viewModel: GameViewModel(puzzle: puzzle))
}

#Preview("7x5 Grid") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 7, rows: 5, difficulty: .easy)!
    GridView(viewModel: GameViewModel(puzzle: puzzle))
}

#Preview("10x5 Grid") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 10, rows: 5, difficulty: .easy)!
    GridView(viewModel: GameViewModel(puzzle: puzzle))
}

#Preview("Dark Mode") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 7, rows: 5, difficulty: .easy)!
    GridView(viewModel: GameViewModel(puzzle: puzzle))
        .preferredColorScheme(.dark)
}
