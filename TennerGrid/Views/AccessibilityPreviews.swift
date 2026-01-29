import SwiftUI

// SwiftUI previews for testing accessibility features, especially Dynamic Type with largest text sizes
// This file contains test previews for major views at various Dynamic Type sizes

// MARK: - Game View Accessibility Tests

#Preview("GameView - Default Size") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
        .testDynamicTypeSize(.large)
}

#Preview("GameView - XXX Large") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
        .testDynamicTypeSize(.xxxLarge)
}

#Preview("GameView - Accessibility Medium (a11y1)") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
        .testDynamicTypeSize(.accessibility1)
}

#Preview("GameView - Accessibility Large (a11y2)") {
    GameView(puzzle: PreviewPuzzles.medium4Row)
        .testDynamicTypeSize(.accessibility2)
}

#Preview("GameView - Accessibility XL (a11y3)") {
    GameView(puzzle: PreviewPuzzles.medium4Row)
        .testDynamicTypeSize(.accessibility3)
}

#Preview("GameView - Accessibility XXL (a11y4)") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
        .testDynamicTypeSize(.accessibility4)
}

#Preview("GameView - Maximum Size (a11y5)") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
        .testDynamicTypeSize(.accessibility5)
}

// MARK: - Component Tests with Size Comparisons

#Preview("GameHeader - Size Comparison") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.medium4Row)

    return DynamicTypeSizeComparison(
        title: "Game Header - Dynamic Type Test",
        sizes: AccessibilityTestSize.allSizes
    ) {
        GameHeaderView(
            viewModel: viewModel,
            onPause: {},
            onSettings: {}
        )
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview("NumberPad - Size Comparison") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))

    return DynamicTypeSizeComparison(
        title: "Number Pad - Dynamic Type Test",
        sizes: AccessibilityTestSize.criticalSizes
    ) {
        NumberPadView(viewModel: viewModel)
            .padding()
            .background(Color(.systemBackground))
    }
}

#Preview("GameToolbar - Size Comparison") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    viewModel.enterNumber(5)

    return DynamicTypeSizeComparison(
        title: "Game Toolbar - Dynamic Type Test",
        sizes: AccessibilityTestSize.allSizes
    ) {
        GameToolbarView(viewModel: viewModel)
            .padding()
            .background(Color(.systemBackground))
    }
}

#Preview("WinScreen - Size Comparison") {
    DynamicTypeSizeComparison(
        title: "Win Screen - Dynamic Type Test",
        sizes: AccessibilityTestSize.criticalSizes
    ) {
        WinScreenView(
            difficulty: .medium,
            elapsedTime: 325,
            hintsUsed: 1,
            errorCount: 3,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )
        .frame(height: 600)
    }
}

#Preview("PauseMenu - Size Comparison") {
    DynamicTypeSizeComparison(
        title: "Pause Menu - Dynamic Type Test",
        sizes: AccessibilityTestSize.criticalSizes
    ) {
        PauseMenuView(
            onResume: {},
            onRestart: {},
            onNewGame: {},
            onSettings: {},
            onQuit: {}
        )
        .frame(height: 400)
    }
}

// MARK: - Difficulty Selection Tests

#Preview("DifficultySelection - Default") {
    NavigationStack {
        DifficultySelectionView { _ in }
    }
    .testDynamicTypeSize(.large)
}

#Preview("DifficultySelection - Maximum Size") {
    NavigationStack {
        DifficultySelectionView { _ in }
    }
    .testDynamicTypeSize(.accessibility5)
}

// MARK: - Grid View Tests

#Preview("GridView - 3 Row Easy - Default") {
    struct PreviewWrapper: View {
        @State private var zoomScale: CGFloat = 1.0
        var body: some View {
            let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
            viewModel.selectCell(at: CellPosition(row: 1, column: 4))
            return GridView(viewModel: viewModel, zoomScale: $zoomScale)
                .padding()
                .testDynamicTypeSize(.large)
        }
    }
    return PreviewWrapper()
}

#Preview("GridView - 3 Row Easy - Maximum Size") {
    struct PreviewWrapper: View {
        @State private var zoomScale: CGFloat = 1.0
        var body: some View {
            let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
            viewModel.selectCell(at: CellPosition(row: 1, column: 4))
            return GridView(viewModel: viewModel, zoomScale: $zoomScale)
                .padding()
                .testDynamicTypeSize(.accessibility5)
        }
    }
    return PreviewWrapper()
}

#Preview("GridView - 5 Row Medium - Default") {
    struct PreviewWrapper: View {
        @State private var zoomScale: CGFloat = 1.0
        var body: some View {
            let viewModel = GameViewModel(puzzle: PreviewPuzzles.medium5Row)
            viewModel.selectCell(at: CellPosition(row: 2, column: 3))
            return GridView(viewModel: viewModel, zoomScale: $zoomScale)
                .padding()
                .testDynamicTypeSize(.large)
        }
    }
    return PreviewWrapper()
}

#Preview("GridView - 5 Row Medium - Maximum Size") {
    struct PreviewWrapper: View {
        @State private var zoomScale: CGFloat = 1.0
        var body: some View {
            let viewModel = GameViewModel(puzzle: PreviewPuzzles.medium5Row)
            viewModel.selectCell(at: CellPosition(row: 2, column: 3))
            return GridView(viewModel: viewModel, zoomScale: $zoomScale)
                .padding()
                .testDynamicTypeSize(.accessibility5)
        }
    }
    return PreviewWrapper()
}

// MARK: - Cell View Individual Tests

#Preview("CellView - Size Comparison") {
    DynamicTypeSizeComparison(
        title: "Cell View - Dynamic Type Test (Column Sums)",
        sizes: AccessibilityTestSize.criticalSizes
    ) {
        VStack(spacing: 16) {
            Text("Note: Cell numbers use fixed sizing. Testing column sum labels:")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                ForEach(0 ..< 10) { col in
                    VStack(spacing: 0) {
                        // Cell
                        CellView(
                            cell: Cell(
                                position: CellPosition(row: 0, column: col),
                                value: col,
                                isInitial: col % 2 == 0
                            ),
                            cellSize: 40,
                            onTap: {}
                        )

                        // Column sum label (uses Dynamic Type)
                        Text("\(col + 10)")
                            .font(.columnSum)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Edge Cases & Stress Tests

#Preview("Full Game Flow - Small Screen + Max Text") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
        .testDynamicTypeSize(.accessibility5)
        .frame(width: 375, height: 667) // iPhone SE size
}

#Preview("Full Game Flow - Large Puzzle + Max Text") {
    GameView(puzzle: PreviewPuzzles.hard7Row)
        .testDynamicTypeSize(.accessibility5)
}

#Preview("Win Screen - Landscape + Max Text") {
    WinScreenView(
        difficulty: .hard,
        elapsedTime: 1825,
        hintsUsed: 0,
        errorCount: 0,
        onNewGame: {},
        onChangeDifficulty: {},
        onHome: {}
    )
    .testDynamicTypeSize(.accessibility5)
    .frame(width: 844, height: 390) // Landscape orientation size
}
