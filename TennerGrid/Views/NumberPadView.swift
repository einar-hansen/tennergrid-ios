//
//  NumberPadView.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import SwiftUI

/// A view displaying a number pad with buttons for digits 0-9
struct NumberPadView: View {
    // MARK: - Properties

    /// The view model managing game state
    @ObservedObject var viewModel: GameViewModel

    // MARK: - Constants

    private let buttonSize: CGFloat = 60
    private let buttonCornerRadius: CGFloat = 8
    private let spacing: CGFloat = 8

    // MARK: - Body

    var body: some View {
        VStack(spacing: spacing) {
            // First row: 1-5
            HStack(spacing: spacing) {
                ForEach(1 ... 5, id: \.self) { number in
                    numberButton(for: number)
                }
            }

            // Second row: 6-9, 0
            HStack(spacing: spacing) {
                ForEach(6 ... 9, id: \.self) { number in
                    numberButton(for: number)
                }
                numberButton(for: 0)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Subviews

    /// Creates a button for a specific number
    /// - Parameter number: The number (0-9) to display
    /// - Returns: A button view
    private func numberButton(for number: Int) -> some View {
        Button {
            viewModel.enterNumber(number)
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .fill(buttonBackgroundColor(for: number))

                // Border
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .strokeBorder(buttonBorderColor(for: number), lineWidth: 1)

                // Number
                Text(String(number))
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(buttonTextColor(for: number))
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Styling Helpers

    /// Background color for a number button
    /// - Parameter number: The number
    /// - Returns: The background color
    private func buttonBackgroundColor(for number: Int) -> Color {
        guard let selected = viewModel.selectedPosition else {
            return Color.gray.opacity(0.1)
        }

        // Highlight if this is the currently selected cell's value
        if let selectedValue = viewModel.value(at: selected),
           selectedValue == number
        {
            return Color.blue.opacity(0.2)
        }

        return Color.gray.opacity(0.1)
    }

    /// Border color for a number button
    /// - Parameter number: The number
    /// - Returns: The border color
    private func buttonBorderColor(for number: Int) -> Color {
        guard let selected = viewModel.selectedPosition else {
            return Color.gray.opacity(0.3)
        }

        // Highlight if this is the currently selected cell's value
        if let selectedValue = viewModel.value(at: selected),
           selectedValue == number
        {
            return Color.blue
        }

        return Color.gray.opacity(0.3)
    }

    /// Text color for a number button
    /// - Parameter number: The number
    /// - Returns: The text color
    private func buttonTextColor(for number: Int) -> Color {
        guard let selected = viewModel.selectedPosition else {
            return .secondary
        }

        // Highlight if this is the currently selected cell's value
        if let selectedValue = viewModel.value(at: selected),
           selectedValue == number
        {
            return .blue
        }

        return .primary
    }
}

// MARK: - Previews

#Preview("Number Pad - Default") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy)!
    let viewModel = GameViewModel(puzzle: puzzle)

    return NumberPadView(viewModel: viewModel)
        .padding()
}

#Preview("Number Pad - Cell Selected") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy)!
    let viewModel = GameViewModel(puzzle: puzzle)

    // Select a cell
    _ = viewModel.selectCell(at: CellPosition(row: 0, column: 0))

    return NumberPadView(viewModel: viewModel)
        .padding()
}

#Preview("Number Pad - With Value") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy)!
    let viewModel = GameViewModel(puzzle: puzzle)

    // Select a cell and enter a value
    _ = viewModel.selectCell(at: CellPosition(row: 0, column: 0))
    _ = viewModel.enterNumber(5)

    return NumberPadView(viewModel: viewModel)
        .padding()
}

#Preview("Number Pad - Dark Mode") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy)!
    let viewModel = GameViewModel(puzzle: puzzle)

    // Select a cell and enter a value
    _ = viewModel.selectCell(at: CellPosition(row: 0, column: 0))
    _ = viewModel.enterNumber(7)

    return NumberPadView(viewModel: viewModel)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("iPhone SE") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy)!
    let viewModel = GameViewModel(puzzle: puzzle)

    _ = viewModel.selectCell(at: CellPosition(row: 0, column: 0))
    _ = viewModel.enterNumber(3)

    return NumberPadView(viewModel: viewModel)
        .padding()
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
}

#Preview("iPad") {
    let generator = PuzzleGenerator()
    let puzzle = generator.generatePuzzle(columns: 5, rows: 5, difficulty: .easy)!
    let viewModel = GameViewModel(puzzle: puzzle)

    _ = viewModel.selectCell(at: CellPosition(row: 0, column: 0))
    _ = viewModel.enterNumber(8)

    return NumberPadView(viewModel: viewModel)
        .padding()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
}
