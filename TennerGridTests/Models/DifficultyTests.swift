import Foundation
import SwiftUI
import Testing
@testable import TennerGrid

struct DifficultyTests {
    // MARK: - Raw Value Tests

    @Test func rawValues() {
        #expect(Difficulty.easy.rawValue == "easy")
        #expect(Difficulty.medium.rawValue == "medium")
        #expect(Difficulty.hard.rawValue == "hard")
    }

    // MARK: - Identifiable Tests

    @Test func identifiable() {
        #expect(Difficulty.easy.id == "easy")
        #expect(Difficulty.medium.id == "medium")
        #expect(Difficulty.hard.id == "hard")
    }

    // MARK: - Display Name Tests

    @Test func displayNames() {
        #expect(Difficulty.easy.displayName == "Easy")
        #expect(Difficulty.medium.displayName == "Medium")
        #expect(Difficulty.hard.displayName == "Hard")
    }

    // MARK: - Color Tests

    @Test func colors() {
        #expect(Difficulty.easy.color == .green)
        #expect(Difficulty.medium.color == .blue)
        #expect(Difficulty.hard.color == .orange)
    }

    // MARK: - Prefilled Percentage Tests

    @Test func prefilledPercentages() {
        #expect(Difficulty.easy.prefilledPercentage == 0.45)
        #expect(Difficulty.medium.prefilledPercentage == 0.35)
        #expect(Difficulty.hard.prefilledPercentage == 0.25)
    }

    @Test func prefilledPercentagesAreDescending() {
        let difficulties = Difficulty.allCases
        for i in 0 ..< (difficulties.count - 1) {
            let current = Array(difficulties)[i]
            let next = Array(difficulties)[i + 1]
            #expect(current.prefilledPercentage > next.prefilledPercentage)
        }
    }

    @Test func prefilledPercentagesAreValid() {
        for difficulty in Difficulty.allCases {
            #expect(difficulty.prefilledPercentage >= 0.0)
            #expect(difficulty.prefilledPercentage <= 1.0)
        }
    }

    // MARK: - Estimated Minutes Tests

    @Test func testEstimatedMinutes() {
        #expect(Difficulty.easy.estimatedMinutes == 5)
        #expect(Difficulty.medium.estimatedMinutes == 10)
        #expect(Difficulty.hard.estimatedMinutes == 20)
    }

    @Test func estimatedMinutesAreAscending() {
        let difficulties = Difficulty.allCases
        for i in 0 ..< (difficulties.count - 1) {
            let current = Array(difficulties)[i]
            let next = Array(difficulties)[i + 1]
            #expect(current.estimatedMinutes < next.estimatedMinutes)
        }
    }

    @Test func estimatedMinutesArePositive() {
        for difficulty in Difficulty.allCases {
            #expect(difficulty.estimatedMinutes > 0)
        }
    }

    // MARK: - Description Tests

    @Test func descriptionsAreNotEmpty() {
        for difficulty in Difficulty.allCases {
            #expect(!difficulty.description.isEmpty)
            #expect(difficulty.description.count > 10)
        }
    }

    @Test func descriptions() {
        #expect(Difficulty.easy.description.contains("beginner"))
        #expect(Difficulty.medium.description.contains("balanced"))
        #expect(Difficulty.hard.description.contains("logical"))
    }

    // MARK: - Points Tests

    @Test func testPoints() {
        #expect(Difficulty.easy.points == 10)
        #expect(Difficulty.medium.points == 25)
        #expect(Difficulty.hard.points == 50)
    }

    @Test func pointsAreAscending() {
        let difficulties = Difficulty.allCases
        for i in 0 ..< (difficulties.count - 1) {
            let current = Array(difficulties)[i]
            let next = Array(difficulties)[i + 1]
            #expect(current.points < next.points)
        }
    }

    @Test func pointsArePositive() {
        for difficulty in Difficulty.allCases {
            #expect(difficulty.points > 0)
        }
    }

    // MARK: - CaseIterable Tests

    @Test func allCasesCount() {
        #expect(Difficulty.allCases.count == 3)
    }

    @Test func allCasesOrder() {
        let cases = Array(Difficulty.allCases)
        #expect(cases[0] == .easy)
        #expect(cases[1] == .medium)
        #expect(cases[2] == .hard)
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        let encoder = JSONEncoder()

        let easyData = try encoder.encode(Difficulty.easy)
        let easyString = String(data: easyData, encoding: .utf8)
        #expect(easyString == "\"easy\"")

        let hardData = try encoder.encode(Difficulty.hard)
        let hardString = String(data: hardData, encoding: .utf8)
        #expect(hardString == "\"hard\"")
    }

    @Test func codableDecoding() throws {
        let decoder = JSONDecoder()

        let easyData = "\"easy\"".data(using: .utf8)!
        let easy = try decoder.decode(Difficulty.self, from: easyData)
        #expect(easy == .easy)

        let hardData = "\"hard\"".data(using: .utf8)!
        let hard = try decoder.decode(Difficulty.self, from: hardData)
        #expect(hard == .hard)
    }

    @Test func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for difficulty in Difficulty.allCases {
            let encoded = try encoder.encode(difficulty)
            let decoded = try decoder.decode(Difficulty.self, from: encoded)
            #expect(decoded == difficulty)
        }
    }

    // MARK: - Consistency Tests

    @Test func difficultyConsistency() {
        // Verify that harder difficulties have:
        // - Lower prefilled percentages
        // - Higher estimated times
        // - Higher points

        let difficulties = Difficulty.allCases

        for i in 0 ..< (difficulties.count - 1) {
            let easier = Array(difficulties)[i]
            let harder = Array(difficulties)[i + 1]

            #expect(
                easier.prefilledPercentage > harder.prefilledPercentage,
                "\(easier.displayName) should have more prefilled cells than \(harder.displayName)"
            )
            #expect(
                easier.estimatedMinutes < harder.estimatedMinutes,
                "\(easier.displayName) should take less time than \(harder.displayName)"
            )
            #expect(
                easier.points < harder.points,
                "\(easier.displayName) should award fewer points than \(harder.displayName)"
            )
        }
    }
}
