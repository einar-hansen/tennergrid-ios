import XCTest
@testable import TennerGrid

final class PersistenceSchemaTests: XCTestCase {
    // MARK: - Properties

    private var testDirectory: URL!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create a temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent(
            "TennerGridTests_\(UUID().uuidString)",
            isDirectory: true
        )

        try? FileManager.default.createDirectory(
            at: testDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    override func tearDown() {
        super.tearDown()

        // Clean up test directory
        if let testDir = testDirectory {
            try? FileManager.default.removeItem(at: testDir)
        }
    }

    // MARK: - Directory Tests

    func testDocumentsDirectoryExists() {
        let documentsDir = PersistenceSchema.documentsDirectory
        XCTAssertTrue(FileManager.default.fileExists(atPath: documentsDir.path))
    }

    func testAppDataDirectoryPath() {
        let appDataDir = PersistenceSchema.appDataDirectory
        XCTAssertTrue(appDataDir.path.contains("TennerGridData"))
    }

    func testEnsureDirectoryExistsCreatesDirectory() throws {
        // This test relies on the real app data directory
        // We'll verify it can be created
        try PersistenceSchema.ensureDirectoryExists()

        let appDataDir = PersistenceSchema.appDataDirectory
        XCTAssertTrue(FileManager.default.fileExists(atPath: appDataDir.path))
    }

    func testEnsureDirectoryExistsDoesNotFailIfAlreadyExists() throws {
        // Create directory twice - should not throw
        try PersistenceSchema.ensureDirectoryExists()
        XCTAssertNoThrow(try PersistenceSchema.ensureDirectoryExists())
    }

    // MARK: - File Path Tests

    func testSavedGameFilePath() {
        let path = PersistenceSchema.FilePath.savedGame
        XCTAssertTrue(path.path.hasSuffix("saved_game.json"))
    }

    func testStatisticsFilePath() {
        let path = PersistenceSchema.FilePath.statistics
        XCTAssertTrue(path.path.hasSuffix("statistics.json"))
    }

    func testAchievementsFilePath() {
        let path = PersistenceSchema.FilePath.achievements
        XCTAssertTrue(path.path.hasSuffix("achievements.json"))
    }

    func testSettingsFilePath() {
        let path = PersistenceSchema.FilePath.settings
        XCTAssertTrue(path.path.hasSuffix("settings.json"))
    }

    func testSchemaVersionFilePath() {
        let path = PersistenceSchema.FilePath.schemaVersion
        XCTAssertTrue(path.path.hasSuffix("schema_version.json"))
    }

    // MARK: - SavedGameData Tests

    func testSavedGameDataCreation() {
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        let savedGameData = PersistenceSchema.SavedGameData(gameState: gameState)

        XCTAssertEqual(savedGameData.schemaVersion, PersistenceSchema.currentVersion)
        XCTAssertEqual(savedGameData.gameState, gameState)
        XCTAssertNotNil(savedGameData.savedAt)
    }

    func testSavedGameDataCodable() throws {
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        let savedGameData = PersistenceSchema.SavedGameData(gameState: gameState)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(savedGameData)
        XCTAssertFalse(data.isEmpty)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersistenceSchema.SavedGameData.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, savedGameData.schemaVersion)
        XCTAssertEqual(decoded.gameState.puzzle.id, savedGameData.gameState.puzzle.id)
    }

    // MARK: - StatisticsData Tests

    func testStatisticsDataCreation() {
        let statistics = GameStatistics()
        let statsData = PersistenceSchema.StatisticsData(statistics: statistics)

        XCTAssertEqual(statsData.schemaVersion, PersistenceSchema.currentVersion)
        XCTAssertEqual(statsData.statistics, statistics)
        XCTAssertNotNil(statsData.updatedAt)
    }

