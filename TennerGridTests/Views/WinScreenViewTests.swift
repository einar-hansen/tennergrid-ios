import SwiftUI
import XCTest
@testable import TennerGrid

/// Tests for WinScreenView to ensure proper rendering and interaction
final class WinScreenViewTests: XCTestCase {
    // MARK: - View Instantiation Tests

    /// Tests that win screen can be created with easy difficulty
    func testWinScreenCreationWithEasyDifficulty() {
        // Given
        let difficulty = Difficulty.easy
        let elapsedTime: TimeInterval = 120 // 2 minutes
        let hintsUsed = 0
        let errorCount = 0

        // When
        let view = WinScreenView(
            difficulty: difficulty,
            elapsedTime: elapsedTime,
            hintsUsed: hintsUsed,
            errorCount: errorCount,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.difficulty, .easy)
        XCTAssertEqual(view.elapsedTime, 120)
        XCTAssertEqual(view.hintsUsed, 0)
        XCTAssertEqual(view.errorCount, 0)
    }

    /// Tests that win screen can be created with medium difficulty
    func testWinScreenCreationWithMediumDifficulty() {
        // Given
        let difficulty = Difficulty.medium
        let elapsedTime: TimeInterval = 300 // 5 minutes
        let hintsUsed = 3
        let errorCount = 1

        // When
        let view = WinScreenView(
            difficulty: difficulty,
            elapsedTime: elapsedTime,
            hintsUsed: hintsUsed,
            errorCount: errorCount,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.difficulty, .medium)
        XCTAssertEqual(view.elapsedTime, 300)
        XCTAssertEqual(view.hintsUsed, 3)
        XCTAssertEqual(view.errorCount, 1)
    }

    /// Tests that win screen can be created with hard difficulty
    func testWinScreenCreationWithHardDifficulty() {
        // Given
        let difficulty = Difficulty.hard
        let elapsedTime: TimeInterval = 600 // 10 minutes
        let hintsUsed = 5
        let errorCount = 3

        // When
        let view = WinScreenView(
            difficulty: difficulty,
            elapsedTime: elapsedTime,
            hintsUsed: hintsUsed,
            errorCount: errorCount,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.difficulty, .hard)
        XCTAssertEqual(view.elapsedTime, 600)
        XCTAssertEqual(view.hintsUsed, 5)
        XCTAssertEqual(view.errorCount, 3)
    }

    /// Tests that win screen can be created with all difficulty levels
    func testWinScreenCreationWithAllDifficulties() {
        // Given/When/Then - Easy
        let easyView = WinScreenView(
            difficulty: .easy,
            elapsedTime: 120,
            hintsUsed: 0,
            errorCount: 0,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )
        XCTAssertNotNil(easyView)
        XCTAssertEqual(easyView.difficulty, .easy)

        // Medium
        let mediumView = WinScreenView(
            difficulty: .medium,
            elapsedTime: 300,
            hintsUsed: 2,
            errorCount: 1,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )
        XCTAssertNotNil(mediumView)
        XCTAssertEqual(mediumView.difficulty, .medium)

        // Hard
        let hardView = WinScreenView(
            difficulty: .hard,
            elapsedTime: 600,
            hintsUsed: 5,
            errorCount: 3,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )
        XCTAssertNotNil(hardView)
        XCTAssertEqual(hardView.difficulty, .hard)
    }

    // MARK: - Callback Tests

    /// Tests that new game callback is triggered
    func testNewGameCallbackTriggered() {
        // Given
        let expectation = expectation(description: "New game callback triggered")
        var callbackTriggered = false

        let view = WinScreenView(
            difficulty: .easy,
            elapsedTime: 120,
            hintsUsed: 0,
            errorCount: 0,
            onNewGame: {
                callbackTriggered = true
                expectation.fulfill()
            },
            onChangeDifficulty: {},
            onHome: {}
        )

        // When
        view.onNewGame()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(callbackTriggered)
    }

    /// Tests that change difficulty callback is triggered
    func testChangeDifficultyCallbackTriggered() {
        // Given
        let expectation = expectation(description: "Change difficulty callback triggered")
        var callbackTriggered = false

        let view = WinScreenView(
            difficulty: .medium,
            elapsedTime: 300,
            hintsUsed: 2,
            errorCount: 1,
            onNewGame: {},
            onChangeDifficulty: {
                callbackTriggered = true
                expectation.fulfill()
            },
            onHome: {}
        )

        // When
        view.onChangeDifficulty()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(callbackTriggered)
    }

    /// Tests that home callback is triggered
    func testHomeCallbackTriggered() {
        // Given
        let expectation = expectation(description: "Home callback triggered")
        var callbackTriggered = false

        let view = WinScreenView(
            difficulty: .hard,
            elapsedTime: 600,
            hintsUsed: 5,
            errorCount: 3,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {
                callbackTriggered = true
                expectation.fulfill()
            }
        )

        // When
        view.onHome()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(callbackTriggered)
    }

    // MARK: - Edge Case Tests

    /// Tests win screen with no hints used
    func testWinScreenWithNoHintsUsed() {
        // Given/When
        let view = WinScreenView(
            difficulty: .hard,
            elapsedTime: 1200,
            hintsUsed: 0,
            errorCount: 0,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.hintsUsed, 0)
    }

    /// Tests win screen with many hints used
    func testWinScreenWithManyHintsUsed() {
        // Given/When
        let view = WinScreenView(
            difficulty: .easy,
            elapsedTime: 180,
            hintsUsed: 20,
            errorCount: 0,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.hintsUsed, 20)
    }

    /// Tests win screen with no errors
    func testWinScreenWithNoErrors() {
        // Given/When
        let view = WinScreenView(
            difficulty: .hard,
            elapsedTime: 500,
            hintsUsed: 3,
            errorCount: 0,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.errorCount, 0)
    }

    /// Tests win screen with many errors
    func testWinScreenWithManyErrors() {
        // Given/When
        let view = WinScreenView(
            difficulty: .medium,
            elapsedTime: 400,
            hintsUsed: 5,
            errorCount: 50,
            onNewGame: {},
            onChangeDifficulty: {},
            onHome: {}
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.errorCount, 50)
    }

    // MARK: - Multiple Callback Tests

    /// Tests that all callbacks can be triggered independently
    func testAllCallbacksCanBeTriggeredIndependently() {
        // Given
        var newGameCalled = false
        var changeDifficultyCalled = false
        var homeCalled = false

        let view = WinScreenView(
            difficulty: .medium,
            elapsedTime: 250,
            hintsUsed: 2,
            errorCount: 1,
            onNewGame: { newGameCalled = true },
            onChangeDifficulty: { changeDifficultyCalled = true },
            onHome: { homeCalled = true }
        )

        // When
        view.onNewGame()
        XCTAssertTrue(newGameCalled)
        XCTAssertFalse(changeDifficultyCalled)
        XCTAssertFalse(homeCalled)

        view.onChangeDifficulty()
        XCTAssertTrue(changeDifficultyCalled)
        XCTAssertFalse(homeCalled)

        view.onHome()
        XCTAssertTrue(homeCalled)
    }

    // MARK: - Performance Tests

    /// Tests that win screen creation is performant
    func testWinScreenCreationPerformance() {
        measure {
            for _ in 0 ..< 100 {
                _ = WinScreenView(
                    difficulty: .medium,
                    elapsedTime: 300,
                    hintsUsed: 3,
                    errorCount: 2,
                    onNewGame: {},
                    onChangeDifficulty: {},
                    onHome: {}
                )
            }
        }
    }
}
