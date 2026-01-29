import Combine
import Foundation

/// Service responsible for managing the puzzle library and saved games
@MainActor
final class PuzzleManager: ObservableObject {
    // MARK: - Published Properties

    /// Current puzzle being played (nil if no active game)
    @Published private(set) var currentPuzzle: TennerGridPuzzle?

    /// List of saved games
    @Published private(set) var savedGames: [SavedGame] = []

    // MARK: - Private Properties

    /// UserDefaults instance to use for persistence
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Load saved games on initialization
        loadSavedGames()
    }

    // MARK: - Puzzle Selection

    /// Returns a random puzzle with specified parameters
    /// - Parameters:
    ///   - rows: Number of rows (3-10, defaults to 5)
    ///   - difficulty: Desired difficulty level
    /// - Returns: A random TennerGridPuzzle, or nil if none available
    /// - Note: All Tenner Grid puzzles have exactly 10 columns
    func randomPuzzle(
        rows: Int = 5,
        difficulty: Difficulty
    ) -> TennerGridPuzzle? {
        // Validate dimensions - rows must be 3-10
        // All puzzles have exactly 10 columns (required for game rules)
        guard rows >= 3, rows <= 10 else { return nil }

        return BundledPuzzleService.shared.randomPuzzle(difficulty: difficulty, rows: rows)
    }

    /// Returns the first puzzle matching the criteria (deterministic)
    /// - Parameters:
    ///   - rows: Number of rows (3-10, defaults to 5)
    ///   - difficulty: Desired difficulty level
    /// - Returns: The first matching TennerGridPuzzle, or nil if none available
    /// - Note: All Tenner Grid puzzles have exactly 10 columns
    func firstPuzzle(
        rows: Int = 5,
        difficulty: Difficulty
    ) -> TennerGridPuzzle? {
        // Validate dimensions - rows must be 3-10
        // All puzzles have exactly 10 columns (required for game rules)
        guard rows >= 3, rows <= 10 else { return nil }

        return BundledPuzzleService.shared.firstPuzzle(difficulty: difficulty, rows: rows)
    }

    /// Returns a daily puzzle based on the current date
    /// Uses a deterministic selection based on day of year
    /// - Returns: A TennerGridPuzzle for today
    func dailyPuzzle() -> TennerGridPuzzle? {
        dailyPuzzle(for: Date())
    }

    /// Returns a daily puzzle for a specific date
    /// Uses a deterministic selection based on the date
    /// - Parameter date: The date to get a puzzle for
    /// - Returns: A TennerGridPuzzle for the specified date
    func dailyPuzzle(for date: Date) -> TennerGridPuzzle? {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Get all medium puzzles with 5 rows (standard daily puzzle)
        let puzzles = BundledPuzzleService.shared.puzzles(difficulty: .medium, rows: 5)
        guard !puzzles.isEmpty else { return nil }

        // Use day of year to select deterministically
        let index = (dayOfYear - 1) % puzzles.count
        return puzzles[index]
    }

    /// Returns all available puzzles matching the criteria
    /// - Parameters:
    ///   - difficulty: Optional difficulty filter
    ///   - rows: Optional rows filter
    /// - Returns: Array of matching puzzles
    func puzzles(difficulty: Difficulty? = nil, rows: Int? = nil) -> [TennerGridPuzzle] {
        BundledPuzzleService.shared.puzzles(difficulty: difficulty, rows: rows)
    }

    /// Returns available row counts for a difficulty
    func availableRows(for difficulty: Difficulty) -> [Int] {
        BundledPuzzleService.shared.availableRows(for: difficulty)
    }

    /// Total number of available puzzles
    var puzzleCount: Int {
        BundledPuzzleService.shared.count
    }

    // MARK: - Saved Games Management

    /// Adds a game to the saved games list
    /// - Parameter game: The SavedGame to add
    func addSavedGame(_ game: SavedGame) {
        // Remove existing game with same puzzle ID if present
        savedGames.removeAll { $0.puzzle.id == game.puzzle.id }

        // Add new game at the beginning (most recent first)
        savedGames.insert(game, at: 0)

        // Limit to 20 most recent saved games
        if savedGames.count > 20 {
            savedGames = Array(savedGames.prefix(20))
        }

        // Persist to storage
        saveSavedGamesToStorage()
    }

    /// Removes a saved game by puzzle ID
    /// - Parameter puzzleID: The ID of the puzzle to remove
    func removeSavedGame(withPuzzleID puzzleID: UUID) {
        savedGames.removeAll { $0.puzzle.id == puzzleID }
        saveSavedGamesToStorage()
    }

    /// Removes all saved games
    func removeAllSavedGames() {
        savedGames.removeAll()
        saveSavedGamesToStorage()
    }

    /// Loads a saved game by puzzle ID
    /// - Parameter puzzleID: The ID of the puzzle to load
    /// - Returns: The SavedGame if found, nil otherwise
    func loadSavedGame(withPuzzleID puzzleID: UUID) -> SavedGame? {
        savedGames.first { $0.puzzle.id == puzzleID }
    }

    /// Sets the current puzzle being played
    /// - Parameter puzzle: The puzzle to set as current
    func setCurrentPuzzle(_ puzzle: TennerGridPuzzle?) {
        currentPuzzle = puzzle
    }

    // MARK: - Private Helper Methods

    /// Loads saved games from persistent storage
    private func loadSavedGames() {
        // For now, we'll use UserDefaults for simple persistence
        // This can be upgraded to SwiftData or FileManager later
        guard let data = userDefaults.data(forKey: "savedGames") else {
            savedGames = []
            return
        }

        do {
            savedGames = try JSONDecoder().decode([SavedGame].self, from: data)
        } catch {
            print("Failed to load saved games: \(error)")
            savedGames = []
        }
    }

    /// Saves the current saved games list to persistent storage
    private func saveSavedGamesToStorage() {
        do {
            let data = try JSONEncoder().encode(savedGames)
            userDefaults.set(data, forKey: "savedGames")
        } catch {
            print("Failed to save games: \(error)")
        }
    }
}

// MARK: - SavedGame Model

/// Represents a saved game state
struct SavedGame: Codable, Identifiable {
    /// Unique identifier (uses puzzle ID)
    var id: UUID {
        puzzle.id
    }

    /// The puzzle being played
    let puzzle: TennerGridPuzzle

    /// Current game state
    let gameState: GameState

    /// Date when the game was last saved
    let savedAt: Date

    /// Creates a new saved game
    /// - Parameters:
    ///   - puzzle: The puzzle being played
    ///   - gameState: The current game state
    ///   - savedAt: When the game was saved (defaults to now)
    init(puzzle: TennerGridPuzzle, gameState: GameState, savedAt: Date = Date()) {
        self.puzzle = puzzle
        self.gameState = gameState
        self.savedAt = savedAt
    }
}

// MARK: - SavedGame Extensions

extension SavedGame {
    /// Returns a formatted time string for the elapsed time
    var formattedElapsedTime: String {
        gameState.formattedTime
    }

    /// Returns the completion progress as a percentage
    var progressPercentage: Double {
        gameState.progress * 100
    }

    /// Whether this game can be resumed
    var canResume: Bool {
        gameState.canResume
    }
}