    func testStatisticsDataCodable() throws {
        let statistics = GameStatistics()
        let statsData = PersistenceSchema.StatisticsData(statistics: statistics)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(statsData)
        XCTAssertFalse(data.isEmpty)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersistenceSchema.StatisticsData.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, statsData.schemaVersion)
        XCTAssertEqual(decoded.statistics, statsData.statistics)
    }

    // MARK: - AchievementsData Tests

    func testAchievementsDataCreation() {
        let achievements = Achievement.allAchievements
        let achievementsData = PersistenceSchema.AchievementsData(achievements: achievements)

        XCTAssertEqual(achievementsData.schemaVersion, PersistenceSchema.currentVersion)
        XCTAssertEqual(achievementsData.achievements.count, achievements.count)
        XCTAssertNotNil(achievementsData.updatedAt)
    }

    func testAchievementsDataCodable() throws {
        let achievements = Achievement.allAchievements
        let achievementsData = PersistenceSchema.AchievementsData(achievements: achievements)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(achievementsData)
        XCTAssertFalse(data.isEmpty)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersistenceSchema.AchievementsData.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, achievementsData.schemaVersion)
        XCTAssertEqual(decoded.achievements.count, achievementsData.achievements.count)
    }

    // MARK: - SettingsData Tests

    func testSettingsDataCreation() {
        let settings = UserSettings.default
        let settingsData = PersistenceSchema.SettingsData(settings: settings)

        XCTAssertEqual(settingsData.schemaVersion, PersistenceSchema.currentVersion)
        XCTAssertEqual(settingsData.settings, settings)
        XCTAssertNotNil(settingsData.updatedAt)
    }

    func testSettingsDataCodable() throws {
        let settings = UserSettings.default
        let settingsData = PersistenceSchema.SettingsData(settings: settings)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(settingsData)
        XCTAssertFalse(data.isEmpty)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersistenceSchema.SettingsData.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, settingsData.schemaVersion)
        XCTAssertEqual(decoded.settings, settingsData.settings)
    }

    // MARK: - SchemaVersionData Tests

    func testSchemaVersionDataCreation() {
        let versionData = PersistenceSchema.SchemaVersionData(version: 1)

        XCTAssertEqual(versionData.version, 1)
        XCTAssertNil(versionData.previousVersion)
        XCTAssertNotNil(versionData.setAt)
    }

    func testSchemaVersionDataWithPreviousVersion() {
        let versionData = PersistenceSchema.SchemaVersionData(version: 2, previousVersion: 1)

        XCTAssertEqual(versionData.version, 2)
        XCTAssertEqual(versionData.previousVersion, 1)
    }

    func testSchemaVersionDataCodable() throws {
        let versionData = PersistenceSchema.SchemaVersionData(version: 1, previousVersion: 0)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(versionData)
        XCTAssertFalse(data.isEmpty)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersistenceSchema.SchemaVersionData.self, from: data)

        XCTAssertEqual(decoded.version, versionData.version)
        XCTAssertEqual(decoded.previousVersion, versionData.previousVersion)
    }

    // MARK: - File Management Tests

    func testFileExistsReturnsFalseForNonexistentFile() {
        let fakePath = testDirectory.appendingPathComponent("nonexistent.json")
        XCTAssertFalse(PersistenceSchema.fileExists(at: fakePath))
    }

    func testFileExistsReturnsTrueForExistingFile() throws {
        let testFile = testDirectory.appendingPathComponent("test.json")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        XCTAssertTrue(PersistenceSchema.fileExists(at: testFile))
    }

    func testDeleteFileRemovesExistingFile() throws {
        let testFile = testDirectory.appendingPathComponent("test.json")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        XCTAssertTrue(PersistenceSchema.fileExists(at: testFile))

        try PersistenceSchema.deleteFile(at: testFile)

        XCTAssertFalse(PersistenceSchema.fileExists(at: testFile))
    }

    func testDeleteFileDoesNotThrowForNonexistentFile() throws {
        let fakePath = testDirectory.appendingPathComponent("nonexistent.json")
        XCTAssertNoThrow(try PersistenceSchema.deleteFile(at: fakePath))
    }

    func testFileSizeReturnsNilForNonexistentFile() {
        let fakePath = testDirectory.appendingPathComponent("nonexistent.json")
        XCTAssertNil(PersistenceSchema.fileSize(at: fakePath))
    }

    func testFileSizeReturnsCorrectSizeForExistingFile() throws {
        let testFile = testDirectory.appendingPathComponent("test.json")
        let testData = "test content"
        try testData.write(to: testFile, atomically: true, encoding: .utf8)

        let size = PersistenceSchema.fileSize(at: testFile)
        XCTAssertNotNil(size)
        XCTAssertGreaterThan(try XCTUnwrap(size), 0)
    }

    func testModificationDateReturnsNilForNonexistentFile() {
        let fakePath = testDirectory.appendingPathComponent("nonexistent.json")
        XCTAssertNil(PersistenceSchema.modificationDate(at: fakePath))
    }

    func testModificationDateReturnsDateForExistingFile() throws {
        let testFile = testDirectory.appendingPathComponent("test.json")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        let modDate = PersistenceSchema.modificationDate(at: testFile)
        XCTAssertNotNil(modDate)
    }

    // MARK: - Migration Tests

    func testMigrationWithInvalidVersionsThrows() {
        let testData = Data()

        XCTAssertThrowsError(
            try PersistenceSchema.Migration.migrate(fromVersion: 2, toVersion: 1, data: testData)
        ) { error in
            guard case let PersistenceSchema.MigrationError.invalidVersions(from, to) = error else {
                XCTFail("Expected invalidVersions error")
                return
            }
            XCTAssertEqual(from, 2)
            XCTAssertEqual(to, 1)
        }
    }

    func testMigrationFromV0ToV1Succeeds() throws {
        let testData = Data([1, 2, 3, 4])

        let migratedData = try PersistenceSchema.Migration.migrate(
            fromVersion: 0,
            toVersion: 1,
            data: testData
        )

        // V0 to V1 migration currently just returns the data as-is
        XCTAssertEqual(migratedData, testData)
    }

    func testMigrationErrorDescriptions() {
        let error1 = PersistenceSchema.MigrationError.invalidVersions(from: 1, to: 0)
        XCTAssertNotNil(error1.errorDescription)

        let error2 = PersistenceSchema.MigrationError.migrationFailed(version: 1, underlyingError: nil)
        XCTAssertNotNil(error2.errorDescription)

        let error3 = PersistenceSchema.MigrationError.corruptedData
        XCTAssertNotNil(error3.errorDescription)
    }

    // MARK: - Schema Version Tests

    func testCurrentVersionIsPositive() {
        XCTAssertGreaterThan(PersistenceSchema.currentVersion, 0)
    }

    // MARK: - Integration Tests

    func testCompleteDataFlowForSavedGame() throws {
        // Create game state
        let puzzle = TestFixtures.easyPuzzle
        let gameState = GameState(puzzle: puzzle)
        let savedGameData = PersistenceSchema.SavedGameData(gameState: gameState)

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(savedGameData)

        // Write to file
        let testFile = testDirectory.appendingPathComponent("saved_game.json")
        try jsonData.write(to: testFile)

        // Read from file
        let readData = try Data(contentsOf: testFile)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersistenceSchema.SavedGameData.self, from: readData)

        // Verify
        XCTAssertEqual(decoded.schemaVersion, savedGameData.schemaVersion)
        XCTAssertEqual(decoded.gameState.puzzle.id, savedGameData.gameState.puzzle.id)
        XCTAssertEqual(decoded.gameState.elapsedTime, savedGameData.gameState.elapsedTime)
    }

    func testCompleteDataFlowForStatistics() throws {
        // Create statistics
        var statistics = GameStatistics()
        statistics.recordGameStarted(difficulty: .medium)
        statistics.recordGameCompleted(difficulty: .medium, time: 120, hintsUsed: 2, errors: 1)

        let statsData = PersistenceSchema.StatisticsData(statistics: statistics)

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(statsData)

        // Write to file
        let testFile = testDirectory.appendingPathComponent("statistics.json")
        try jsonData.write(to: testFile)

        // Read from file
        let readData = try Data(contentsOf: testFile)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersistenceSchema.StatisticsData.self, from: readData)

        // Verify
        XCTAssertEqual(decoded.schemaVersion, statsData.schemaVersion)
        XCTAssertEqual(decoded.statistics.gamesPlayed, 1)
        XCTAssertEqual(decoded.statistics.gamesCompleted, 1)
    }
}
