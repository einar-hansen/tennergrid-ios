import SwiftUI

/// A view representing a single cell in the Tenner Grid puzzle
struct CellView: View {
    // MARK: - Properties

    /// The cell data to display
    let cell: Cell

    /// Action to perform when the cell is tapped
    let onTap: () -> Void

    // MARK: - Constants

    private let cellSize: CGFloat = 50
    private let borderWidth: CGFloat = 1
    private let selectedBorderWidth: CGFloat = 3
    private let cornerRadius: CGFloat = 4
    private let fontSize: CGFloat = 24
    private let pencilMarkFontSize: CGFloat = 10

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(backgroundColor)

            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderColor, lineWidth: cell.isSelected ? selectedBorderWidth : borderWidth)

            // Content
            if let value = cell.value {
                // Display number
                Text(String(value))
                    .font(.system(size: fontSize, weight: textWeight, design: .rounded))
                    .foregroundColor(textColor)
            } else if cell.hasPencilMarks {
                // Display pencil marks in 3x3 grid
                pencilMarksView
            }
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    // MARK: - Subviews

    /// View displaying pencil marks in a 3x3 grid
    private var pencilMarksView: some View {
        VStack(spacing: 2) {
            ForEach(0 ..< 3) { row in
                HStack(spacing: 2) {
                    ForEach(0 ..< 3) { col in
                        let number = row * 3 + col + 1
                        if number <= 9 {
                            pencilMarkCell(for: number)
                        }
                    }
                }
            }
        }
        .padding(4)
    }

    /// Individual pencil mark cell
    /// - Parameter number: The number (1-9) to display
    /// - Returns: View for the pencil mark
    private func pencilMarkCell(for number: Int) -> some View {
        Text(cell.pencilMarks.contains(number) ? String(number) : "")
            .font(.system(size: pencilMarkFontSize, weight: .light, design: .rounded))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Styling

    /// Background color based on cell state (priority order: error > selected > same-number > neighbor > highlighted >
    /// initial > empty)
    private var backgroundColor: Color {
        if cell.hasError {
            // Error state: red tint to indicate invalid placement
            Color.red.opacity(0.2)
        } else if cell.isSelected {
            // Selected state: prominent blue background
            Color.blue.opacity(0.15)
        } else if cell.isSameNumber {
            // Same-number state: yellow/amber tint for cells with matching value
            Color.yellow.opacity(0.12)
        } else if cell.isNeighbor {
            // Neighbor state: purple/indigo tint for adjacent cells (constraint helper)
            Color.purple.opacity(0.12)
        } else if cell.isHighlighted {
            // Highlighted state: subtle blue tint for related cells (e.g., same row/column)
            Color.blue.opacity(0.08)
        } else if cell.isInitial {
            // Initial/pre-filled state: light gray to distinguish from user entries
            Color.gray.opacity(0.1)
        } else {
            // Empty/default state: clear background
            Color.clear
        }
    }

    /// Border color based on cell state (priority order: error > selected > default)
    private var borderColor: Color {
        if cell.hasError {
            // Error state: red border
            .red
        } else if cell.isSelected {
            // Selected state: blue border
            .blue
        } else {
            // Default state: subtle gray border
            Color.gray.opacity(0.3)
        }
    }

    /// Text color based on cell state (priority order: error > initial > user-entered)
    private var textColor: Color {
        if cell.hasError {
            // Error state: red text
            .red
        } else if cell.isInitial {
            // Initial/pre-filled: primary color (adapts to light/dark mode)
            .primary
        } else {
            // User-entered: blue to distinguish from pre-filled
            .blue
        }
    }

    /// Text weight based on whether cell is pre-filled
    private var textWeight: Font.Weight {
        cell.isInitial ? .bold : .regular
    }
}

// MARK: - Previews

struct CellView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty cell
            CellView(
                cell: Cell(position: CellPosition(row: 0, column: 0)),
                onTap: {}
            )
            .previewDisplayName("Empty")

            // Pre-filled cell
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 5,
                    isInitial: true
                ),
                onTap: {}
            )
            .previewDisplayName("Pre-filled")

            // User-entered cell
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 7,
                    isInitial: false
                ),
                onTap: {}
            )
            .previewDisplayName("User-entered")

            // Selected cell
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 3,
                    isInitial: false,
                    isSelected: true
                ),
                onTap: {}
            )
            .previewDisplayName("Selected")

            // Error cell
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 4,
                    isInitial: false,
                    hasError: true
                ),
                onTap: {}
            )
            .previewDisplayName("Error")

            // Highlighted cell
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 2,
                    isInitial: false,
                    isHighlighted: true
                ),
                onTap: {}
            )
            .previewDisplayName("Highlighted")

            // Same-number cell
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 7,
                    isInitial: false,
                    isSameNumber: true
                ),
                onTap: {}
            )
            .previewDisplayName("Same Number")

            // Neighbor cell
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 5,
                    isInitial: false,
                    isNeighbor: true
                ),
                onTap: {}
            )
            .previewDisplayName("Neighbor")

            // Pencil marks
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: nil,
                    isInitial: false,
                    pencilMarks: [1, 3, 5, 7, 9]
                ),
                onTap: {}
            )
            .previewDisplayName("Pencil Marks")

            // Combined states: Selected with error
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 6,
                    isInitial: false,
                    isSelected: true,
                    hasError: true
                ),
                onTap: {}
            )
            .previewDisplayName("Selected + Error")

            // Dark mode
            CellView(
                cell: Cell(
                    position: CellPosition(row: 0, column: 0),
                    value: 8,
                    isInitial: false,
                    isSelected: true
                ),
                onTap: {}
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Device Size Testing Previews

#Preview("iPhone SE") {
    VStack(spacing: 20) {
        Text("iPhone SE (4.7\" / 375pt wide)")
            .font(.caption)
        sampleGridRow
    }
}

#Preview("iPhone 15") {
    VStack(spacing: 20) {
        Text("iPhone 15 (6.1\" / 393pt wide)")
            .font(.caption)
        sampleGridRow
    }
}

#Preview("iPhone 15 Pro Max") {
    VStack(spacing: 20) {
        Text("iPhone 15 Pro Max (6.7\" / 430pt wide)")
            .font(.caption)
        sampleGridRow
    }
}

private var sampleGridRow: some View {
    VStack(spacing: 16) {
        // 5 cells in a row (typical small puzzle)
        HStack(spacing: 2) {
            ForEach(0 ..< 5) { index in
                CellView(
                    cell: Cell(
                        position: CellPosition(row: 0, column: index),
                        value: index == 2 ? nil : index + 1,
                        isInitial: index % 2 == 0,
                        pencilMarks: index == 2 ? [1, 4, 7] : [],
                        isSelected: index == 1
                    ),
                    onTap: {}
                )
            }
        }

        // 10 cells in a row (maximum puzzle width)
        HStack(spacing: 2) {
            ForEach(0 ..< 10) { index in
                CellView(
                    cell: Cell(
                        position: CellPosition(row: 1, column: index),
                        value: index == 5 ? nil : (index % 10),
                        isInitial: index % 3 == 0,
                        pencilMarks: index == 5 ? [2, 5, 8] : []
                    ),
                    onTap: {}
                )
            }
        }

        Text("Cell size: 50pt × 50pt (fixed)")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
    .padding()
}
