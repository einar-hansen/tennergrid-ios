import SwiftUI

/// A header view displaying game information: timer, difficulty, and control buttons
struct GameHeaderView: View {
    // MARK: - Properties

    /// The view model managing game state
    @ObservedObject var viewModel: GameViewModel

    /// Action to perform when pause button is tapped
    var onPause: () -> Void

    /// Action to perform when settings/menu button is tapped
    var onSettings: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            difficultyLabel
            Spacer()
            timerDisplay
            Spacer()
            controlButtons
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Subviews

    /// Difficulty label with color indicator
    private var difficultyLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.gameState.puzzle.difficulty.color)
                .frame(width: 10, height: 10)

            Text(viewModel.gameState.puzzle.difficulty.displayName)
                .font(.difficultyLabel)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.themeButtonSecondary)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Difficulty level")
        .accessibilityValue(viewModel.gameState.puzzle.difficulty.displayName)
    }

    /// Timer display showing elapsed time in MM:SS format
    private var timerDisplay: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.secondaryText)
                .foregroundColor(timerColor)

            Text(viewModel.formattedTime)
                .font(.timerText)
                .foregroundColor(timerColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Elapsed time")
        .accessibilityValue(timerAccessibilityValue)
    }

    /// Control buttons (pause and settings)
    private var controlButtons: some View {
        HStack(spacing: 12) {
            pauseButton
            settingsButton
        }
    }

    /// Pause button
    private var pauseButton: some View {
        Button(action: onPause) {
            Image(systemName: pauseIconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.themeButtonSecondary)
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.gameState.isCompleted)
        .opacity(viewModel.gameState.isCompleted ? 0.4 : 1.0)
        .accessibilityLabel(viewModel.gameState.isPaused ? "Resume game" : "Pause game")
    }

    /// Settings/menu button
    private var settingsButton: some View {
        Button(action: onSettings) {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.themeButtonSecondary)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }

    // MARK: - Computed Properties

    /// Timer text color based on game state
    private var timerColor: Color {
        if viewModel.gameState.isCompleted {
            .green
        } else if viewModel.gameState.isPaused {
            .secondary
        } else {
            .primary
        }
    }

    /// Icon name for pause button based on game state
    private var pauseIconName: String {
        viewModel.gameState.isPaused ? "play.fill" : "pause.fill"
    }

    // MARK: - Accessibility

    /// Timer accessibility value with spoken time
    private var timerAccessibilityValue: String {
        let minutes = Int(viewModel.gameState.elapsedTime) / 60
        let seconds = Int(viewModel.gameState.elapsedTime) % 60

        if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") and \(seconds) second\(seconds == 1 ? "" : "s")"
        } else {
            return "\(seconds) second\(seconds == 1 ? "" : "s")"
        }
    }
}

// MARK: - Previews

#Preview("Header - Default") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.easy3Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
}

#Preview("Header - Medium Difficulty") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.medium4Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
}

#Preview("Header - Hard Difficulty") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.hard5Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
}

#Preview("Header - Large Grid") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.hard6Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
}

#Preview("Header - Dark Mode") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.hard5Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("iPhone SE") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.medium5Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
}

#Preview("iPhone 15 Pro Max") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.medium5Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
}

#Preview("iPad") {
    let viewModel = GameViewModel(puzzle: PreviewPuzzles.medium5Row)
    return VStack {
        GameHeaderView(viewModel: viewModel, onPause: {}, onSettings: {})
        Spacer()
    }
    .padding()
}
