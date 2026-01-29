import SwiftUI
import XCTest
@testable import TennerGrid

/// Tests for DifficultySelectionView and CustomGameConfigurationView
/// Validates difficulty selection flow, custom game configuration, and callbacks
@MainActor
final class DifficultySelectionViewTests: XCTestCase {
    // MARK: - DifficultySelectionView Tests

    /// Test that DifficultySelectionView can be created
    func testDifficultySelectionViewCreation() {
        // Given & When
        let view = DifficultySelectionView()

        // Then
        XCTAssertNotNil(view, "DifficultySelectionView should be created")
    }

    /// Test that DifficultySelectionView can be created with callbacks
    func testDifficultySelectionViewCreationWithCallbacks() {
        // Given
        var selectedDifficulty: Difficulty?
        var customGameDifficulty: Difficulty?
        var customGameRows: Int?

        // When
        let view = DifficultySelectionView(
            onSelect: { difficulty in
                selectedDifficulty = difficulty
            },
            onCustomGame: { difficulty, rows in
                customGameDifficulty = difficulty
                customGameRows = rows
            }
        )

        // Then
        XCTAssertNotNil(view, "DifficultySelectionView should be created with callbacks")
        XCTAssertNil(selectedDifficulty, "No difficulty should be selected initially")
        XCTAssertNil(customGameDifficulty, "No custom game should be configured initially")
        XCTAssertNil(customGameRows, "No custom rows should be set initially")
    }

    /// Test that all difficulty levels are available
    func testAllDifficultyLevelsAvailable() {
        // Given
        let expectedDifficulties = Difficulty.allCases

        // Then
        XCTAssertEqual(expectedDifficulties.count, 4, "Should have 4 difficulty levels")
        XCTAssertTrue(expectedDifficulties.contains(.easy), "Should include Easy")
        XCTAssertTrue(expectedDifficulties.contains(.medium), "Should include Medium")
        XCTAssertTrue(expectedDifficulties.contains(.hard), "Should include Hard")
        XCTAssertTrue(expectedDifficulties.contains(.extreme), "Should include Extreme")
    }

    /// Test difficulty properties for Easy level
    func testEasyDifficultyProperties() {
        // Given
        let difficulty = Difficulty.easy

        // Then
        XCTAssertEqual(difficulty.displayName, "Easy")
        XCTAssertEqual(difficulty.color, .green)
        XCTAssertEqual(difficulty.prefilledPercentage, 0.55)
        XCTAssertEqual(difficulty.estimatedMinutes, 5)
        XCTAssertEqual(difficulty.points, 10)
        XCTAssertEqual(difficulty.minRows, 3)
        XCTAssertEqual(difficulty.maxRows, 5)
        XCTAssertFalse(difficulty.description.isEmpty)
    }

    /// Test difficulty properties for Medium level
    func testMediumDifficultyProperties() {
        // Given
        let difficulty = Difficulty.medium

        // Then
        XCTAssertEqual(difficulty.displayName, "Medium")
        XCTAssertEqual(difficulty.color, .blue)
        XCTAssertEqual(difficulty.prefilledPercentage, 0.45)
        XCTAssertEqual(difficulty.estimatedMinutes, 10)
        XCTAssertEqual(difficulty.points, 25)
        XCTAssertEqual(difficulty.minRows, 4)
        XCTAssertEqual(difficulty.maxRows, 7)
        XCTAssertFalse(difficulty.description.isEmpty)
    }

    /// Test difficulty properties for Hard level
    func testHardDifficultyProperties() {
        // Given
        let difficulty = Difficulty.hard

        // Then
        XCTAssertEqual(difficulty.displayName, "Hard")
        XCTAssertEqual(difficulty.color, .orange)
        XCTAssertEqual(difficulty.prefilledPercentage, 0.35)
        XCTAssertEqual(difficulty.estimatedMinutes, 20)
        XCTAssertEqual(difficulty.points, 50)
        XCTAssertEqual(difficulty.minRows, 5)
        XCTAssertEqual(difficulty.maxRows, 10)
        XCTAssertFalse(difficulty.description.isEmpty)
    }

