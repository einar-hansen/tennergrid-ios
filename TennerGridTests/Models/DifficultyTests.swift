//
//  DifficultyTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

import SwiftUI
@testable import TennerGrid
import Testing

struct DifficultyTests {
    // MARK: - Raw Value Tests

    @Test func rawValues() {
        #expect(Difficulty.easy.rawValue == "easy")
        #expect(Difficulty.medium.rawValue == "medium")
        #expect(Difficulty.hard.rawValue == "hard")
        #expect(Difficulty.expert.rawValue == "expert")
        #expect(Difficulty.calculator.rawValue == "calculator")
    }

    // MARK: - Identifiable Tests

    @Test func identifiable() {
        #expect(Difficulty.easy.id == "easy")
        #expect(Difficulty.medium.id == "medium")
        #expect(Difficulty.hard.id == "hard")
        #expect(Difficulty.expert.id == "expert")
        #expect(Difficulty.calculator.id == "calculator")
    }

    // MARK: - Display Name Tests

    @Test func displayNames() {
        #expect(Difficulty.easy.displayName == "Easy")
        #expect(Difficulty.medium.displayName == "Medium")
        #expect(Difficulty.hard.displayName == "Hard")
        #expect(Difficulty.expert.displayName == "Expert")
        #expect(Difficulty.calculator.displayName == "Calculator")
    }

    // MARK: - Color Tests

    @Test func colors() {
        #expect(Difficulty.easy.color == .green)
        #expect(Difficulty.medium.color == .blue)
        #expect(Difficulty.hard.color == .orange)
        #expect(Difficulty.expert.color == .red)
        #expect(Difficulty.calculator.color == .purple)
    }

    // MARK: - Prefilled Percentage Tests

    @Test func prefilledPercentages() {
        #expect(Difficulty.easy.prefilledPercentage == 0.45)
        #expect(Difficulty.medium.prefilledPercentage == 0.35)
        #expect(Difficulty.hard.prefilledPercentage == 0.25)
        #expect(Difficulty.expert.prefilledPercentage == 0.15)
        #expect(Difficulty.calculator.prefilledPercentage == 0.05)
    }

    @Test func prefilledPercentagesAreDescending() {
        let difficulties = Difficulty.allCases.dropLast() // Exclude calculator
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
        #expect(Difficulty.expert.estimatedMinutes == 35)
        #expect(Difficulty.calculator.estimatedMinutes == 60)
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
            #expect(difficulty.description.count > 10) // Should be a meaningful description
        }
    }

    @Test func descriptions() {
        #expect(Difficulty.easy.description.contains("beginner"))
        #expect(Difficulty.medium.description.contains("balanced"))
        #expect(Difficulty.hard.description.contains("logical"))
        #expect(Difficulty.expert.description.contains("challenging"))
        #expect(Difficulty.calculator.description.contains("ultimate"))
    }

    // MARK: - Points Tests

    @Test func testPoints() {
        #expect(Difficulty.easy.points == 10)
        #expect(Difficulty.medium.points == 25)
        #expect(Difficulty.hard.points == 50)
        #expect(Difficulty.expert.points == 100)
        #expect(Difficulty.calculator.points == 200)
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
        #expect(Difficulty.allCases.count == 5)
    }

    @Test func allCasesOrder() {
        let cases = Array(Difficulty.allCases)
        #expect(cases[0] == .easy)
        #expect(cases[1] == .medium)
        #expect(cases[2] == .hard)
        #expect(cases[3] == .expert)
        #expect(cases[4] == .calculator)
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        let encoder = JSONEncoder()

        let easyData = try encoder.encode(Difficulty.easy)
        let easyString = String(data: easyData, encoding: .utf8)
        #expect(easyString == "\"easy\"")

        let expertData = try encoder.encode(Difficulty.expert)
        let expertString = String(data: expertData, encoding: .utf8)
        #expect(expertString == "\"expert\"")
    }

    @Test func codableDecoding() throws {
        let decoder = JSONDecoder()

        let easyData = "\"easy\"".data(using: .utf8)!
        let easy = try decoder.decode(Difficulty.self, from: easyData)
        #expect(easy == .easy)

        let calculatorData = "\"calculator\"".data(using: .utf8)!
        let calculator = try decoder.decode(Difficulty.self, from: calculatorData)
        #expect(calculator == .calculator)
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

            #expect(easier.prefilledPercentage > harder.prefilledPercentage,
                    "\(easier.displayName) should have more prefilled cells than \(harder.displayName)")
            #expect(easier.estimatedMinutes < harder.estimatedMinutes,
                    "\(easier.displayName) should take less time than \(harder.displayName)")
            #expect(easier.points < harder.points,
                    "\(easier.displayName) should award fewer points than \(harder.displayName)")
        }
    }
}
