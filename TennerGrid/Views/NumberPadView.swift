import SwiftUI

/// A view displaying a number pad with buttons for digits 0-9
// swiftlint:disable:next swiftui_view_body
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
            // First row: 0-4
            HStack(spacing: spacing) {
                numberButton(for: 0)
                ForEach(1 ... 4, id: \.self) { number in
                    numberButton(for: number)
                }
            }

            // Second row: 5-9
            HStack(spacing: spacing) {
                ForEach(5 ... 9, id: \.self) { number in
                    numberButton(for: number)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Subviews

    /// Creates a button for a specific number
    /// - Parameter number: The number (0-9) to display
    /// - Returns: A button view
    private func numberButton(for number: Int) -> some View {
        let isSelected = isSelectedNumber(number)

        return Button {
            viewModel.enterNumber(number)
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .fill(buttonBackgroundColor(for: number))

                // Border
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .strokeBorder(buttonBorderColor(for: number), lineWidth: isSelected ? 2 : 1)

                // Number
                Text(String(number))
                    .font(.system(size: 24, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(buttonTextColor(for: number))

                // Conflict count badge
                conflictBadge(for: number)
            }
            .frame(width: buttonSize, height: buttonSize)
            .shadow(
                color: isSelected ? Color.blue.opacity(0.4) : Color.clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
            .opacity(isNumberDisabled(for: number) ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isNumberDisabled(for: number))
    }

    /// Creates a badge showing conflict count for a number
    /// - Parameter number: The number to check
    /// - Returns: A badge view showing conflict count, or empty view if no conflicts
    @ViewBuilder
    private func conflictBadge(for number: Int) -> some View {
        let conflicts = conflictCount(for: number)
        if conflicts > 0 {
            VStack {
                HStack {
                    Spacer()
                    Text("\(conflicts)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.red))
                }
                Spacer()
            }
            .padding(4)
        }
    }

    /// Gets the conflict count for a number at the selected position
    /// - Parameter number: The number to check
    /// - Returns: The number of conflicts (0 if valid or no selection)
    private func conflictCount(for number: Int) -> Int {
        // Don't show conflicts in notes mode
        guard !viewModel.notesMode else { return 0 }

        guard let selected = viewModel.selectedPosition else { return 0 }

        // Don't show conflicts if cell is not editable
        guard viewModel.isEditable(at: selected) else { return 0 }

        // Don't show conflicts if cell already has this value
        if let currentValue = viewModel.value(at: selected),
           currentValue == number
        {
            return 0
        }

        return viewModel.conflictCount(for: number, at: selected)
    }

    // MARK: - Styling Helpers

    /// Checks if a number is the currently selected cell's value
    /// - Parameter number: The number to check
    /// - Returns: True if this number matches the selected cell's value
    private func isSelectedNumber(_ number: Int) -> Bool {
        guard let selected = viewModel.selectedPosition,
              let selectedValue = viewModel.value(at: selected)
        else {
            return false
        }
        return selectedValue == number
    }

    /// Background color for a number button
    /// - Parameter number: The number
    /// - Returns: The background color
    private func buttonBackgroundColor(for number: Int) -> Color {
        guard let selected = viewModel.selectedPosition else {
            return Color.themeButtonSecondary
        }

        // Highlight if this is the currently selected cell's value
        // Use a filled blue background to make it stand out prominently
        if isSelectedNumber(number) {
            return Color.blue
        }

        // Check if this number would be invalid
        if !viewModel.notesMode,
           !viewModel.canPlaceValue(number, at: selected)
        {
            return Color.red.opacity(0.1)
        }

        return Color.themeButtonSecondary
    }

    /// Border color for a number button
    /// - Parameter number: The number
    /// - Returns: The border color
    private func buttonBorderColor(for number: Int) -> Color {
        guard let selected = viewModel.selectedPosition else {
            return Color.themeBorderColor
        }

        // Highlight if this is the currently selected cell's value
        // Use a darker blue border for the selected number
        if isSelectedNumber(number) {
            return Color.blue.opacity(0.8)
        }

        // Check if this number would be invalid
        if !viewModel.notesMode,
           !viewModel.canPlaceValue(number, at: selected)
        {
            return Color.red.opacity(0.5)
        }

        return Color.themeBorderColor
    }

    /// Text color for a number button
    /// - Parameter number: The number
    /// - Returns: The text color
    private func buttonTextColor(for number: Int) -> Color {
        guard let selected = viewModel.selectedPosition else {
            return .secondary
        }

        // Highlight if this is the currently selected cell's value
        // Use white text on the filled blue background for better contrast
        if isSelectedNumber(number) {
            return .white
        }

        // Check if this number would be invalid (dim the text)
        if !viewModel.notesMode,
           !viewModel.canPlaceValue(number, at: selected)
        {
            return .red.opacity(0.6)
        }

        return .primary
    }

    /// Checks if a number button should be disabled
    /// - Parameter number: The number
    /// - Returns: True if the button should be disabled
    private func isNumberDisabled(for number: Int) -> Bool {
        guard let selected = viewModel.selectedPosition else {
            return false
        }

        // Don't disable in notes mode
        if viewModel.notesMode {
            return false
        }

        // Check if cell is editable
        guard viewModel.isEditable(at: selected) else {
            return true
        }

        // Don't disable if cell already has this value
        if let currentValue = viewModel.value(at: selected),
           currentValue == number
        {
            return false
        }

        // Check if this placement would exceed the column's remaining sum
        if viewModel.wouldExceedColumnSum(number, at: selected) {
            return true
        }

        // Check if this placement would be invalid (violates game rules)
        return !viewModel.canPlaceValue(number, at: selected)
    }
}

// MARK: - Previews

#Preview("Number Pad - Default") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy5Row)
    return NumberPadView(viewModel: viewModel)
        .padding()
}

#Preview("Number Pad - Cell Selected") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy5Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    return NumberPadView(viewModel: viewModel)
        .padding()
}

#Preview("Number Pad - With Value") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy5Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    viewModel.enterNumber(5)
    return NumberPadView(viewModel: viewModel)
        .padding()
}

#Preview("Number Pad - Selected Number Highlighted") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy5Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    viewModel.enterNumber(5)
    return VStack(spacing: 20) {
        Text("Button '5' should be highlighted blue")
            .font(.caption)
            .foregroundColor(.secondary)
        NumberPadView(viewModel: viewModel)
    }
    .padding()
}

#Preview("Number Pad - Dark Mode") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy5Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    viewModel.enterNumber(7)
    return NumberPadView(viewModel: viewModel)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("iPhone SE") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy5Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    viewModel.enterNumber(3)
    return NumberPadView(viewModel: viewModel)
        .padding()
}

#Preview("iPad") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy5Row)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    viewModel.enterNumber(8)
    return NumberPadView(viewModel: viewModel)
        .padding()
}