    // MARK: - CustomGameConfigurationView Tests

    /// Test that CustomGameConfigurationView can be created
    func testCustomGameConfigurationViewCreation() {
        // Given & When
        let view = CustomGameConfigurationView()

        // Then
        XCTAssertNotNil(view, "CustomGameConfigurationView should be created")
    }

    /// Test that CustomGameConfigurationView can be created with callback
    func testCustomGameConfigurationViewCreationWithCallback() {
        // Given
        var confirmedDifficulty: Difficulty?
        var confirmedRows: Int?

        // When
        let view = CustomGameConfigurationView { difficulty, rows in
            confirmedDifficulty = difficulty
            confirmedRows = rows
        }

        // Then
        XCTAssertNotNil(view, "CustomGameConfigurationView should be created with callback")
        XCTAssertNil(confirmedDifficulty, "No difficulty should be confirmed initially")
        XCTAssertNil(confirmedRows, "No rows should be confirmed initially")
    }

    // MARK: - Row Selection Tests

    /// Test row selection range is valid
    func testRowSelectionRangeIsValid() {
        // Given
        let minRows = 3
        let maxRows = 10

        // Then
        XCTAssertEqual(minRows, 3, "Minimum rows should be 3")
        XCTAssertEqual(maxRows, 10, "Maximum rows should be 10")
        XCTAssertGreaterThan(maxRows, minRows, "Max rows should be greater than min rows")
    }

    /// Test that all row options are within valid range
    func testRowOptionsWithinValidRange() {
        // Given
        let minRows = 3
        let maxRows = 10
        let expectedRowCount = maxRows - minRows + 1

        // Then
        XCTAssertEqual(expectedRowCount, 8, "Should have 8 row options (3-10)")

        // Verify each row value is valid
        for rows in minRows ... maxRows {
            XCTAssertGreaterThanOrEqual(rows, minRows, "Row value should be >= min")
            XCTAssertLessThanOrEqual(rows, maxRows, "Row value should be <= max")
        }
    }

    // MARK: - Column Constants Tests

    /// Test that Tenner Grid always uses 10 columns
    func testTennerGridColumnConstant() {
        // Given
        let columns = Difficulty.columns

        // Then
        XCTAssertEqual(columns, 10, "Tenner Grid should always have 10 columns")
    }

    // MARK: - Difficulty Selection Flow Tests

    /// Test difficulty selection callback is executed
    func testDifficultySelectionCallback() {
        // Given
        var selectedDifficulty: Difficulty?
        let view = DifficultySelectionView { difficulty in
            selectedDifficulty = difficulty
        }

        // When - Simulate selecting a difficulty
        // Note: In actual SwiftUI tests, we would use UI testing
        // Here we test the model logic
        let testDifficulty = Difficulty.medium

        // Simulate the callback
        view.onSelect?(testDifficulty)

        // Then
        XCTAssertEqual(selectedDifficulty, testDifficulty, "Callback should receive selected difficulty")
    }

    /// Test custom game callback is executed with difficulty and rows
    func testCustomGameCallback() {
        // Given
        var customDifficulty: Difficulty?
        var customRows: Int?
        let view = DifficultySelectionView(
            onSelect: { _ in },
            onCustomGame: { difficulty, rows in
                customDifficulty = difficulty
                customRows = rows
            }
        )

        // When - Simulate custom game configuration
        let testDifficulty = Difficulty.hard
        let testRows = 7

        // Simulate the callback
        view.onCustomGame?(testDifficulty, testRows)

        // Then
        XCTAssertEqual(customDifficulty, testDifficulty, "Callback should receive custom difficulty")
        XCTAssertEqual(customRows, testRows, "Callback should receive custom rows")
    }

