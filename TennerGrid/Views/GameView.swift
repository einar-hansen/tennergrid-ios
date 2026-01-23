//
//  GameView.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import SwiftUI

/// The main game view composing all game UI components
struct GameView: View {
    // MARK: - Properties

    /// The view model managing game state
    @StateObject private var viewModel: GameViewModel

    /// Whether the pause menu is showing
    @State private var showingPauseMenu = false

    /// Whether the settings sheet is showing
    @State private var showingSettings = false

    /// Whether the win screen is showing
    @State private var showingWinScreen = false

    /// Focus state for keyboard input
    @FocusState private var isGameFocused: Bool

    // MARK: - Initialization

    /// Creates a new GameView with the given puzzle
    /// - Parameter puzzle: The puzzle to play
    init(puzzle: TennerGridPuzzle) {
        _viewModel = StateObject(wrappedValue: GameViewModel(puzzle: puzzle))
    }

    /// Creates a new GameView with the given view model
    /// - Parameter viewModel: The view model to use
    init(viewModel: GameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main game content
            gameContent
                .blur(radius: viewModel.gameState.isPaused ? 10 : 0)
                .disabled(viewModel.gameState.isPaused)

            // Pause overlay
            if viewModel.gameState.isPaused {
                pauseOverlay
            }
        }
        .modifier(KeyboardSupportModifier(viewModel: viewModel, isGameFocused: $isGameFocused))
        .onChange(of: viewModel.gameState.isCompleted) { isCompleted in
            if isCompleted {
                Task { @MainActor in
                    showingWinScreen = true
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            settingsPlaceholder
        }
        .sheet(isPresented: $showingWinScreen) {
            winScreenPlaceholder
        }
    }

    // MARK: - Subviews

    /// Main game content layout
    private var gameContent: some View {
        VStack(spacing: 16) {
            // Header with timer, difficulty, and controls
            GameHeaderView(
                viewModel: viewModel,
                onPause: handlePause,
                onSettings: handleSettings
            )

            Spacer()

            // Main puzzle grid
            GridView(viewModel: viewModel)

            Spacer()

            // Game toolbar with action buttons
            GameToolbarView(viewModel: viewModel)
                .padding(.bottom, 8)

            // Number pad for input
            NumberPadView(viewModel: viewModel)
                .padding(.bottom, 16)
        }
    }

    /// Pause overlay shown when game is paused
    private var pauseOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Pause menu content
            VStack(spacing: 24) {
                // Pause icon
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)

                Text("Game Paused")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                // Resume button
                Button(action: handleResume) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }

    /// Placeholder for settings view (to be implemented in Phase 6)
    private var settingsPlaceholder: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("Settings")
                    .font(.title)

                Text("Coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
    }

    /// Placeholder for win screen (to be implemented in Phase 4.3)
    private var winScreenPlaceholder: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.yellow)

                Text("Congratulations!")
                    .font(.largeTitle.bold())

                VStack(spacing: 8) {
                    Text("Time: \(viewModel.formattedTime)")
                        .font(.title2)

                    Text("Hints used: \(viewModel.gameState.hintsUsed)")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Difficulty: \(viewModel.gameState.puzzle.difficulty.displayName)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)

                Button(action: {
                    showingWinScreen = false
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    // MARK: - Actions

    /// Handles the pause button tap
    private func handlePause() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.pauseTimer()
        }
    }

    /// Handles the resume button tap
    private func handleResume() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.resumeTimer()
        }
    }

    /// Handles the settings button tap
    private func handleSettings() {
        showingSettings = true
    }
}

// MARK: - Keyboard Support Modifier

/// A view modifier that adds hardware keyboard support for the game
/// On iOS 17+, supports number keys 0-9 for entry, backspace for clearing, and arrow keys for navigation
/// On iOS 16, keyboard support is not available (requires on-screen controls)
private struct KeyboardSupportModifier: ViewModifier {
    /// The game view model to send input to
    @ObservedObject var viewModel: GameViewModel

