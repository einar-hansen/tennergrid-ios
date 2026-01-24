import XCTest
import SwiftUI
@testable import TennerGrid

/// Tests for TabBarView navigation and state preservation
@MainActor
final class TabBarViewTests: XCTestCase {
    // MARK: - Tab Enumeration Tests

    /// Tests that all tab cases have unique raw values
    func testTabRawValues() {
        // Given
        let mainTab = TabBarView.Tab.main
        let dailyChallengesTab = TabBarView.Tab.dailyChallenges
        let profileTab = TabBarView.Tab.profile

        // Then
        XCTAssertEqual(mainTab.rawValue, 0)
        XCTAssertEqual(dailyChallengesTab.rawValue, 1)
        XCTAssertEqual(profileTab.rawValue, 2)
    }

    /// Tests that all tabs are iterable via CaseIterable
    func testTabCaseIterable() {
        // Given
        let allTabs = TabBarView.Tab.allCases

        // Then
        XCTAssertEqual(allTabs.count, 3)
        XCTAssertTrue(allTabs.contains(.main))
        XCTAssertTrue(allTabs.contains(.dailyChallenges))
        XCTAssertTrue(allTabs.contains(.profile))
    }

    /// Tests that each tab has a unique ID for Identifiable conformance
    func testTabIdentifiable() {
        // Given
        let mainTab = TabBarView.Tab.main
        let dailyChallengesTab = TabBarView.Tab.dailyChallenges
        let profileTab = TabBarView.Tab.profile

        // Then
        XCTAssertEqual(mainTab.id, mainTab.rawValue)
        XCTAssertEqual(dailyChallengesTab.id, dailyChallengesTab.rawValue)
        XCTAssertEqual(profileTab.id, profileTab.rawValue)

        // Verify uniqueness
        XCTAssertNotEqual(mainTab.id, dailyChallengesTab.id)
        XCTAssertNotEqual(dailyChallengesTab.id, profileTab.id)
        XCTAssertNotEqual(mainTab.id, profileTab.id)
    }

    /// Tests that tab titles are correct
    func testTabTitles() {
        // Then
        XCTAssertEqual(TabBarView.Tab.main.title, "Main")
        XCTAssertEqual(TabBarView.Tab.dailyChallenges.title, "Daily")
        XCTAssertEqual(TabBarView.Tab.profile.title, "Me")
    }

    /// Tests that tab icons are correct SF Symbol names
    func testTabIcons() {
        // Then
        XCTAssertEqual(TabBarView.Tab.main.icon, "house.fill")
        XCTAssertEqual(TabBarView.Tab.dailyChallenges.icon, "calendar")
        XCTAssertEqual(TabBarView.Tab.profile.icon, "person.fill")
    }

    // MARK: - State Preservation Tests

    /// Tests that Tab enum can be stored and retrieved with SceneStorage
    /// This verifies RawRepresentable conformance needed for @SceneStorage
    func testTabSceneStorageCompatibility() {
        // Given
        let originalTab = TabBarView.Tab.dailyChallenges

        // When - Simulate storage and retrieval via rawValue
        let storedValue = originalTab.rawValue
        let retrievedTab = TabBarView.Tab(rawValue: storedValue)

        // Then
        XCTAssertNotNil(retrievedTab)
        XCTAssertEqual(retrievedTab, originalTab)
    }

    /// Tests that all tabs can round-trip through raw value conversion
    func testTabRawValueRoundTrip() {
        // Given
        let tabs: [TabBarView.Tab] = [.main, .dailyChallenges, .profile]

        // When/Then
        for tab in tabs {
            let rawValue = tab.rawValue
            let reconstructedTab = TabBarView.Tab(rawValue: rawValue)

            XCTAssertNotNil(reconstructedTab, "Tab \(tab) should reconstruct from raw value")
            XCTAssertEqual(reconstructedTab, tab, "Reconstructed tab should equal original")
        }
    }

    /// Tests that invalid raw values return nil
    func testTabInvalidRawValue() {
        // Given
        let invalidRawValue = 999

        // When
        let tab = TabBarView.Tab(rawValue: invalidRawValue)

        // Then
        XCTAssertNil(tab, "Invalid raw value should return nil")
    }

    // MARK: - Architecture Tests

    /// Tests tab order matches expected navigation flow
    func testTabOrder() {
        // Given
        let tabs = TabBarView.Tab.allCases

        // Then - Verify tabs are in the expected order
        XCTAssertEqual(tabs[0], .main, "First tab should be Main")
        XCTAssertEqual(tabs[1], .dailyChallenges, "Second tab should be Daily Challenges")
        XCTAssertEqual(tabs[2], .profile, "Third tab should be Me/Profile")
    }
}
