import SwiftUI

/// A toolbar view providing game action buttons: Undo, Erase, Notes, and Hint
// swiftlint:disable:next swiftui_view_body
struct GameToolbarView: View {
    // MARK: - Properties

    /// The view model managing game state
    @ObservedObject var viewModel: GameViewModel

    /// Maximum hints allowed per game (for displaying remaining)
    var maxHints: Int = 3

    // MARK: - Constants

    private let buttonSize: CGFloat = 44
    private let iconSize: CGFloat = 22
    private let spacing: CGFloat = 24

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            undoButton
            eraseButton
            notesButton
            hintButton
        }
        .padding(.horizontal)
    }

    // MARK: - Subviews

    /// Undo button - reverts the last action
    private var undoButton: some View {
        ToolbarButton(
            icon: "arrow.uturn.backward",
            label: "Undo",
            isEnabled: viewModel.canUndo,
            action: { viewModel.undo() }
        )
    }

    /// Erase button - clears the selected cell
    private var eraseButton: some View {
        ToolbarButton(
            icon: "eraser",
            label: "Erase",
            isEnabled: canErase,
            action: { viewModel.clearSelectedCell() }
        )
    }

    /// Notes button - toggles pencil marks mode
    private var notesButton: some View {
        ToolbarButton(
            icon: "pencil.and.list.clipboard",
            label: "Notes",
            isEnabled: true,
            isActive: viewModel.notesMode,
            showIndicator: true,
            action: { viewModel.toggleNotesMode() }
        )
    }

    /// Hint button - provides a hint for the current puzzle state
    private var hintButton: some View {
        ToolbarButton(
            icon: "lightbulb",
            label: "Hint",
            isEnabled: canUseHint,
            badge: remainingHints,
            action: { viewModel.requestHint() }
        )
    }

    // MARK: - Computed Properties

    /// Whether the erase button should be enabled
    private var canErase: Bool {
        guard let selected = viewModel.selectedPosition else { return false }
        guard viewModel.isEditable(at: selected) else { return false }

        // Can erase if cell has a value or pencil marks
        let hasValue = viewModel.value(at: selected) != nil
        let hasMarks = !viewModel.marks(at: selected).isEmpty
        return hasValue || hasMarks
    }

    /// Whether hints can still be used
    private var canUseHint: Bool {
        !viewModel.gameState.isCompleted && remainingHints > 0
    }

    /// Number of hints remaining
    private var remainingHints: Int {
        max(0, maxHints - viewModel.gameState.hintsUsed)
    }
}

// MARK: - Toolbar Button Component

/// A reusable toolbar button with icon, label, and optional state indicators
// swiftlint:disable:next swiftui_view_body
private struct ToolbarButton: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    var isActive: Bool = false
    var showIndicator: Bool = false
    var badge: Int?
    let action: () -> Void

    private let buttonSize: CGFloat = 44
    private let iconSize: CGFloat = 22

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                iconStack
                labelStack
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
    }

    /// Icon stack with background and optional badge
    private var iconStack: some View {
        ZStack {
            // Background circle for active state
            Circle()
                .fill(isActive ? Color.blue.opacity(0.15) : Color.clear)
                .frame(width: buttonSize, height: buttonSize)

            // Icon
            Image(systemName: activeIcon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: buttonSize, height: buttonSize)

            // Badge for hint count
            if let badgeValue = badge, badgeValue > 0 {
                badgeView(value: badgeValue)
            }
        }
    }

    /// Label with optional ON/OFF indicator
    private var labelStack: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(labelColor)

            if showIndicator {
                statusIndicator
            }
        }
    }

    /// ON/OFF status indicator
    private var statusIndicator: some View {
        Text(isActive ? "ON" : "OFF")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(isActive ? .blue : .secondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                Capsule()
                    .fill(isActive ? Color.blue.opacity(0.15) : Color.themeButtonSecondary)
            )
    }

    /// Active icon name - handles special cases where .fill variant doesn't exist
    private var activeIcon: String {
        // Special case: pencil.and.list.clipboard doesn't have a .fill variant
        // Use pencil.tip.crop.circle.fill for notes mode when active
        if isActive, icon == "pencil.and.list.clipboard" {
            return "pencil.tip.crop.circle.fill"
        }
        // For other icons, use .fill variant when active
        return isActive ? "\(icon).fill" : icon
    }

    /// Icon color based on state
    private var iconColor: Color {
        if isActive {
            return .blue
        }
        return isEnabled ? .primary : .secondary
    }

    /// Label color based on state
    private var labelColor: Color {
        if isActive {
            return .blue
        }
        return isEnabled ? .secondary : .secondary.opacity(0.6)
    }

    /// Badge view showing remaining count
    private func badgeView(value: Int) -> some View {
        VStack {
            HStack {
                Spacer()
                Text("\(value)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.orange))
                    .offset(x: 4, y: -4)
            }
            Spacer()
        }
        .frame(width: buttonSize, height: buttonSize)
    }
}

// MARK: - Previews

#Preview("Toolbar - Default") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    return VStack {
        Spacer()
        GameToolbarView(viewModel: viewModel)
        Spacer()
    }
    .padding()
}

#Preview("Toolbar - Cell Selected") {
    let puzzle = PreviewPuzzles.easy3Row
    let viewModel = GameViewModel(puzzle: puzzle)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    return VStack {
        Text("Empty cell selected")
            .font(.caption)
            .foregroundColor(.secondary)
        Spacer()
        GameToolbarView(viewModel: viewModel)
        Spacer()
    }
    .padding()
}

#Preview("Toolbar - Notes Mode ON") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    viewModel.toggleNotesMode()
    return VStack {
        Text("Notes mode enabled")
            .font(.caption)
            .foregroundColor(.secondary)
        Spacer()
        GameToolbarView(viewModel: viewModel)
        Spacer()
    }
    .padding()
}

#Preview("Toolbar - With Undo Available") {
    let puzzle = PreviewPuzzles.easy3Row
    let viewModel = GameViewModel(puzzle: puzzle)
    viewModel.selectCell(at: CellPosition(row: 0, column: 2))
    viewModel.enterNumber(2)
    return VStack {
        Text("Undo available after entering a number")
            .font(.caption)
            .foregroundColor(.secondary)
        Spacer()
        GameToolbarView(viewModel: viewModel)
        Spacer()
    }
    .padding()
}

#Preview("Toolbar - Dark Mode") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    viewModel.toggleNotesMode()
    return VStack {
        Spacer()
        GameToolbarView(viewModel: viewModel)
        Spacer()
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("iPhone SE") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    return VStack {
        Spacer()
        GameToolbarView(viewModel: viewModel)
        Spacer()
    }
    .padding()
}

#Preview("iPad") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    return VStack {
        Spacer()
        GameToolbarView(viewModel: viewModel)
        Spacer()
    }
    .padding()
}
