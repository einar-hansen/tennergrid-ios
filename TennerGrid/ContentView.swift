import SwiftUI

/// The root content view that manages navigation between home and game screens
@MainActor
// swiftlint:disable:next swiftui_view_body
struct ContentView: View {
    // MARK: - Properties

    /// Puzzle manager for creating and managing puzzles
    @StateObject private var puzzleManager = PuzzleManager()

    /// Current game view model (nil when on home screen)
    @State private var gameViewModel: GameViewModel?

    /// Flag to show difficulty selection sheet
    @State private var showingDifficultySelection = false

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel = gameViewModel {
                // Show game view when a game is active
                GameView(viewModel: viewModel)
                    .onQuit(handleQuitGame)
                    .onNewGame(handleNewGameRequest)
            } else {
                // Show home view when no game is active
                HomeView(puzzleManager: puzzleManager)
                    .onContinueGame(handleContinueGame)
                    .onNewGame(handleStartNewGame)
                    .onDailyChallenge(handleDailyChallenge)
            }
        }
        .sheet(isPresented: $showingDifficultySelection) {
            DifficultySelectionView { difficulty in
                startNewGame(with: difficulty)
            }
        }
    }

    // MARK: - Navigation Actions

    /// Handles continuing a saved game
    /// - Parameter savedGame: The saved game to continue
    private func handleContinueGame(_ savedGame: SavedGame) {
        gameViewModel = GameViewModel(gameState: savedGame.gameState)
    }

    /// Handles starting a new game with difficulty selection
    /// - Parameter difficulty: The selected difficulty
    private func handleStartNewGame(_ difficulty: Difficulty) {
        startNewGame(with: difficulty)
    }

    /// Handles the new game request - shows difficulty selection
    private func handleNewGameRequest() {
        showingDifficultySelection = true
    }

    /// Handles playing the daily challenge
    private func handleDailyChallenge() {
        guard let puzzle = puzzleManager.dailyPuzzle() else {
            return
        }
        gameViewModel = GameViewModel(puzzle: puzzle)
    }

    /// Handles quitting the current game and returning to home
    private func handleQuitGame() {
        gameViewModel = nil
    }

    // MARK: - Game Creation

    /// Starts a new game with the specified difficulty
    /// - Parameter difficulty: The difficulty level for the new puzzle
    private func startNewGame(with difficulty: Difficulty) {
        // Generate a puzzle with random rows within the difficulty's range
        let rows = Int.random(in: difficulty.minRows ... difficulty.maxRows)
        guard let puzzle = puzzleManager.randomPuzzle(rows: rows, difficulty: difficulty) else {
            return
        }
        gameViewModel = GameViewModel(puzzle: puzzle)
    }
}

// MARK: - HomeView Extensions

extension HomeView {
    /// Sets the callback for when user wants to continue a saved game
    /// - Parameter action: The action to perform when continue is tapped
    /// - Returns: A modified HomeView with the callback configured
    func onContinueGame(_ action: @escaping (SavedGame) -> Void) -> HomeView {
        var view = self
        view.onContinueGame = action
        return view
    }

    /// Sets the callback for when user wants to start a new game
    /// - Parameter action: The action to perform when new game is tapped
    /// - Returns: A modified HomeView with the callback configured
    func onNewGame(_ action: @escaping (Difficulty) -> Void) -> HomeView {
        var view = self
        view.onNewGame = action
        return view
    }

    /// Sets the callback for when user wants to play the daily challenge
    /// - Parameter action: The action to perform when daily challenge is tapped
    /// - Returns: A modified HomeView with the callback configured
    func onDailyChallenge(_ action: @escaping () -> Void) -> HomeView {
        var view = self
        view.onDailyChallenge = action
        return view
    }
}

// MARK: - GameView Extensions

extension GameView {
    /// Sets the callback for when user quits the game
    /// - Parameter action: The action to perform when quit is tapped
    /// - Returns: A modified GameView with the callback configured
    func onQuit(_ action: @escaping () -> Void) -> GameView {
        var view = self
        view.onQuit = action
        return view
    }

    /// Sets the callback for when user wants to start a new game
    /// - Parameter action: The action to perform when new game is tapped
    /// - Returns: A modified GameView with the callback configured
    func onNewGame(_ action: @escaping () -> Void) -> GameView {
        var view = self
        view.onNewGame = action
        return view
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