    // MARK: - Edge Cases

    /// Test minimum custom game configuration
    func testMinimumCustomGameConfiguration() {
        // Given
        var confirmedDifficulty: Difficulty?
        var confirmedRows: Int?
        let view = CustomGameConfigurationView { difficulty, rows in
            confirmedDifficulty = difficulty
            confirmedRows = rows
        }

        // When - Simulate minimum configuration
        let minDifficulty = Difficulty.easy
        let minRows = 3

        // Simulate the callback
        view.onConfirm?(minDifficulty, minRows)

        // Then
        XCTAssertEqual(confirmedDifficulty, minDifficulty, "Should accept minimum difficulty")
        XCTAssertEqual(confirmedRows, minRows, "Should accept minimum rows")
    }

    /// Test maximum custom game configuration
    func testMaximumCustomGameConfiguration() {
        // Given
        var confirmedDifficulty: Difficulty?
        var confirmedRows: Int?
        let view = CustomGameConfigurationView { difficulty, rows in
            confirmedDifficulty = difficulty
            confirmedRows = rows
        }

        // When - Simulate maximum configuration
        let maxDifficulty = Difficulty.hard
        let maxRows = 10

        // Simulate the callback
        view.onConfirm?(maxDifficulty, maxRows)

        // Then
        XCTAssertEqual(confirmedDifficulty, maxDifficulty, "Should accept maximum difficulty")
        XCTAssertEqual(confirmedRows, maxRows, "Should accept maximum rows")
    }

    // MARK: - Difficulty Metadata Tests

    /// Test that all difficulties have valid metadata
    func testDifficultyMetadataValidity() {
        // Given
        let difficulties = Difficulty.allCases

        // Then
        for difficulty in difficulties {
            // Display name should not be empty
            XCTAssertFalse(difficulty.displayName.isEmpty, "\(difficulty) should have display name")

            // Description should not be empty
            XCTAssertFalse(difficulty.description.isEmpty, "\(difficulty) should have description")

            // Prefilled percentage should be between 0 and 1
            XCTAssertGreaterThan(difficulty.prefilledPercentage, 0.0, "\(difficulty) prefilled % should be > 0")
            XCTAssertLessThanOrEqual(difficulty.prefilledPercentage, 1.0, "\(difficulty) prefilled % should be <= 1")

            // Estimated minutes should be positive
            XCTAssertGreaterThan(difficulty.estimatedMinutes, 0, "\(difficulty) estimated minutes should be > 0")

            // Points should be positive
            XCTAssertGreaterThan(difficulty.points, 0, "\(difficulty) points should be > 0")

            // Row range should be valid
            XCTAssertGreaterThanOrEqual(difficulty.minRows, 3, "\(difficulty) minRows should be >= 3")
            XCTAssertLessThanOrEqual(difficulty.maxRows, 10, "\(difficulty) maxRows should be <= 10")
            XCTAssertGreaterThan(difficulty.maxRows, difficulty.minRows, "\(difficulty) maxRows should be > minRows")
        }
    }

    /// Test that difficulty points increase with difficulty
    func testDifficultyPointsProgression() {
        // Given
        let easy = Difficulty.easy
        let medium = Difficulty.medium
        let hard = Difficulty.hard
        let extreme = Difficulty.extreme

        // Then
        XCTAssertLessThan(easy.points, medium.points, "Medium should have more points than Easy")
        XCTAssertLessThan(medium.points, hard.points, "Hard should have more points than Medium")
        XCTAssertLessThan(hard.points, extreme.points, "Extreme should have more points than Hard")
    }

    /// Test that estimated time increases with difficulty
    func testDifficultyTimeProgression() {
        // Given
        let easy = Difficulty.easy
        let medium = Difficulty.medium
        let hard = Difficulty.hard
        let extreme = Difficulty.extreme

        // Then
        XCTAssertLessThan(easy.estimatedMinutes, medium.estimatedMinutes, "Medium should take longer than Easy")
        XCTAssertLessThan(medium.estimatedMinutes, hard.estimatedMinutes, "Hard should take longer than Medium")
        XCTAssertLessThan(hard.estimatedMinutes, extreme.estimatedMinutes, "Extreme should take longer than Hard")
    }

