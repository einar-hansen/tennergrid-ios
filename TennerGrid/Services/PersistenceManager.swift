import Foundation

/// Service responsible for persisting and loading app data to/from disk
/// Uses JSON files with Codable for data serialization
// swiftlint:disable:next type_body_length
final class PersistenceManager {
    // MARK: - Singleton

    /// Shared instance for global access
    static let shared = PersistenceManager()

    // MARK: - Properties

    /// JSON encoder configured for pretty-printed output
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// JSON decoder configured for date handling
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// File manager for I/O operations
    private let fileManager = FileManager.default

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    private init() {
        // Ensure data directory exists
        do {
            try PersistenceSchema.initialize()
        } catch {
            // Failed to initialize - this will be handled by individual save/load operations
            // Error will surface when actually trying to save/load data
        }
    }

    // MARK: - Game State Persistence

    /// Saves the current game state to disk
    /// - Parameter gameState: The game state to save
    /// - Throws: PersistenceError if save fails
    func saveGame(_ gameState: GameState) throws {
        let data = PersistenceSchema.SavedGameData(gameState: gameState)
        try save(data, to: PersistenceSchema.FilePath.savedGame)
    }

    /// Loads the saved game state from disk
    /// - Returns: The saved game state, or nil if no save exists
    /// - Throws: PersistenceError if load fails
    func loadGame() throws -> GameState? {
        guard PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.savedGame) else {
            return nil
        }

