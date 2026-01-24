import SwiftUI

/// A view representing a single cell in the Tenner Grid puzzle
struct CellView: View {
    // MARK: - Properties

    /// The cell data to display
    let cell: Cell

    /// The size of the cell (width and height)
    let cellSize: CGFloat

    /// Action to perform when the cell is tapped
    let onTap: () -> Void

    /// High contrast mode setting for accessibility
    @AppStorage("highContrastMode") private var highContrastMode = false

    // MARK: - Animation State

    /// Scale factor for number entry animation
    @State private var scale: CGFloat = 1.0

    /// Opacity for number entry animation
    @State private var opacity: Double = 1.0

    /// Horizontal offset for error shake animation
    @State private var shakeOffset: CGFloat = 0

    /// Scale factor for selection bounce animation
    @State private var selectionScale: CGFloat = 1.0

    // MARK: - Constants

    private let borderWidth: CGFloat = 1
    private let selectedBorderWidth: CGFloat = 3
    private let highContrastBorderWidth: CGFloat = 2.5
    private let cornerRadius: CGFloat = 4

    /// Font size scales with cell size
    private var fontSize: CGFloat {
        cellSize * 0.48 // Approximately 48% of cell size
    }

    /// Pencil mark font size scales with cell size
    private var pencilMarkFontSize: CGFloat {
        cellSize * 0.20 // Approximately 20% of cell size
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(backgroundColor)

            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderColor, lineWidth: effectiveBorderWidth)

            // High contrast pattern overlay (adds visual patterns for better distinction)
            if highContrastMode {
                highContrastPatternOverlay
            }

