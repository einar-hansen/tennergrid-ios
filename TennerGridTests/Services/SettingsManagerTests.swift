import Combine
import XCTest
@testable import TennerGrid

final class SettingsManagerTests: XCTestCase {
    // MARK: - Properties

    private var suiteName: String!
    private var userDefaults: UserDefaults!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test to avoid conflicts
        suiteName = "test.suite.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!

        // Clear any existing data
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        // Clean up test suite
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationWithNoSavedSettings() {
        // Given: No saved settings in UserDefaults
        // When: SettingsManager is initialized
        let manager = createTestManager()

        // Then: Default settings should be loaded
        XCTAssertEqual(manager.settings, .default)
    }

    func testInitializationWithSavedSettings() {
        // Given: Custom settings saved in UserDefaults
        let customSettings = UserSettings(
            autoCheckErrors: false,
            showTimer: false,
            highlightSameNumbers: false,
            hapticFeedback: false,
            soundEffects: false,
            themePreference: "dark",
            dailyReminder: true
        )
        saveSettings(customSettings)

        // When: SettingsManager is initialized
        let manager = createTestManager()

        // Then: Saved settings should be loaded
        XCTAssertEqual(manager.settings, customSettings)
    }

    func testInitializationWithCorruptedData() {
        // Given: Corrupted data in UserDefaults
        userDefaults.set("corrupted data", forKey: "com.tennergrid.userSettings")

        // When: SettingsManager is initialized
        let manager = createTestManager()

        // Then: Default settings should be used as fallback
        XCTAssertEqual(manager.settings, .default)
    }

    // MARK: - Update Settings Tests

    func testUpdateSettings() {
        // Given: Manager with default settings
        let manager = createTestManager()
        let newSettings = UserSettings(
            autoCheckErrors: false,
            showTimer: true,
            highlightSameNumbers: false,
            hapticFeedback: true,
            soundEffects: false,
            themePreference: "light",
            dailyReminder: true
        )

        // When: Settings are updated
        manager.updateSettings(newSettings)

        // Then: Settings should be updated and persisted
        XCTAssertEqual(manager.settings, newSettings)

        // And: Settings should be retrievable from UserDefaults
        let loadedSettings = loadSettings()
        XCTAssertEqual(loadedSettings, newSettings)
    }

    func testUpdateSettingWithKeyPath() {
        // Given: Manager with default settings
        let manager = createTestManager()
        XCTAssertTrue(manager.settings.autoCheckErrors)

        // When: A single setting is updated via key path
        manager.updateSetting(\.autoCheckErrors, value: false)

        // Then: Only that setting should be changed
        XCTAssertFalse(manager.settings.autoCheckErrors)
        XCTAssertTrue(manager.settings.showTimer) // Other settings unchanged
        XCTAssertTrue(manager.settings.highlightSameNumbers)

        // And: Change should be persisted
        let loadedSettings = loadSettings()
        XCTAssertFalse(loadedSettings?.autoCheckErrors ?? true)
    }

    func testUpdateMultipleSettingsSequentially() {
        // Given: Manager with default settings
        let manager = createTestManager()

        // When: Multiple settings are updated sequentially
        manager.updateSetting(\.autoCheckErrors, value: false)
        manager.updateSetting(\.soundEffects, value: false)
        manager.updateSetting(\.themePreference, value: "dark")
        manager.updateSetting(\.dailyReminder, value: true)

        // Then: All updates should be applied
        XCTAssertFalse(manager.settings.autoCheckErrors)
        XCTAssertFalse(manager.settings.soundEffects)
        XCTAssertEqual(manager.settings.themePreference, "dark")
        XCTAssertTrue(manager.settings.dailyReminder)

        // And: All changes should be persisted
        let loadedSettings = loadSettings()
        XCTAssertFalse(loadedSettings?.autoCheckErrors ?? true)
        XCTAssertFalse(loadedSettings?.soundEffects ?? true)
        XCTAssertEqual(loadedSettings?.themePreference, "dark")
        XCTAssertTrue(loadedSettings?.dailyReminder ?? false)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        // Given: Manager with custom settings
        let manager = createTestManager()
        let customSettings = UserSettings.allDisabled
        manager.updateSettings(customSettings)
        XCTAssertEqual(manager.settings, customSettings)

        // When: Settings are reset to defaults
        manager.resetToDefaults()

        // Then: Settings should be default
        XCTAssertEqual(manager.settings, .default)

        // And: Default settings should be persisted
        let loadedSettings = loadSettings()
        XCTAssertEqual(loadedSettings, .default)
    }

    // MARK: - Persistence Tests

    func testSettingsPersistence() {
        // Given: Manager with custom settings
        let manager = createTestManager()
        let customSettings = UserSettings(
            autoCheckErrors: false,
            showTimer: false,
            highlightSameNumbers: true,
            hapticFeedback: false,
            soundEffects: true,
            themePreference: "dark",
            dailyReminder: true
        )
        manager.updateSettings(customSettings)

        // When: Settings are loaded again (simulating app restart)
        let newManager = createTestManager()

        // Then: Same settings should be loaded
        XCTAssertEqual(newManager.settings, customSettings)
    }