        let data: PersistenceSchema.SavedGameData = try load(from: PersistenceSchema.FilePath.savedGame)
        return data.gameState
    }

    /// Safely loads the saved game state with automatic recovery from corruption
    /// This method catches all errors and deletes corrupted files automatically
    /// - Returns: The saved game state, or nil if no save exists or if data is corrupted
    func loadGameSafely() -> GameState? {
        do {
            return try loadGame()
        } catch let error as PersistenceError {
            // Check if this is a corruption-related error that should trigger cleanup
            let shouldDeleteCorruptedFile = switch error {
            case .decodingFailed, .corruptedData:
                true
            default:
                false
            }

            if shouldDeleteCorruptedFile {
                // Delete the corrupted file to prevent future errors
                try? deleteSavedGame()

                #if DEBUG
                    NSLog("Deleted corrupted saved game file: \(error.localizedDescription)")
                #endif
            } else {
                // Log non-corruption errors but don't delete the file
                #if DEBUG
                    NSLog("Failed to load saved game (not corruption): \(error.localizedDescription)")
                #endif
            }

            return nil
        } catch {
            // Handle unexpected errors
            #if DEBUG
                NSLog("Unexpected error loading saved game: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// Deletes the saved game from disk
    /// - Throws: PersistenceError if deletion fails
    func deleteSavedGame() throws {
        try PersistenceSchema.deleteFile(at: PersistenceSchema.FilePath.savedGame)
    }

    /// Checks if a saved game exists
    /// - Returns: True if a saved game file exists
    func hasSavedGame() -> Bool {
        PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.savedGame)
    }

    // MARK: - Statistics Persistence

    /// Saves game statistics to disk
    /// - Parameter statistics: The statistics to save
    /// - Throws: PersistenceError if save fails
    func saveStatistics(_ statistics: GameStatistics) throws {
        let data = PersistenceSchema.StatisticsData(statistics: statistics)
        try save(data, to: PersistenceSchema.FilePath.statistics)
    }

    /// Loads game statistics from disk
    /// - Returns: The saved statistics, or new empty statistics if none exist
    /// - Throws: PersistenceError if load fails
    func loadStatistics() throws -> GameStatistics {
        guard PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.statistics) else {
            return GameStatistics()
        }

        let data: PersistenceSchema.StatisticsData = try load(from: PersistenceSchema.FilePath.statistics)
        return data.statistics
    }

    /// Safely loads statistics with automatic recovery from corruption
    /// - Returns: The saved statistics, or new empty statistics if load fails
    func loadStatisticsSafely() -> GameStatistics {
        do {
            return try loadStatistics()
        } catch let error as PersistenceError {
            let shouldDeleteCorruptedFile = switch error {
            case .decodingFailed, .corruptedData:
                true
            default:
                false
            }

            if shouldDeleteCorruptedFile {
                try? deleteStatistics()
                #if DEBUG
                    NSLog("Deleted corrupted statistics file: \(error.localizedDescription)")
                #endif
            }

            return GameStatistics()
        } catch {
            #if DEBUG
                NSLog("Unexpected error loading statistics: \(error.localizedDescription)")
            #endif
            return GameStatistics()
        }
    }

    /// Deletes all statistics data
    /// - Throws: PersistenceError if deletion fails
    func deleteStatistics() throws {
        try PersistenceSchema.deleteFile(at: PersistenceSchema.FilePath.statistics)
    }

    // MARK: - Achievements Persistence

    /// Saves achievements list to disk
    /// - Parameter achievements: The achievements to save
    /// - Throws: PersistenceError if save fails
    func saveAchievements(_ achievements: [Achievement]) throws {
        let data = PersistenceSchema.AchievementsData(achievements: achievements)
        try save(data, to: PersistenceSchema.FilePath.achievements)
    }

    /// Loads achievements from disk
    /// - Returns: The saved achievements, or all default achievements if none exist
    /// - Throws: PersistenceError if load fails
    func loadAchievements() throws -> [Achievement] {
        guard PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.achievements) else {
            return Achievement.allAchievements
        }

        let data: PersistenceSchema.AchievementsData = try load(from: PersistenceSchema.FilePath.achievements)
        return data.achievements
    }

    /// Safely loads achievements with automatic recovery from corruption
    /// - Returns: The saved achievements, or default achievements if load fails
    func loadAchievementsSafely() -> [Achievement] {
        do {
            return try loadAchievements()
        } catch let error as PersistenceError {
            let shouldDeleteCorruptedFile = switch error {
            case .decodingFailed, .corruptedData:
                true
            default:
                false
            }

            if shouldDeleteCorruptedFile {
                try? deleteAchievements()
                #if DEBUG
                    NSLog("Deleted corrupted achievements file: \(error.localizedDescription)")
                #endif
            }

            return Achievement.allAchievements
        } catch {
            #if DEBUG
                NSLog("Unexpected error loading achievements: \(error.localizedDescription)")
            #endif
            return Achievement.allAchievements
        }
    }

    /// Deletes all achievements data
    /// - Throws: PersistenceError if deletion fails
    func deleteAchievements() throws {
        try PersistenceSchema.deleteFile(at: PersistenceSchema.FilePath.achievements)
    }

    // MARK: - Settings Persistence

    /// Saves user settings to disk
    /// - Parameter settings: The settings to save
    /// - Throws: PersistenceError if save fails
    func saveSettings(_ settings: UserSettings) throws {
        let data = PersistenceSchema.SettingsData(settings: settings)
        try save(data, to: PersistenceSchema.FilePath.settings)
    }

    /// Loads user settings from disk
    /// - Returns: The saved settings, or default settings if none exist
    /// - Throws: PersistenceError if load fails
    func loadSettings() throws -> UserSettings {
        guard PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.settings) else {
            return UserSettings()
        }

        let data: PersistenceSchema.SettingsData = try load(from: PersistenceSchema.FilePath.settings)
        return data.settings
    }

    /// Safely loads settings with automatic recovery from corruption
    /// - Returns: The saved settings, or default settings if load fails
    func loadSettingsSafely() -> UserSettings {
        do {
            return try loadSettings()
        } catch let error as PersistenceError {
            let shouldDeleteCorruptedFile = switch error {
            case .decodingFailed, .corruptedData:
                true
            default:
                false
            }

            if shouldDeleteCorruptedFile {
                try? deleteSettings()
                #if DEBUG
                    NSLog("Deleted corrupted settings file: \(error.localizedDescription)")
                #endif
            }

            return UserSettings()
        } catch {
            #if DEBUG
                NSLog("Unexpected error loading settings: \(error.localizedDescription)")
            #endif
            return UserSettings()
        }
    }

    /// Deletes all settings data
    /// - Throws: PersistenceError if deletion fails
    func deleteSettings() throws {
        try PersistenceSchema.deleteFile(at: PersistenceSchema.FilePath.settings)
    }

    // MARK: - Generic Save/Load

    /// Generic method to save any Codable data to a file
    /// - Parameters:
    ///   - data: The data to save (must be Codable)
    ///   - url: The file URL to save to
    /// - Throws: PersistenceError if save fails
    private func save(_ data: some Codable, to url: URL) throws {
        do {
            // Ensure directory exists
            try PersistenceSchema.ensureDirectoryExists()

            // Encode data to JSON
            let jsonData = try encoder.encode(data)

            // Write to file
            try jsonData.write(to: url, options: [.atomic, .completeFileProtection])
        } catch let error as EncodingError {
            throw PersistenceError.encodingFailed(error)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain {
            throw PersistenceError.writeFailed(url: url, underlyingError: error)
        } catch {
            throw PersistenceError.unknownError(error)
        }
    }

    /// Generic method to load any Codable data from a file
    /// - Parameter url: The file URL to load from
    /// - Returns: The decoded data
    /// - Throws: PersistenceError if load fails
    private func load<T: Codable>(from url: URL) throws -> T {
        do {
            // Read data from file
            let jsonData = try Data(contentsOf: url)

            // Basic corruption check: verify it's valid JSON
            // This catches empty files, truncated files, or non-JSON data
            guard !jsonData.isEmpty else {
                throw PersistenceError.corruptedData(url: url)
            }

            // Decode JSON
            return try decoder.decode(T.self, from: jsonData)
        } catch let error as DecodingError {
            // Decoding failures indicate corrupted or incompatible data
            throw PersistenceError.decodingFailed(error)
        } catch let error as PersistenceError {
            // Re-throw our own errors as-is
            throw error
        } catch let error as NSError where error.domain == NSCocoaErrorDomain {
            throw PersistenceError.readFailed(url: url, underlyingError: error)
        } catch {
            throw PersistenceError.unknownError(error)
        }
    }

    // MARK: - Bulk Operations

    /// Saves all app data (game, statistics, achievements, settings)
    /// - Parameters:
    ///   - gameState: Optional game state to save
    ///   - statistics: Optional statistics to save
    ///   - achievements: Optional achievements to save
    ///   - settings: Optional settings to save
    /// - Returns: Array of any errors that occurred (empty if all succeeded)
    func saveAll(
        gameState: GameState? = nil,
        statistics: GameStatistics? = nil,
        achievements: [Achievement] = [],
        settings: UserSettings? = nil
    ) -> [PersistenceError] {
        var errors: [PersistenceError] = []

        if let gameState {
            errors.append(contentsOf: performSave { try saveGame(gameState) })
        }

        if let statistics {
            errors.append(contentsOf: performSave { try saveStatistics(statistics) })
        }

        if !achievements.isEmpty {
            errors.append(contentsOf: performSave { try saveAchievements(achievements) })
        }

        if let settings {
            errors.append(contentsOf: performSave { try saveSettings(settings) })
        }

        return errors
    }

    /// Helper method to perform a save operation and capture errors
    /// - Parameter operation: The save operation to perform
    /// - Returns: Array containing any error that occurred (empty if succeeded)
    private func performSave(_ operation: () throws -> Void) -> [PersistenceError] {
        do {
            try operation()
            return []
        } catch {
            if let persistenceError = error as? PersistenceError {
                return [persistenceError]
            } else {
                return [.unknownError(error)]
            }
        }
    }

    /// Loads all app data
    /// - Returns: AppData struct containing all loaded data
    /// - Throws: PersistenceError if any critical load fails
    func loadAll() throws -> AppData {
        let gameState = try loadGame()
        let statistics = try loadStatistics()
        let achievements = try loadAchievements()
        let settings = try loadSettings()

        return AppData(
            gameState: gameState,
            statistics: statistics,
            achievements: achievements,
            settings: settings
        )
    }

    /// Safely loads all app data with automatic recovery from corruption
    /// This method never throws and returns sensible defaults for any corrupted data
    /// - Returns: AppData struct containing all loaded data (with defaults for corrupted files)
    func loadAllSafely() -> AppData {
        let gameState = loadGameSafely()
        let statistics = loadStatisticsSafely()
        let achievements = loadAchievementsSafely()
        let settings = loadSettingsSafely()

        return AppData(
            gameState: gameState,
            statistics: statistics,
            achievements: achievements,
            settings: settings
        )
    }

    /// Container for all app data
    struct AppData {
        let gameState: GameState?
        let statistics: GameStatistics
        let achievements: [Achievement]
        let settings: UserSettings
    }

    /// Deletes all app data (use with caution!)
    /// - Returns: Array of any errors that occurred (empty if all succeeded)
    func deleteAll() -> [PersistenceError] {
        var errors: [PersistenceError] = []

        do {
            try deleteSavedGame()
        } catch {
            if let persistenceError = error as? PersistenceError {
                errors.append(persistenceError)
            } else {
                errors.append(.unknownError(error))
            }
        }

        do {
            try deleteStatistics()
        } catch {
            if let persistenceError = error as? PersistenceError {
                errors.append(persistenceError)
            } else {
                errors.append(.unknownError(error))
            }
        }

        do {
            try deleteAchievements()
        } catch {
            if let persistenceError = error as? PersistenceError {
                errors.append(persistenceError)
            } else {
                errors.append(.unknownError(error))
            }
        }

        do {
            try deleteSettings()
        } catch {
            if let persistenceError = error as? PersistenceError {
                errors.append(persistenceError)
            } else {
                errors.append(.unknownError(error))
            }
        }

        return errors
    }

    // MARK: - File Information

    /// Gets information about all persisted files
    /// - Returns: Dictionary mapping file type to file info
    func getFileInfo() -> [String: FileInfo] {
        var info: [String: FileInfo] = [:]

        let files: [(String, URL)] = [
            ("savedGame", PersistenceSchema.FilePath.savedGame),
            ("statistics", PersistenceSchema.FilePath.statistics),
            ("achievements", PersistenceSchema.FilePath.achievements),
            ("settings", PersistenceSchema.FilePath.settings),
        ]

        for (name, url) in files {
            if PersistenceSchema.fileExists(at: url) {
                info[name] = FileInfo(
                    exists: true,
                    size: PersistenceSchema.fileSize(at: url),
                    modificationDate: PersistenceSchema.modificationDate(at: url)
                )
            } else {
                info[name] = FileInfo(exists: false, size: nil, modificationDate: nil)
            }
        }

        return info
    }

    // MARK: - Migration

    /// Checks if data migration is needed
    /// - Returns: True if current schema version differs from saved version
    func needsMigration() -> Bool {
        guard let currentVersion = PersistenceSchema.getCurrentSchemaVersion() else {
            return false
        }
        return currentVersion != PersistenceSchema.currentVersion
    }

    /// Performs data migration if needed
    /// - Throws: PersistenceError if migration fails
    func performMigrationIfNeeded() throws {
        guard needsMigration() else { return }

        guard let currentVersion = PersistenceSchema.getCurrentSchemaVersion() else {
            // No version file exists - first install, no migration needed
            return
        }

        // Create backup before migration
        do {
            try PersistenceSchema.createBackup()
        } catch {
            throw PersistenceError.migrationFailed(
                version: currentVersion,
                underlyingError: error
            )
        }

        // Perform migration
        // Currently no migrations needed as we're on version 1
        // Future migrations would be implemented here

        // Update version
        try PersistenceSchema.updateSchemaVersion(to: PersistenceSchema.currentVersion)
    }
}

