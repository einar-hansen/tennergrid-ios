import SwiftUI

/// The main home screen of the Tenner Grid app
/// Displays app branding, game options, and navigation to various features
// swiftlint:disable:next swiftui_view_body
struct HomeView: View {
    // MARK: - Properties

    /// Puzzle manager for accessing saved games
    @ObservedObject var puzzleManager: PuzzleManager

    /// Callback when user wants to continue a saved game
    var onContinueGame: ((SavedGame) -> Void)?

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                appBranding
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                Spacer()

                // Show continue game card if there's a saved game
                if let savedGame = mostRecentSavedGame {
                    continueGameCard(for: savedGame)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                } else {
                    welcomeMessage
                        .padding(.bottom, 20)
                }

                Spacer()
            }
        }
    }

    // MARK: - Computed Properties

    /// Returns the most recent saved game that can be resumed
    private var mostRecentSavedGame: SavedGame? {
        puzzleManager.savedGames.first { $0.canResume }
    }

    // MARK: - Subviews

    /// Background gradient for the home screen
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.3),
                Color.green.opacity(0.2),
                Color.orange.opacity(0.1),
                Color.clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    /// App branding section with title and icon
    private var appBranding: some View {
        VStack(spacing: 16) {
            appIcon
            appTitle
            appTagline
        }
    }

    /// App icon display
    private var appIcon: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue,
                            Color.green,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)

            // Grid icon representation
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
    }

    /// App title
    private var appTitle: some View {
        Text("Tenner Grid")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.blue,
                        Color.green,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    /// App tagline
    private var appTagline: some View {
        Text("The Ultimate Number Puzzle")
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
    }

    /// Welcome message at the bottom
    private var welcomeMessage: some View {
        VStack(spacing: 8) {
            Text("Welcome!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Text("More features coming soon")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
    }

    /// Continue game card for saved games
    /// - Parameter savedGame: The saved game to display
    /// - Returns: A card view showing game progress and continue option
    private func continueGameCard(for savedGame: SavedGame) -> some View {
        Button {
            onContinueGame?(savedGame)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader(for: savedGame)
                gameStatsSection(for: savedGame)
                continueButton(for: savedGame)
            }
            .padding(20)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    /// Card background with rounded rectangle and shadow
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    /// Header section with title and difficulty badge
    /// - Parameter savedGame: The saved game
    /// - Returns: Header view
    private func cardHeader(for savedGame: SavedGame) -> some View {
        HStack {
            Text("Continue Game")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            difficultyBadge(for: savedGame.puzzle.difficulty)
        }
    }

    /// Game statistics section showing progress and metadata
    /// - Parameter savedGame: The saved game
    /// - Returns: Stats view
    private func gameStatsSection(for savedGame: SavedGame) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            progressBar(for: savedGame)
            gameMetadata(for: savedGame)
        }
    }

    /// Progress bar showing completion percentage
    /// - Parameter savedGame: The saved game
    /// - Returns: Progress view
    private func progressBar(for savedGame: SavedGame) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(savedGame.progressPercentage))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }

            ProgressView(value: savedGame.gameState.progress, total: 1.0)
                .tint(savedGame.puzzle.difficulty.color)
        }
    }

    /// Game metadata showing time and grid size
    /// - Parameter savedGame: The saved game
    /// - Returns: Metadata view
    private func gameMetadata(for savedGame: SavedGame) -> some View {
        HStack(spacing: 20) {
            timeInfo(savedGame.formattedElapsedTime)
            gridSizeInfo(rows: savedGame.puzzle.rows, columns: savedGame.puzzle.columns)
            Spacer()
        }
    }

    /// Time information display
    /// - Parameter formattedTime: Formatted time string
    /// - Returns: Time view
    private func timeInfo(_ formattedTime: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Text(formattedTime)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    /// Grid size information display
    /// - Parameters:
    ///   - rows: Number of rows
    ///   - columns: Number of columns
    /// - Returns: Grid size view
    private func gridSizeInfo(rows: Int, columns: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Text("\(rows)x\(columns)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    /// Continue playing button
    /// - Parameter savedGame: The saved game
    /// - Returns: Button view
    private func continueButton(for savedGame: SavedGame) -> some View {
        HStack {
            Spacer()

            Text("Continue Playing")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(continueButtonGradient(for: savedGame))
                .cornerRadius(12)

            Spacer()
        }
    }

    /// Gradient background for continue button
    /// - Parameter savedGame: The saved game
    /// - Returns: Gradient view
    private func continueButtonGradient(for savedGame: SavedGame) -> some View {
        LinearGradient(
            colors: [
                savedGame.puzzle.difficulty.color,
                savedGame.puzzle.difficulty.color.opacity(0.8),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Difficulty badge view
    /// - Parameter difficulty: The difficulty level
    /// - Returns: A badge showing the difficulty
    private func difficultyBadge(for difficulty: Difficulty) -> some View {
        Text(difficulty.displayName.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(difficulty.color)
            )
    }
}

// MARK: - Previews

#Preview("Home View - Light Mode") {
    HomeView(puzzleManager: PuzzleManager())
}

#Preview("Home View - Dark Mode") {
    HomeView(puzzleManager: PuzzleManager())
        .preferredColorScheme(.dark)
}

#Preview("Home View - With Saved Game") {
    let manager = PuzzleManager()
    // Add a test saved game
    if let puzzle = manager.randomPuzzle(rows: 5, difficulty: .medium) {
        let gameState = GameState(puzzle: puzzle)
        var modifiedState = gameState
        modifiedState.elapsedTime = 245 // 4:05
        // Add some progress by filling a few cells
        if modifiedState.puzzle.rows > 0, modifiedState.puzzle.columns > 0 {
            modifiedState.currentGrid[0][0] = 5
            modifiedState.currentGrid[0][1] = 3
        }
        let savedGame = SavedGame(puzzle: puzzle, gameState: modifiedState)
        manager.addSavedGame(savedGame)
    }
    return HomeView(puzzleManager: manager)
}

#Preview("Home View - No Saved Game") {
    HomeView(puzzleManager: PuzzleManager())
}