    func testAllSettingsPersist() throws {
        // Given: Manager with all settings modified
        let manager = createTestManager()

        // When: All settings are changed
        manager.updateSetting(\.autoCheckErrors, value: false)
        manager.updateSetting(\.showTimer, value: false)
        manager.updateSetting(\.highlightSameNumbers, value: false)
        manager.updateSetting(\.hapticFeedback, value: false)
        manager.updateSetting(\.soundEffects, value: false)
        manager.updateSetting(\.themePreference, value: "light")
        manager.updateSetting(\.dailyReminder, value: true)

        // Then: All settings should persist
        let loadedSettings = loadSettings()
        XCTAssertNotNil(loadedSettings)
        XCTAssertFalse(try XCTUnwrap(loadedSettings?.autoCheckErrors))
        XCTAssertFalse(try XCTUnwrap(loadedSettings?.showTimer))
        XCTAssertFalse(try XCTUnwrap(loadedSettings?.highlightSameNumbers))
        XCTAssertFalse(try XCTUnwrap(loadedSettings?.hapticFeedback))
        XCTAssertFalse(try XCTUnwrap(loadedSettings?.soundEffects))
        XCTAssertEqual(loadedSettings?.themePreference, "light")
        XCTAssertTrue(try XCTUnwrap(loadedSettings?.dailyReminder))
    }

    // MARK: - Edge Cases

    func testUpdateSettingPreservesOtherSettings() {
        // Given: Manager with known settings
        let manager = createTestManager()
        let initialSettings = manager.settings

        // When: One setting is updated
        manager.updateSetting(\.themePreference, value: "dark")

        // Then: Only that setting should change
        XCTAssertNotEqual(manager.settings.themePreference, initialSettings.themePreference)
        XCTAssertEqual(manager.settings.autoCheckErrors, initialSettings.autoCheckErrors)
        XCTAssertEqual(manager.settings.showTimer, initialSettings.showTimer)
        XCTAssertEqual(manager.settings.highlightSameNumbers, initialSettings.highlightSameNumbers)
        XCTAssertEqual(manager.settings.hapticFeedback, initialSettings.hapticFeedback)
        XCTAssertEqual(manager.settings.soundEffects, initialSettings.soundEffects)
        XCTAssertEqual(manager.settings.dailyReminder, initialSettings.dailyReminder)
    }

    func testMultipleManagerInstancesShareSettings() {
        // Given: Two manager instances
        let manager1 = createTestManager()
        let manager2 = createTestManager()

        // When: Settings are updated via first manager
        let customSettings = UserSettings.allDisabled
        manager1.updateSettings(customSettings)

        // Then: Second manager should load the updated settings
        let reloadedManager = createTestManager()
        XCTAssertEqual(reloadedManager.settings, customSettings)
    }

    // MARK: - Helper Methods

    /// Creates a test manager instance that uses the test UserDefaults
    private func createTestManager() -> TestSettingsManager {
        TestSettingsManager(userDefaults: userDefaults)
    }

    /// Saves settings directly to test UserDefaults
    private func saveSettings(_ settings: UserSettings) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: "com.tennergrid.userSettings")
        } catch {
            XCTFail("Failed to save test settings: \(error)")
        }
    }

    /// Loads settings directly from test UserDefaults
    private func loadSettings() -> UserSettings? {
        guard let data = userDefaults.data(forKey: "com.tennergrid.userSettings") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(UserSettings.self, from: data)
        } catch {
            XCTFail("Failed to load test settings: \(error)")
            return nil
        }
    }
}

// MARK: - Test Settings Manager

/// Test version of SettingsManager that uses a custom UserDefaults
private final class TestSettingsManager: ObservableObject {
    @Published private(set) var settings: UserSettings
    private let userDefaults: UserDefaults
    private let settingsKey = "com.tennergrid.userSettings"

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.settings = TestSettingsManager.loadSettings(from: userDefaults) ?? .default
    }

    func updateSettings(_ settings: UserSettings) {
        self.settings = settings
        saveSettings()
    }

    func updateSetting<T>(_ keyPath: WritableKeyPath<UserSettings, T>, value: T) {
        settings[keyPath: keyPath] = value
        saveSettings()
    }

    func resetToDefaults() {
        settings = .default
        saveSettings()
    }

    private func saveSettings() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            print("Failed to save settings: \(error.localizedDescription)")
        }
    }

    private static func loadSettings(from userDefaults: UserDefaults) -> UserSettings? {
        guard let data = userDefaults.data(forKey: "com.tennergrid.userSettings") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(UserSettings.self, from: data)
        } catch {
            print("Failed to load settings: \(error.localizedDescription)")
            return nil
        }
    }
}