// MARK: - FileInfo

extension PersistenceManager {
    /// Information about a persisted file
    struct FileInfo {
        /// Whether the file exists
        let exists: Bool

        /// File size in bytes
        let size: Int?

        /// Last modification date
        let modificationDate: Date?

        /// Human-readable file size
        var formattedSize: String? {
            guard let size else { return nil }

            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(size))
        }
    }
}

// MARK: - PersistenceError

/// Errors that can occur during persistence operations
enum PersistenceError: Error, LocalizedError {
    /// Failed to encode data to JSON
    case encodingFailed(EncodingError)

    /// Failed to decode data from JSON
    case decodingFailed(DecodingError)

    /// Failed to write data to file
    case writeFailed(url: URL, underlyingError: Error)

    /// Failed to read data from file
    case readFailed(url: URL, underlyingError: Error)

    /// Migration failed
    case migrationFailed(version: Int, underlyingError: Error)

    /// Data is corrupted and cannot be read
    case corruptedData(url: URL)

    /// Unknown error occurred
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case let .encodingFailed(error):
            "Failed to encode data: \(error.localizedDescription)"
        case let .decodingFailed(error):
            "Failed to decode data: \(error.localizedDescription)"
        case let .writeFailed(url, error):
            "Failed to write to \(url.lastPathComponent): \(error.localizedDescription)"
        case let .readFailed(url, error):
            "Failed to read from \(url.lastPathComponent): \(error.localizedDescription)"
        case let .migrationFailed(version, error):
            "Migration to version \(version) failed: \(error.localizedDescription)"
        case let .corruptedData(url):
            "Data in \(url.lastPathComponent) is corrupted"
        case let .unknownError(error):
            "Unknown error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .encodingFailed:
            "The data could not be saved. Try restarting the app."
        case .decodingFailed, .corruptedData:
            "The saved data is corrupted. You may need to reset your progress."
        case .writeFailed:
            "Unable to save data. Check available storage space."
        case .readFailed:
            "Unable to load data. The file may not exist or is inaccessible."
        case .migrationFailed:
            "Failed to migrate data to new format. Your data has been backed up."
        case .unknownError:
            "An unexpected error occurred. Try restarting the app."
        }
    }
}

// MARK: - Convenience Extensions

extension PersistenceManager {
    /// Checks if any data exists (used to determine if this is first launch)
    var hasAnyData: Bool {
        hasSavedGame() ||
            PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.statistics) ||
            PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.achievements) ||
            PersistenceSchema.fileExists(at: PersistenceSchema.FilePath.settings)
    }

    /// Gets the total size of all persisted data in bytes
    var totalDataSize: Int {
        let files = [
            PersistenceSchema.FilePath.savedGame,
            PersistenceSchema.FilePath.statistics,
            PersistenceSchema.FilePath.achievements,
            PersistenceSchema.FilePath.settings,
        ]

        return files.compactMap { PersistenceSchema.fileSize(at: $0) }.reduce(0, +)
    }

    /// Gets a human-readable total data size string
    var formattedTotalDataSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalDataSize))
    }
}