    /// Focus state binding for keyboard input
    @FocusState.Binding var isGameFocused: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .focusable()
                .focused($isGameFocused)
                .onAppear {
                    isGameFocused = true
                }
                .modifier(KeyboardInputModifierIOS17(viewModel: viewModel))
        } else {
            // iOS 16 fallback - hardware keyboard support is not available
            // Users must use the on-screen number pad
            content
        }
    }
}

/// iOS 17+ specific keyboard input handler
/// Separated to avoid availability warnings in the main modifier
@available(iOS 17.0, *)
private struct KeyboardInputModifierIOS17: ViewModifier {
    /// The game view model to send input to
    @ObservedObject var viewModel: GameViewModel

    /// Number keys 0-9
    private static let numberKeys: Set<KeyEquivalent> = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    ]

    /// Delete/backspace keys
    private static let deleteKeys: Set<KeyEquivalent> = [
        .delete,
    ]

    /// Arrow keys for navigation
    private static let arrowKeys: Set<KeyEquivalent> = [
        .upArrow, .downArrow, .leftArrow, .rightArrow,
    ]

    func body(content: Content) -> some View {
        content
            .onKeyPress(keys: Self.numberKeys) { keyPress in
                handleNumberKey(keyPress)
            }
            .onKeyPress(keys: Self.deleteKeys) { _ in
                handleDeleteKey()
            }
            .onKeyPress(keys: Self.arrowKeys) { keyPress in
                handleArrowKey(keyPress)
            }
    }

    // MARK: - Key Handlers

    /// Handles number key presses (0-9)
    private func handleNumberKey(_ keyPress: KeyPress) -> KeyPress.Result {
        guard !viewModel.gameState.isPaused,
              !viewModel.gameState.isCompleted
        else {
            return .ignored
        }

        // Extract the number from the key character
        guard let character = keyPress.characters.first,
              let number = Int(String(character)),
              number >= 0, number <= 9
        else {
            return .ignored
        }

        // Enter the number
        viewModel.enterNumber(number)
        return .handled
    }

    /// Handles delete/backspace key presses
    private func handleDeleteKey() -> KeyPress.Result {
        guard !viewModel.gameState.isPaused,
              !viewModel.gameState.isCompleted,
              viewModel.selectedPosition != nil
        else {
            return .ignored
        }

        // Clear the selected cell
        viewModel.clearSelectedCell()
        return .handled
    }

    /// Handles arrow key presses for cell navigation
    private func handleArrowKey(_ keyPress: KeyPress) -> KeyPress.Result {
        guard !viewModel.gameState.isPaused,
              !viewModel.gameState.isCompleted
        else {
            return .ignored
        }

        let puzzle = viewModel.gameState.puzzle
        let currentPosition = viewModel.selectedPosition ?? CellPosition(row: 0, column: 0)

        var newRow = currentPosition.row
        var newColumn = currentPosition.column

        switch keyPress.key {
        case .upArrow:
            newRow = max(0, currentPosition.row - 1)
        case .downArrow:
            newRow = min(puzzle.rows - 1, currentPosition.row + 1)
        case .leftArrow:
            newColumn = max(0, currentPosition.column - 1)
        case .rightArrow:
            newColumn = min(puzzle.columns - 1, currentPosition.column + 1)
        default:
            return .ignored
        }

        let newPosition = CellPosition(row: newRow, column: newColumn)
        if newPosition != currentPosition {
            viewModel.selectCell(at: newPosition)
        }

        return .handled
    }
}

// MARK: - Previews

#Preview("Game View - Easy") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
}

#Preview("Game View - Medium") {
    GameView(puzzle: PreviewPuzzles.medium4Row)
}

#Preview("Game View - Hard") {
    GameView(puzzle: PreviewPuzzles.hard5Row)
}

#Preview("Dark Mode") {
    GameView(puzzle: PreviewPuzzles.medium5Row)
        .preferredColorScheme(.dark)
}

#Preview("iPhone SE - Small") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
}

#Preview("iPhone 15 Pro Max") {
    GameView(puzzle: PreviewPuzzles.hard5Row)
}

#Preview("iPad") {
    GameView(puzzle: PreviewPuzzles.hard7Row)
}