            // Content
            if let value = cell.value {
                // Display number with animation
                Text(String(value))
                    .font(cell.isInitial ? .cellNumberBold(cellSize: cellSize) : .cellNumber(cellSize: cellSize))
                    .foregroundColor(textColor)
                    .scaleEffect(scale)
                    .opacity(opacity)
            } else if cell.hasPencilMarks {
                // Display pencil marks in 3x3 grid
                pencilMarksView
            }
        }
        .frame(width: cellSize, height: cellSize)
        .fixedSize()
        .contentShape(Rectangle())
        .scaleEffect(selectionScale)
        .offset(x: shakeOffset, y: 0)
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(accessibilityTraits)
        .onChange(of: cell.value) { newValue in
            // Only animate when a number is entered (not when cleared or for initial values)
            if newValue != nil, !cell.isInitial {
                playNumberEntryAnimation()
            }
        }
        .onChange(of: cell.hasError) { hasError in
            // Trigger shake animation when an error occurs
            if hasError {
                playErrorShakeAnimation()
            }
        }
        .onChange(of: cell.isSelected) { isSelected in
            // Trigger bounce animation when cell is selected
            if isSelected {
                playSelectionBounceAnimation()
            }
        }
    }

    // MARK: - Animation Methods

    /// Plays the number entry animation (scale + fade in)
    private func playNumberEntryAnimation() {
        // Start with smaller scale and reduced opacity
        scale = 0.3
        opacity = 0.0

        // Animate to normal size with spring effect
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }
    }

    /// Plays the error shake animation (horizontal shake)
    private func playErrorShakeAnimation() {
        // Reset shake offset
        shakeOffset = 0

        // Create a sequence of shake movements
        let shakeDistance: CGFloat = 8
        let shakeDuration = 0.08

        // Shake right
        withAnimation(.easeInOut(duration: shakeDuration)) {
            shakeOffset = shakeDistance
        }

        // Shake left (after first shake completes)
        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = -shakeDistance
            }
        }

        // Shake right again
        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 2) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = shakeDistance / 2
            }
        }

        // Return to center
        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 3) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = 0
            }
        }
    }

    /// Plays the selection bounce animation (scale effect with spring)
    private func playSelectionBounceAnimation() {
        // Start with slightly larger scale
        selectionScale = 1.15

        // Bounce back to normal with spring animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            selectionScale = 1.0
        }
    }

    // MARK: - Computed Properties

    /// Effective border width based on cell state and high contrast mode
    private var effectiveBorderWidth: CGFloat {
        if cell.isSelected {
            selectedBorderWidth
        } else if highContrastMode, cell.hasError || cell.isSameNumber || cell.isNeighbor {
            highContrastBorderWidth
        } else {
            borderWidth
        }
    }

    // MARK: - Subviews

    /// Pattern overlay for high contrast mode (adds visual patterns to distinguish cell states)
    @ViewBuilder
    private var highContrastPatternOverlay: some View {
        if cell.hasError {
            // Diagonal stripes for errors
            diagonalStripesPattern
                .foregroundColor(Color.highContrastErrorBorder.opacity(0.1))
        } else if cell.isNeighbor {
            // Dots pattern for neighbors
            dotsPattern
                .foregroundColor(Color.highContrastNeighborBackground.opacity(0.3))
        }
    }

    /// Diagonal stripes pattern for error state
    private var diagonalStripesPattern: some View {
        GeometryReader { geometry in
            Path { path in
                let stripeWidth: CGFloat = 2
                let spacing: CGFloat = 6
                let size = geometry.size

                // Draw diagonal stripes from top-left to bottom-right
                var x: CGFloat = -size.height
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    x += spacing
                }
            }
            .stroke(lineWidth: 1.5)
        }
    }

    /// Dots pattern for neighbor state
    private var dotsPattern: some View {
        GeometryReader { geometry in
            let dotSize: CGFloat = 2
            let spacing: CGFloat = 8
            let columns = Int(geometry.size.width / spacing)
            let rows = Int(geometry.size.height / spacing)

            Canvas { context, _ in
                for row in 0 ..< rows {
                    for col in 0 ..< columns {
                        let x = CGFloat(col) * spacing + spacing / 2
                        let y = CGFloat(row) * spacing + spacing / 2
                        let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                        context.fill(Path(ellipseIn: rect), with: .color(Color.highContrastNeighborBackground))
                    }
                }
            }
        }
    }

    /// View displaying pencil marks in a 2x5 grid (matching number pad layout)
    private var pencilMarksView: some View {
        let padding: CGFloat = 6
        let availableSize = cellSize - (padding * 2)
        let gridCellWidth = availableSize / 5 // 5 columns
        let gridCellHeight = availableSize / 2 // 2 rows

        return VStack(spacing: 0) {
            // First row: 0-4
            HStack(spacing: 0) {
                pencilMarkCell(for: 0, width: gridCellWidth, height: gridCellHeight)
                ForEach(1 ... 4, id: \.self) { number in
                    pencilMarkCell(for: number, width: gridCellWidth, height: gridCellHeight)
                }
            }
            // Second row: 5-9
            HStack(spacing: 0) {
                ForEach(5 ... 9, id: \.self) { number in
                    pencilMarkCell(for: number, width: gridCellWidth, height: gridCellHeight)
                }
            }
        }
        .frame(width: availableSize, height: availableSize)
        .padding(padding)
    }

    /// Individual pencil mark cell
    /// - Parameters:
    ///   - number: The number (0-9) to display
    ///   - width: The width of the grid cell
    ///   - height: The height of the grid cell
    /// - Returns: View for the pencil mark
    private func pencilMarkCell(for number: Int, width: CGFloat, height: CGFloat) -> some View {
        Text(cell.pencilMarks.contains(number) ? String(number) : "")
            .font(.pencilMark(cellSize: cellSize))
            .foregroundColor(.secondary)
            .frame(width: width, height: height)
            .minimumScaleFactor(0.5)
    }

    // MARK: - Styling

    /// Background color based on cell state (priority order: error > selected > same-number > neighbor > highlighted >
    /// initial > empty)
    private var backgroundColor: Color {
        if cell.hasError {
            // Error state: red tint to indicate invalid placement
            highContrastMode ? Color.highContrastErrorBackground : Color.red.opacity(0.2)
        } else if cell.isSelected {
            // Selected state: prominent blue background
            highContrastMode ? Color.highContrastSelectedBackground : Color.blue.opacity(0.15)
        } else if cell.isSameNumber {
            // Same-number state: yellow/amber tint for cells with matching value
            highContrastMode ? Color.highContrastSameNumberBackground : Color.yellow.opacity(0.12)
        } else if cell.isNeighbor {
            // Neighbor state: purple/indigo tint for adjacent cells (constraint helper)
            highContrastMode ? Color.highContrastNeighborBackground : Color.purple.opacity(0.12)
        } else if cell.isHighlighted {
            // Highlighted state: subtle blue tint for related cells (e.g., same row/column)
            highContrastMode ? Color.highContrastHighlightedBackground : Color.blue.opacity(0.08)
        } else if cell.isInitial {
            // Initial/pre-filled state: subtle background to distinguish from user entries
            Color.themeCellInitialBackground
        } else {
            // Empty/default state: clear background
            Color.clear
        }
    }

    /// Border color based on cell state (priority order: error > selected > default)
    private var borderColor: Color {
        if cell.hasError {
            // Error state: red border
            highContrastMode ? Color.highContrastErrorBorder : .red
        } else if cell.isSelected {
            // Selected state: blue border
            highContrastMode ? Color.highContrastSelectedBorder : .blue
        } else {
            // Default state: subtle border
            Color.themeBorderColor
        }
    }

    /// Text color based on cell state (priority order: error > initial > user-entered)
    private var textColor: Color {
        if cell.hasError {
            // Error state: red text
            highContrastMode ? Color.highContrastErrorText : .red
        } else if cell.isInitial {
            // Initial/pre-filled: primary color (adapts to light/dark mode)
            .primary
        } else {
            // User-entered: blue to distinguish from pre-filled
            highContrastMode ? Color.highContrastUserEnteredText : .blue
        }
    }

    /// Text weight based on whether cell is pre-filled
    private var textWeight: Font.Weight {
        cell.isInitial ? .bold : .regular
    }

    // MARK: - Accessibility

    /// Accessibility label describing the cell
    private var accessibilityLabel: String {
        "Cell at row \(cell.position.row + 1), column \(cell.position.column + 1)"
    }

    /// Accessibility value describing the cell's content
    private var accessibilityValue: String {
        if let value = cell.value {
            if cell.isInitial {
                return "Pre-filled with \(value)"
            } else {
                return "Contains \(value)"
            }
        } else if cell.hasPencilMarks {
            let marks = cell.pencilMarks.sorted()
            let marksString = marks.map(String.init).joined(separator: ", ")
            return "Pencil marks: \(marksString)"
        } else {
            return "Empty"
        }
    }

    /// Accessibility hint providing context
    private var accessibilityHint: String {
        if cell.isInitial {
            "This cell is pre-filled and cannot be changed"
        } else if cell.hasError {
            "This cell has an error. Double tap to select and enter a different number"
        } else if cell.isSelected {
            "Selected. Use number pad to enter a value"
        } else {
            "Double tap to select this cell"
        }
    }

    /// Accessibility traits based on cell state
    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]

        if cell.isSelected {
            traits.insert(.isSelected)
        }

        if cell.isInitial {
            traits.insert(.isStaticText)
            traits.remove(.isButton)
        }

        return traits
    }
}

