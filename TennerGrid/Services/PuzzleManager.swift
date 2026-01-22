//
//  PuzzleManager.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

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

    /// Whether a puzzle generation is in progress
    @Published private(set) var isGenerating = false

    // MARK: - Private Properties

    private let generator = PuzzleGenerator()
    private let solver = PuzzleSolver()

    // MARK: - Initialization

    init() {
        // Load saved games on initialization
        loadSavedGames()
    }

    // MARK: - Puzzle Generation

    /// Generates a new puzzle with specified parameters
    /// - Parameters:
    ///   - columns: Number of columns (5-10, defaults to 10)
    ///   - rows: Number of rows (5-10, defaults to 5)
    ///   - difficulty: Desired difficulty level
    /// - Returns: A new TennerGridPuzzle, or nil if generation fails
    func generateNewPuzzle(
        columns: Int = 10,
        rows: Int = 5,
        difficulty: Difficulty
    ) async -> TennerGridPuzzle? {
        isGenerating = true
        defer { isGenerating = false }

        // Validate dimensions
        guard columns >= 5, columns <= 10 else { return nil }
        guard rows >= 5, rows <= 10 else { return nil }

        // Run generation on background thread to avoid blocking UI
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }
            return generator.generatePuzzle(
                columns: columns,
                rows: rows,
                difficulty: difficulty
            )
        }.value
    }

    /// Generates a daily puzzle deterministically based on the current date
    /// - Returns: A TennerGridPuzzle for today's date, or nil if generation fails
    func generateDailyPuzzle() async -> TennerGridPuzzle? {
        isGenerating = true
        defer { isGenerating = false }

        // Generate seed from today's date
        let seed = seedForDate(Date())

        // Run generation on background thread
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }

            // Daily puzzles use standard 10x5 grid with medium difficulty
            return generator.generatePuzzle(
                columns: 10,
                rows: 5,
                difficulty: .medium,
                seed: seed
            )
        }.value
    }

    /// Generates a daily puzzle for a specific date
    /// - Parameter date: The date to generate a puzzle for
    /// - Returns: A TennerGridPuzzle for the specified date, or nil if generation fails
    func generateDailyPuzzle(for date: Date) async -> TennerGridPuzzle? {
        isGenerating = true
        defer { isGenerating = false }

        // Generate seed from the specified date
        let seed = seedForDate(date)

        // Run generation on background thread
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }

            // Daily puzzles use standard 10x5 grid with medium difficulty
            return generator.generatePuzzle(
                columns: 10,
                rows: 5,
                difficulty: .medium,
                seed: seed
            )
        }.value
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

    /// Generates a deterministic seed from a date
    /// - Parameter date: The date to convert to a seed
    /// - Returns: A UInt64 seed value
    private func seedForDate(_ date: Date) -> UInt64 {
        // Get calendar components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        // Create a seed from the date components
        // This ensures the same date always generates the same puzzle
        let year = UInt64(components.year ?? 2026)
        let month = UInt64(components.month ?? 1)
        let day = UInt64(components.day ?? 1)

        // Combine components into a single seed
        // Formula: year * 10000 + month * 100 + day
        return year * 10000 + month * 100 + day
    }

    /// Loads saved games from persistent storage
    private func loadSavedGames() {
        // For now, we'll use UserDefaults for simple persistence
        // This can be upgraded to SwiftData or FileManager later
        guard let data = UserDefaults.standard.data(forKey: "savedGames") else {
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
            UserDefaults.standard.set(data, forKey: "savedGames")
        } catch {
            print("Failed to save games: \(error)")
        }
    }
}

// MARK: - SavedGame Model

/// Represents a saved game state
struct SavedGame: Codable, Identifiable {
    /// Unique identifier (uses puzzle ID)
    var id: UUID { puzzle.id }

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
