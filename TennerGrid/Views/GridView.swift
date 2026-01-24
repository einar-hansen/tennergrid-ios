import SwiftUI

/// A view displaying the complete Tenner Grid puzzle
// swiftlint:disable:next swiftui_view_body
struct GridView: View {
    // MARK: - Properties

    /// The current game state
    @ObservedObject var viewModel: GameViewModel

    // MARK: - Constants

    private let rowSpacing: CGFloat = 2
    private let columnSpacing: CGFloat = 0
    private let columnSumHeight: CGFloat = 40
    private let gridPadding: CGFloat = 16

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: rowSpacing) {
                // Main grid
                gridContent(availableWidth: geometry.size.width - (gridPadding * 2))

                // Column sums
                columnSumsView(availableWidth: geometry.size.width - (gridPadding * 2))
            }
            .padding(gridPadding)
        }
    }

    // MARK: - Subviews

    /// The main grid layout with cells
    /// - Parameter availableWidth: The available width for the grid
    private func gridContent(availableWidth: CGFloat) -> some View {
        let cellSize = calculateCellSize(availableWidth: availableWidth)

        return LazyVGrid(
            columns: gridColumns(cellSize: cellSize),
            spacing: rowSpacing
        ) {
            ForEach(0 ..< totalCells, id: \.self) { index in
                let position = cellPosition(for: index)
                let cell = viewModel.cell(at: position)

                CellView(cell: cell, cellSize: cellSize) {
                    viewModel.selectCell(at: position)
                }
            }
        }
    }

    /// Column sums display below the grid
    /// - Parameter availableWidth: The available width for the grid
    private func columnSumsView(availableWidth: CGFloat) -> some View {
        let cellSize = calculateCellSize(availableWidth: availableWidth)

        return HStack(spacing: columnSpacing) {
            ForEach(0 ..< columnCount, id: \.self) { column in
                columnSumCell(for: column, cellSize: cellSize)
            }
        }
    }

    /// Individual column sum cell
    /// - Parameters:
    ///   - column: The column index
    ///   - cellSize: The width of each cell
    /// - Returns: View displaying the target sum for the column
    private func columnSumCell(for column: Int, cellSize: CGFloat) -> some View {
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
        .frame(width: cellSize)
        .frame(height: columnSumHeight)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(sumBackgroundColor(isComplete: isComplete, isValid: isValid))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Column \(column + 1)")
        .accessibilityValue(columnSumAccessibilityValue(
            column: column,
            current: currentSum,
            target: targetSum,
            isComplete: isComplete,
            isValid: isValid
        ))
    }

    // MARK: - Helper Methods

    /// Calculate grid columns for LazyVGrid with fixed cell size
    /// - Parameter cellSize: The size of each cell
    /// - Returns: Array of GridItem with fixed sizing
    private func gridColumns(cellSize: CGFloat) -> [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: columnSpacing), count: columnCount)
    }

    /// Calculate the appropriate cell size based on available width
    /// - Parameter availableWidth: The total width available for the grid
    /// - Returns: The calculated cell size that fits all columns without overlap
    private func calculateCellSize(availableWidth: CGFloat) -> CGFloat {
        // Calculate cell size: (available width - total spacing) / number of columns
        let totalSpacing = columnSpacing * CGFloat(columnCount - 1)
        let cellSize = (availableWidth - totalSpacing) / CGFloat(columnCount)

        // Return the calculated size, with a minimum of 30 and maximum of 60
        return min(max(cellSize, 30), 60)
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
            Color.themeTertiaryBackground
        }
    }

    // MARK: - Accessibility

    /// Accessibility value for column sum cell
    /// - Parameters:
    ///   - column: Column index
    ///   - current: Current sum
    ///   - target: Target sum
    ///   - isComplete: Whether column is complete
    ///   - isValid: Whether sum is valid
    /// - Returns: Accessibility value string
    private func columnSumAccessibilityValue(
        column: Int,
        current: Int,
        target: Int,
        isComplete: Bool,
        isValid: Bool
    ) -> String {
        if isComplete {
            if isValid {
                "Complete. Target \(target), Current \(current). Correct"
            } else {
                "Complete. Target \(target), Current \(current). Incorrect"
            }
        } else if current > 0 {
            "Target sum \(target), Current sum \(current), Remaining \(target - current)"
        } else {
            "Target sum \(target), No values entered yet"
        }
    }
}

// MARK: - Previews

#Preview("10x3 Grid") {
    GridView(viewModel: GameViewModel(puzzle: PreviewPuzzles.easy3Row))
}

#Preview("10x5 Grid") {
    GridView(viewModel: GameViewModel(puzzle: PreviewPuzzles.easy5Row))
}

#Preview("10x7 Grid") {
    GridView(viewModel: GameViewModel(puzzle: PreviewPuzzles.hard7Row))
}

#Preview("Dark Mode") {
    GridView(viewModel: GameViewModel(puzzle: PreviewPuzzles.medium5Row))
        .preferredColorScheme(.dark)
}
