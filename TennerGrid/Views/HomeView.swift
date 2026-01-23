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

    /// Callback when user wants to start a new game with a selected difficulty
    var onNewGame: ((Difficulty) -> Void)?

    /// Callback when user wants to start a custom game with specific difficulty and row count
    var onCustomGame: ((Difficulty, Int) -> Void)?

    /// Callback when user wants to play the daily challenge
    var onDailyChallenge: (() -> Void)?

    /// State to control difficulty selection sheet presentation
    @State private var showingDifficultySelection = false

    /// Timer for updating countdown
    @State private var timer: Timer?

    /// Current time remaining until next daily challenge
    @State private var timeUntilNextDaily: TimeInterval = 0

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
                }

                // Daily Challenge card - always visible
                dailyChallengeCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // New Game button - always visible
                newGameButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // Welcome message only when no saved game
                if mostRecentSavedGame == nil {
                    welcomeMessage
                        .padding(.bottom, 20)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showingDifficultySelection) {
            DifficultySelectionView(
                onSelect: { difficulty in
                    onNewGame?(difficulty)
                },
                onCustomGame: { difficulty, rows in
                    onCustomGame?(difficulty, rows)
                }
            )
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Computed Properties

    /// Returns the most recent saved game that can be resumed
    private var mostRecentSavedGame: SavedGame? {
        puzzleManager.savedGames.first { $0.canResume }
    }

    /// Calculates time remaining until midnight (next daily challenge)
    private var timeUntilMidnight: TimeInterval {
        let now = Date()
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow)
        else {
            return 0
        }
        return midnight.timeIntervalSince(now)
    }

    /// Formats the countdown time as HH:MM:SS
    private var formattedCountdown: String {
        let hours = Int(timeUntilNextDaily) / 3600
        let minutes = (Int(timeUntilNextDaily) % 3600) / 60
        let seconds = Int(timeUntilNextDaily) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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

    /// New Game button
    private var newGameButton: some View {
        Button {
            showingDifficultySelection = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("New Game")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(newGameButtonGradient)
            .cornerRadius(16)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    /// Gradient for new game button
    private var newGameButtonGradient: some View {
        LinearGradient(
            colors: [
                Color.blue,
                Color.blue.opacity(0.8),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
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

    // MARK: - Daily Challenge Card

    /// Daily challenge card with countdown timer
    private var dailyChallengeCard: some View {
        Button {
            onDailyChallenge?()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                dailyChallengeHeader
                dailyChallengeDescription
                Divider()
                dailyChallengeCountdown
            }
            .padding(20)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    /// Header section for daily challenge card
    private var dailyChallengeHeader: some View {
        HStack {
            HStack(spacing: 8) {
                dailyChallengeIcon
                Text("Daily Challenge")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Spacer()

            dailyChallengeNewBadge
        }
    }

    /// Icon for daily challenge card
    private var dailyChallengeIcon: some View {
        Image(systemName: "calendar.badge.clock")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    /// "NEW" badge for daily challenge
    private var dailyChallengeNewBadge: some View {
        Text("NEW")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.red)
            )
    }

    /// Description text for daily challenge
    private var dailyChallengeDescription: some View {
        Text("Complete today's puzzle and build your streak!")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.secondary)
            .lineLimit(2)
    }

    /// Countdown timer section
    private var dailyChallengeCountdown: some View {
        HStack {
            countdownTimer
            Spacer()
            playNowButton
        }
    }

    /// Countdown timer display
    private var countdownTimer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next Challenge In")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text(formattedCountdown)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    /// Play now button
    private var playNowButton: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.fill")
                .font(.system(size: 14))

            Text("Play Now")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(dailyChallengeGradient)
        .cornerRadius(10)
    }

    /// Gradient for daily challenge elements
    private var dailyChallengeGradient: some View {
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Timer Management

    /// Starts the countdown timer
    private func startTimer() {
        // Set initial time
        timeUntilNextDaily = timeUntilMidnight

        // Create timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            timeUntilNextDaily = timeUntilMidnight

            // If we've passed midnight, reset to the full day
            if timeUntilNextDaily < 0 {
                timeUntilNextDaily = timeUntilMidnight
            }
        }
    }

    /// Stops the countdown timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
