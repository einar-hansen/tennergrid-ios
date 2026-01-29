import SwiftUI

/// A view displaying a number pad with buttons for digits 0-9
// swiftlint:disable:next swiftui_view_body
struct NumberPadView: View {
    // MARK: - Properties

    /// The view model managing game state
    @ObservedObject var viewModel: GameViewModel

    // MARK: - Environment

    /// Size class to detect iPad vs iPhone
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Constants

    /// Check if running on iPad based on size classes
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    /// Check if running on very compact width device (iPhone SE)
    private var isVeryCompact: Bool {
        horizontalSizeClass == .compact && UIScreen.main.bounds.width <= 320
    }

    /// Button size scales with device - larger on iPad, smaller on very compact devices
    private var buttonSize: CGFloat {
        if isIPad {
            80
        } else if isVeryCompact {
            52 // Smaller for iPhone SE to fit in 320pt width
        } else {
            60
        }
    }

    /// Corner radius scales with button size
    private var buttonCornerRadius: CGFloat {
        isIPad ? 10 : 8
    }

    /// Spacing between buttons scales with device
    private var spacing: CGFloat {
        isIPad ? 12 : 8
    }

    /// Horizontal padding scales with device - tighter on very compact devices
    private var horizontalPadding: CGFloat {
        if isIPad {
            16
        } else if isVeryCompact {
            12 // Tighter padding for iPhone SE
        } else {
            16
        }
    }

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
        .padding(.horizontal, horizontalPadding)
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
                    .font(.system(size: isIPad ? 32 : 24, weight: isSelected ? .bold : .medium, design: .rounded))
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
        .accessibilityIdentifier("NumberButton_\(number)")
        .accessibilityLabel("Number \(number)")
        .accessibilityValue(numberAccessibilityValue(for: number))
        .accessibilityHint(numberAccessibilityHint(for: number))
        .accessibilityAddTraits(isSelectedNumber(number) ? .isSelected : [])
    }

    /// Creates a badge showing conflict count for a number
    /// - Parameter number: The number to check
    /// - Returns: A badge view showing conflict count, or empty view if no conflicts
    @ViewBuilder
    private func conflictBadge(for number: Int) -> some View {
        let conflicts = conflictCount(for: number)
        if conflicts > 0 {
            let badgeSize: CGFloat = isIPad ? 20 : 16
            VStack {
                HStack {
                    Spacer()
                    Text("\(conflicts)")
                        .font(.system(size: isIPad ? 12 : 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(Circle().fill(Color.red))
                }
                Spacer()
            }
            .padding(isIPad ? 6 : 4)
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

    /// Checks if a number is in the selected cell's notes
    /// Used to highlight numbers that were previously marked as possibilities
    /// - Parameter number: The number to check
    /// - Returns: True if this number is in the selected cell's notes
    private func isInNotes(_ number: Int) -> Bool {
        guard let selected = viewModel.selectedPosition,
              !viewModel.notesMode // Only highlight when in value entry mode
        else {
            return false
        }

        let marks = viewModel.marks(at: selected)
        return marks.contains(number)
    }

    /// Background color for a number button
    /// - Parameter number: The number
    /// - Returns: The background color
    private func buttonBackgroundColor(for number: Int) -> Color {
        guard let selected = viewModel.selectedPosition else {
            return Color.themeButtonSecondary
        }

        // Highlight if this is the currently selected cell's value (only in non-notes mode)
        // Use a filled blue background to make it stand out prominently
        if !viewModel.notesMode, isSelectedNumber(number) {
            return Color.blue
        }

        // Highlight if this number is in the cell's notes (only in value entry mode)
        // Use a teal/cyan background to indicate these are marked possibilities
        if isInNotes(number) {
            return Color.cyan.opacity(0.2)
        }

        // Check if this number would be invalid (applies in both notes and non-notes mode)
        if !viewModel.canPlaceValue(number, at: selected) {
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

        // Highlight if this is the currently selected cell's value (only in non-notes mode)
        // Use a darker blue border for the selected number
        if !viewModel.notesMode, isSelectedNumber(number) {
            return Color.blue.opacity(0.8)
        }

        // Highlight if this number is in the cell's notes (only in value entry mode)
        // Use a teal/cyan border to indicate these are marked possibilities
        if isInNotes(number) {
            return Color.cyan.opacity(0.7)
        }

        // Check if this number would be invalid (applies in both notes and non-notes mode)
        if !viewModel.canPlaceValue(number, at: selected) {
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

        // Highlight if this is the currently selected cell's value (only in non-notes mode)
        // Use white text on the filled blue background for better contrast
        if !viewModel.notesMode, isSelectedNumber(number) {
            return .white
        }

        // Highlight if this number is in the cell's notes (only in value entry mode)
        // Use a teal/cyan text to indicate these are marked possibilities
        if isInNotes(number) {
            return Color.cyan.opacity(0.9)
        }

        // Check if this number would be invalid (dim the text)
        // Apply this in both notes and non-notes mode
        if !viewModel.canPlaceValue(number, at: selected) {
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

        // Check if cell is editable
        guard viewModel.isEditable(at: selected) else {
            return true
        }

        // Don't disable if cell already has this value (for non-notes mode)
        if !viewModel.notesMode,
           let currentValue = viewModel.value(at: selected),
           currentValue == number
        {
            return false
        }

        // Check if this placement would exceed the column's remaining sum
        // Apply this check in both notes mode and regular mode
        if viewModel.wouldExceedColumnSum(number, at: selected) {
            return true
        }

        // Check if this placement would be invalid (violates game rules)
        // Apply this check in both notes mode and regular mode
        return !viewModel.canPlaceValue(number, at: selected)
    }

    // MARK: - Accessibility Helpers

    /// Accessibility value for a number button
    /// - Parameter number: The number
    /// - Returns: The accessibility value
    private func numberAccessibilityValue(for number: Int) -> String {
        let conflicts = conflictCount(for: number)
        if conflicts > 0 {
            return "\(conflicts) conflict\(conflicts == 1 ? "" : "s")"
        }
        if isSelectedNumber(number) {
            return "Currently selected in cell"
        }
        return ""
    }

    /// Accessibility hint for a number button
    /// - Parameter number: The number
    /// - Returns: The accessibility hint
    private func numberAccessibilityHint(for number: Int) -> String {
        guard viewModel.selectedPosition != nil else {
            return "Select a cell first to enter this number"
        }

        if isNumberDisabled(for: number) {
            if viewModel.wouldExceedColumnSum(number, at: viewModel.selectedPosition!) {
                return "Cannot enter this number. It would exceed the column sum"
            }
            return "Cannot enter this number. It violates game rules"
        }

        if viewModel.notesMode {
            return "Double tap to add or remove this number as a pencil mark"
        } else {
            return "Double tap to enter this number in the selected cell"
        }
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