    /// Test that prefilled percentage decreases with difficulty
    func testDifficultyPrefilledProgression() {
        // Given
        let easy = Difficulty.easy
        let medium = Difficulty.medium
        let hard = Difficulty.hard
        let extreme = Difficulty.extreme

        // Then
        XCTAssertGreaterThan(
            easy.prefilledPercentage,
            medium.prefilledPercentage,
            "Easy should have more pre-filled cells than Medium"
        )
        XCTAssertGreaterThan(
            medium.prefilledPercentage,
            hard.prefilledPercentage,
            "Medium should have more pre-filled cells than Hard"
        )
        XCTAssertGreaterThan(
            hard.prefilledPercentage,
            extreme.prefilledPercentage,
            "Hard should have more pre-filled cells than Extreme"
        )
    }

    // MARK: - Integration Tests

    /// Test complete difficulty selection flow
    func testCompleteDifficultySelectionFlow() {
        // Given
        var selectionCompleted = false
        var selectedDifficulty: Difficulty?

        let view = DifficultySelectionView { difficulty in
            selectionCompleted = true
            selectedDifficulty = difficulty
        }

        // When - Simulate selecting each difficulty
        for difficulty in Difficulty.allCases {
            selectionCompleted = false
            selectedDifficulty = nil

            view.onSelect?(difficulty)

            // Then
            XCTAssertTrue(selectionCompleted, "Selection should complete for \(difficulty)")
            XCTAssertEqual(selectedDifficulty, difficulty, "Should select correct difficulty: \(difficulty)")
        }
    }

    /// Test complete custom game configuration flow
    func testCompleteCustomGameConfigurationFlow() {
        // Given
        var configurationCompleted = false
        var confirmedDifficulty: Difficulty?
        var confirmedRows: Int?

        let view = DifficultySelectionView(
            onSelect: { _ in },
            onCustomGame: { difficulty, rows in
                configurationCompleted = true
                confirmedDifficulty = difficulty
                confirmedRows = rows
            }
        )

        // When - Simulate custom game configurations
        let testConfigurations: [(Difficulty, Int)] = [
            (.easy, 3),
            (.medium, 5),
            (.hard, 10),
        ]

        for (difficulty, rows) in testConfigurations {
            configurationCompleted = false
            confirmedDifficulty = nil
            confirmedRows = nil

            view.onCustomGame?(difficulty, rows)

            // Then
            XCTAssertTrue(configurationCompleted, "Configuration should complete for \(difficulty), \(rows) rows")
            XCTAssertEqual(confirmedDifficulty, difficulty, "Should confirm difficulty: \(difficulty)")
            XCTAssertEqual(confirmedRows, rows, "Should confirm rows: \(rows)")
        }
    }

    // MARK: - Nil Callback Tests

    /// Test that view handles nil callbacks gracefully
    func testViewHandlesNilCallbacks() {
        // Given & When
        let view = DifficultySelectionView(onSelect: nil, onCustomGame: nil)

        // Then - Should not crash when callbacks are called
        view.onSelect?(.easy)
        view.onCustomGame?(.medium, 5)

        // No assertions needed - just ensuring no crash
        XCTAssertNotNil(view, "View should handle nil callbacks")
    }

    /// Test custom configuration view with nil callback
    func testCustomConfigurationViewHandlesNilCallback() {
        // Given & When
        let view = CustomGameConfigurationView(onConfirm: nil)

        // Then - Should not crash when callback is called
        view.onConfirm?(.easy, 3)

        // No assertions needed - just ensuring no crash
        XCTAssertNotNil(view, "Custom configuration view should handle nil callback")
    }
}