// MARK: - Previews

struct CellView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            emptyCell
            prefilledCell
            userEnteredCell
            selectedCell
            errorCell
            highlightedCell
            sameNumberCell
            neighborCell
            pencilMarksCell
            selectedErrorCell
            darkModeCell
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }

    static var emptyCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0)),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Empty")
    }

    static var prefilledCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 5, isInitial: true),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Pre-filled")
    }

    static var userEnteredCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 7, isInitial: false),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("User-entered")
    }

    static var selectedCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 3, isInitial: false, isSelected: true),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Selected")
    }

    static var errorCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 4, isInitial: false, hasError: true),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Error")
    }

    static var highlightedCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 2, isInitial: false, isHighlighted: true),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Highlighted")
    }

    static var sameNumberCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 7, isInitial: false, isSameNumber: true),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Same Number")
    }

    static var neighborCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 5, isInitial: false, isNeighbor: true),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Neighbor")
    }

    static var pencilMarksCell: some View {
        CellView(
            cell: Cell(
                position: CellPosition(row: 0, column: 0),
                value: nil,
                isInitial: false,
                pencilMarks: [0, 1, 3, 5, 7, 9]
            ),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Pencil Marks")
    }

    static var selectedErrorCell: some View {
        CellView(
            cell: Cell(
                position: CellPosition(row: 0, column: 0),
                value: 6,
                isInitial: false,
                isSelected: true,
                hasError: true
            ),
            cellSize: 50,
            onTap: {}
        )
        .previewDisplayName("Selected + Error")
    }

    static var darkModeCell: some View {
        CellView(
            cell: Cell(position: CellPosition(row: 0, column: 0), value: 8, isInitial: false, isSelected: true),
            cellSize: 50,
            onTap: {}
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
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
        smallGridRow
        fullGridRow
        sizeDescription
    }
    .padding()
}

private var smallGridRow: some View {
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
                cellSize: 50,
                onTap: {}
            )
        }
    }
}

private var fullGridRow: some View {
    HStack(spacing: 2) {
        ForEach(0 ..< 10) { index in
            CellView(
                cell: Cell(
                    position: CellPosition(row: 1, column: index),
                    value: index == 5 ? nil : (index % 10),
                    isInitial: index % 3 == 0,
                    pencilMarks: index == 5 ? [2, 5, 8] : []
                ),
                cellSize: 50,
                onTap: {}
            )
        }
    }
}

private var sizeDescription: some View {
    Text("Cell size: 50pt × 50pt (example)")
        .font(.caption2)
        .foregroundColor(.secondary)
}
