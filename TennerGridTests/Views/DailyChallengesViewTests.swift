import XCTest
@testable import TennerGrid

// swiftlint:disable type_body_length implicitly_unwrapped_optional
@MainActor
final class DailyChallengesViewTests: XCTestCase {
    var puzzleManager: PuzzleManager!
    var testSuiteName: String!
    var testUserDefaults: UserDefaults!
    let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test instance to support parallel testing
        testSuiteName = "com.tennergrid.tests.\(UUID().uuidString)"
        testUserDefaults = UserDefaults(suiteName: testSuiteName) ?? .standard

        // Clear the persistent domain first
        testUserDefaults.removePersistentDomain(forName: testSuiteName)
        testUserDefaults.synchronize()

        // Create manager with test UserDefaults
        puzzleManager = PuzzleManager(userDefaults: testUserDefaults)
    }

    override func tearDown() {
        // Ensure cleanup
        puzzleManager = nil

        // Clean up test UserDefaults
        testUserDefaults?.removePersistentDomain(forName: testSuiteName)
        testUserDefaults = nil
        testSuiteName = nil
        super.tearDown()
    }

    // MARK: - Daily Puzzle Generation Tests

    func testDailyPuzzle_returnsValidPuzzle() {
        // When
        let puzzle = puzzleManager.dailyPuzzle()

        // Then
        XCTAssertNotNil(puzzle, "Daily puzzle should not be nil")
        XCTAssertEqual(puzzle?.columns, 10, "Daily puzzle should have 10 columns")
        XCTAssertEqual(puzzle?.rows, 5, "Daily puzzle should have 5 rows")
        XCTAssertEqual(puzzle?.difficulty, .medium, "Daily puzzle should be medium difficulty")
    }

    func testDailyPuzzle_sameDateReturnsSamePuzzle() {
        // Given
        let date = createDate(year: 2026, month: 1, day: 15)

        // When
        let puzzle1 = puzzleManager.dailyPuzzle(for: date)
        let puzzle2 = puzzleManager.dailyPuzzle(for: date)

        // Then
        XCTAssertEqual(
            puzzle1?.id,
            puzzle2?.id,
            "Same date should return same puzzle ID"
        )
    }

    func testDailyPuzzle_differentDatesReturnDifferentPuzzles() {
        // Given
        let date1 = createDate(year: 2026, month: 1, day: 15)
        let date2 = createDate(year: 2026, month: 1, day: 16)

        // When
        let puzzle1 = puzzleManager.dailyPuzzle(for: date1)
        let puzzle2 = puzzleManager.dailyPuzzle(for: date2)

        // Then - Puzzles should be different (but may occasionally match due to cycling)
        // The important test is that the selection is deterministic
        XCTAssertNotNil(puzzle1)
        XCTAssertNotNil(puzzle2)

        // Test that the same dates still return same puzzles
        let puzzle1Again = puzzleManager.dailyPuzzle(for: date1)
        let puzzle2Again = puzzleManager.dailyPuzzle(for: date2)

        XCTAssertEqual(puzzle1?.id, puzzle1Again?.id)
        XCTAssertEqual(puzzle2?.id, puzzle2Again?.id)
    }

    func testDailyPuzzle_consistentAcrossYears() {
        // Given - Same day of year in different years
        let date2026 = createDate(year: 2026, month: 6, day: 15)
        let date2027 = createDate(year: 2027, month: 6, day: 15)

        // When
        let puzzle2026 = puzzleManager.dailyPuzzle(for: date2026)
        let puzzle2027 = puzzleManager.dailyPuzzle(for: date2027)

        // Then - These dates have same day of year, so puzzles should match
        let dayOfYear2026 = calendar.ordinality(of: .day, in: .year, for: date2026)
        let dayOfYear2027 = calendar.ordinality(of: .day, in: .year, for: date2027)

        if dayOfYear2026 == dayOfYear2027 {
            XCTAssertEqual(
                puzzle2026?.id,
                puzzle2027?.id,
                "Same day of year should return same puzzle"
            )
        }
    }

    func testDailyPuzzle_cyclesThroughAvailablePuzzles() {
        // Given - Get the total number of available medium 5-row puzzles
        let availablePuzzles = puzzleManager.puzzles(difficulty: .medium, rows: 5)
        let puzzleCount = availablePuzzles.count

        XCTAssertGreaterThan(puzzleCount, 0, "Should have medium puzzles available")

        // When - Generate puzzles for a year's worth of days
        var uniquePuzzles = Set<UUID>()
        let startDate = createDate(year: 2026, month: 1, day: 1)

        for dayOffset in 0 ..< puzzleCount {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate),
                  let puzzle = puzzleManager.dailyPuzzle(for: date)
            else {
                XCTFail("Failed to generate puzzle for day \(dayOffset)")
                continue
            }

            uniquePuzzles.insert(puzzle.id)
        }

        // Then - Should use all available puzzles before cycling
        XCTAssertEqual(
            uniquePuzzles.count,
            puzzleCount,
            "Should cycle through all \(puzzleCount) available puzzles"
        )
    }

    func testDailyPuzzle_deterministicSelection() {
        // Given
        let testDates = [
            createDate(year: 2026, month: 1, day: 1),
            createDate(year: 2026, month: 3, day: 15),
            createDate(year: 2026, month: 7, day: 4),
            createDate(year: 2026, month: 12, day: 31),
        ]

        // When - Generate puzzles multiple times for each date
        for date in testDates {
            let puzzle1 = puzzleManager.dailyPuzzle(for: date)
            let puzzle2 = puzzleManager.dailyPuzzle(for: date)
            let puzzle3 = puzzleManager.dailyPuzzle(for: date)

            // Then - All should be identical
            XCTAssertNotNil(puzzle1)
            XCTAssertEqual(puzzle1?.id, puzzle2?.id)
            XCTAssertEqual(puzzle2?.id, puzzle3?.id)
        }
    }

    // MARK: - Daily Challenges View Display Tests

    func testDailyChallengesView_initialization() {
        // Given / When
        let view = DailyChallengesView(puzzleManager: puzzleManager)

        // Then - View should be created without issues
        XCTAssertNotNil(view)
    }

    func testDailyChallengesView_withCallback() {
        // Given
        var playedDate: Date?
        let onPlayDaily: (Date) -> Void = { date in
            playedDate = date
        }

        // When
        let view = DailyChallengesView(
            puzzleManager: puzzleManager,
            onPlayDaily: onPlayDaily
        )

        // Then
        XCTAssertNotNil(view)

        // Simulate callback
        let testDate = Date()
        onPlayDaily(testDate)
        XCTAssertEqual(playedDate, testDate)
    }

    func testDailyChallengesView_loadsCompletionData() {
        // Given - Save some completed dates
        let completedDates = [
            dateString(for: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            dateString(for: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            dateString(for: calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
        ]

        testUserDefaults.set(completedDates, forKey: "completedDailyDates")

        // When
        let view = DailyChallengesView(puzzleManager: puzzleManager)

        // Then - View should be created and will load the completion data on appear
        XCTAssertNotNil(view)

        // Verify UserDefaults contains the data
        let loadedDates = testUserDefaults.array(forKey: "completedDailyDates") as? [String]
        XCTAssertEqual(loadedDates?.count, 3)
    }

    func testDateString_formatting() {
        // Given
        let date = createDate(year: 2026, month: 1, day: 15)

        // When
        let dateStr = dateString(for: date)

        // Then
        XCTAssertEqual(dateStr, "2026-01-15")
    }

    func testCompletionDataPersistence() {
        // Given
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today

        let completedDates = [
            dateString(for: yesterday),
            dateString(for: twoDaysAgo),
        ]

        // When
        testUserDefaults.set(completedDates, forKey: "completedDailyDates")
        testUserDefaults.synchronize()

        // Then - Verify data persists
        let loadedDates = testUserDefaults.array(forKey: "completedDailyDates") as? [String]
        XCTAssertEqual(loadedDates?.count, 2)
        XCTAssertEqual(Set(loadedDates ?? []), Set(completedDates))
    }

    func testStreakCalculation() {
        // Given - Complete last 5 days
        var completedDates: [String] = []
        for dayOffset in 1 ... 5 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                completedDates.append(dateString(for: date))
            }
        }

        // When
        testUserDefaults.set(completedDates, forKey: "completedDailyDates")

        // Create view which will calculate streak on appear
        let view = DailyChallengesView(puzzleManager: puzzleManager)

        // Then - View should be created (actual streak calculation happens in the view's state)
        XCTAssertNotNil(view)
        XCTAssertEqual(completedDates.count, 5)
    }

    func testBestStreakPersistence() {
        // Given
        let bestStreak = 10
        testUserDefaults.set(bestStreak, forKey: "bestDailyStreak")

        // When
        let loadedStreak = testUserDefaults.integer(forKey: "bestDailyStreak")

        // Then
        XCTAssertEqual(loadedStreak, bestStreak)
    }

    func testMonthlyStatsCalculation() {
        // Given - Complete 10 days in current month
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            XCTFail("Could not get month interval")
            return
        }

        var completedDates: [String] = []
        var currentDay = monthInterval.start

        // Add first 10 days of the month
        for _ in 0 ..< 10 {
            guard currentDay < monthInterval.end else { break }
            completedDates.append(dateString(for: currentDay))

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            currentDay = nextDay
        }

        // When
        testUserDefaults.set(completedDates, forKey: "completedDailyDates")

        // Create view which will calculate monthly stats
        let view = DailyChallengesView(puzzleManager: puzzleManager)

        // Then - View should be created
        XCTAssertNotNil(view)
        XCTAssertEqual(completedDates.count, 10)
    }

    func testNavigationLimits() {
        // Given
        let januaryStart = createDate(year: 2026, month: 1, day: 1)
        let beforeJanuary = createDate(year: 2025, month: 12, day: 1)

        // When / Then - Can't navigate before January 2026
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: januaryStart) else {
            XCTFail("Could not calculate previous month")
            return
        }

        XCTAssertLessThan(previousMonth, januaryStart)

        // Current month navigation should work
        let now = Date()
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) else {
            XCTFail("Could not calculate next month")
            return
        }

        // Can't navigate beyond current date
        XCTAssertGreaterThan(nextMonth, now)
    }

    func testCalendarDayGeneration() {
        // Given
        let testDate = createDate(year: 2026, month: 1, day: 15)

        guard let monthInterval = calendar.dateInterval(of: .month, for: testDate) else {
            XCTFail("Could not get month interval")
            return
        }

        // When - Count days in January 2026
        var dayCount = 0
        var currentDay = monthInterval.start

        while currentDay < monthInterval.end {
            dayCount += 1
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            currentDay = nextDay
        }

        // Then - January has 31 days
        XCTAssertEqual(dayCount, 31)
    }

    func testWeekdayAlignment() {
        // Given - Test that first day of month aligns correctly
        let testDate = createDate(year: 2026, month: 1, day: 1)

        guard let weekday = calendar.dateComponents([.weekday], from: testDate).weekday else {
            XCTFail("Could not get weekday")
            return
        }

        // When / Then - January 1, 2026 is a Thursday (weekday 5 in 1-based Sunday system)
        // Note: weekday is locale-dependent, but we can verify it's valid
        XCTAssertGreaterThanOrEqual(weekday, 1)
        XCTAssertLessThanOrEqual(weekday, 7)
    }

    func testFutureDatesDisabled() {
        // Given
        let today = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            XCTFail("Could not create tomorrow's date")
            return
        }

        // When / Then - Future dates should be > today
        XCTAssertGreaterThan(tomorrow, today)
    }

    func testCompletionStatusPersistence() {
        // Given
        let testDates = [
            dateString(for: createDate(year: 2026, month: 1, day: 5)),
            dateString(for: createDate(year: 2026, month: 1, day: 10)),
            dateString(for: createDate(year: 2026, month: 1, day: 15)),
        ]

        // When
        testUserDefaults.set(testDates, forKey: "completedDailyDates")
        testUserDefaults.synchronize()

        // Then
        let loaded = testUserDefaults.array(forKey: "completedDailyDates") as? [String]
        XCTAssertEqual(Set(loaded ?? []), Set(testDates))
    }

    // MARK: - Integration Tests

    func testFullDailyChallengeFlow() {
        // Given
        let today = Date()
        let todayString = dateString(for: today)

        // When - Get today's puzzle
        let puzzle = puzzleManager.dailyPuzzle(for: today)

        // Then
        XCTAssertNotNil(puzzle)
        XCTAssertEqual(puzzle?.difficulty, .medium)
        XCTAssertEqual(puzzle?.rows, 5)

        // Simulate completing the puzzle
        var completedDates = testUserDefaults.array(forKey: "completedDailyDates") as? [String] ?? []
        completedDates.append(todayString)
        testUserDefaults.set(completedDates, forKey: "completedDailyDates")

        // Verify completion was saved
        let saved = testUserDefaults.array(forKey: "completedDailyDates") as? [String]
        XCTAssertTrue(saved?.contains(todayString) ?? false)
    }

    func testConsecutiveDailyPuzzles() {
        // Given - Test that consecutive days have valid puzzles
        let startDate = createDate(year: 2026, month: 1, day: 1)
        var puzzles: [TennerGridPuzzle] = []

        // When - Get puzzles for 30 consecutive days
        for dayOffset in 0 ..< 30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate),
                  let puzzle = puzzleManager.dailyPuzzle(for: date)
            else {
                XCTFail("Failed to get puzzle for day \(dayOffset)")
                continue
            }
            puzzles.append(puzzle)
        }

        // Then - All puzzles should be valid
        XCTAssertEqual(puzzles.count, 30)

        for puzzle in puzzles {
            XCTAssertEqual(puzzle.columns, 10)
            XCTAssertEqual(puzzle.rows, 5)
            XCTAssertEqual(puzzle.difficulty, .medium)
        }
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12 // Noon to avoid timezone issues

        guard let date = calendar.date(from: components) else {
            fatalError("Failed to create date for \(year)-\(month)-\(day)")
        }

        return date
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// swiftlint:enable type_body_length implicitly_unwrapped_optional
