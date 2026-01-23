import Foundation
@testable import TennerGrid

/// Test fixtures providing pre-built puzzles for fast test execution
enum TestFixtures {
    // MARK: - Bundled Puzzle Access

    /// Loads puzzles from the bundled JSON file
    private static let bundledPuzzles: [APIPuzzle] = {
        // Try main bundle first (when running app), then test bundle
        let bundles = [Bundle.main, Bundle(for: BundleToken.self)]

        for bundle in bundles {
            if let url = bundle.url(forResource: "BundledPuzzles", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let response = try? JSONDecoder().decode(PuzzleResponse.self, from: data)
            {
                return response.data.flatMap { $0 }
            }
        }

        print("TestFixtures: Warning - BundledPuzzles.json not found, using static fixtures")
        return []
    }()

    /// Index for fast lookup by difficulty and rows
    private static let puzzleIndex: [String: [APIPuzzle]] = {
        var index: [String: [APIPuzzle]] = [:]
        for puzzle in bundledPuzzles {
            let key = "\(puzzle.difficulty)_\(puzzle.rows)"
            index[key, default: []].append(puzzle)
        }
        return index
    }()

    // MARK: - Quick Access Fixtures

    /// Easy 5x10 puzzle for general testing
    static var easyPuzzle: TennerGridPuzzle {
        firstPuzzle(difficulty: .easy, rows: 5) ?? staticEasyPuzzle
    }

    /// Medium 5x10 puzzle for testing
    static var mediumPuzzle: TennerGridPuzzle {
        firstPuzzle(difficulty: .medium, rows: 5) ?? staticMediumPuzzle
    }

    /// Hard 5x10 puzzle for testing
    static var hardPuzzle: TennerGridPuzzle {
        firstPuzzle(difficulty: .hard, rows: 5) ?? staticHardPuzzle
    }

    /// Small 3x10 puzzle for fast tests
    static var smallPuzzle: TennerGridPuzzle {
        firstPuzzle(difficulty: .easy, rows: 3) ?? staticEasyPuzzle
    }

    /// Large 7x10 puzzle for stress tests
    static var largePuzzle: TennerGridPuzzle {
        firstPuzzle(difficulty: .hard, rows: 7) ?? staticHardPuzzle
    }

    // MARK: - Puzzle Lookup

    /// Returns the first puzzle matching criteria
    static func firstPuzzle(difficulty: Difficulty, rows: Int) -> TennerGridPuzzle? {
        let key = "\(difficulty.rawValue)_\(rows)"
        return puzzleIndex[key]?.first?.toPuzzle()
    }

    /// Returns a random puzzle matching criteria
    static func randomPuzzle(difficulty: Difficulty, rows: Int) -> TennerGridPuzzle? {
        let key = "\(difficulty.rawValue)_\(rows)"
        return puzzleIndex[key]?.randomElement()?.toPuzzle()
    }

    /// Returns all puzzles matching criteria
    static func puzzles(difficulty: Difficulty, rows: Int) -> [TennerGridPuzzle] {
        let key = "\(difficulty.rawValue)_\(rows)"
        return puzzleIndex[key]?.map { $0.toPuzzle() } ?? []
    }

    /// Total number of bundled puzzles available
    static var bundledCount: Int {
        bundledPuzzles.count
    }

    // MARK: - Static Fallback Fixtures (10 columns as required by Tenner Grid)

    /// Static easy puzzle (fallback when bundle not available)
    private static let staticEasyPuzzle: TennerGridPuzzle = .init(
        columns: 10,
        rows: 3,
        difficulty: .easy,
        targetSums: [5, 20, 17, 4, 22, 15, 14, 12, 19, 7],
        initialGrid: [
            [2, nil, nil, 1, nil, 8, 5, nil, 6, nil],
            [nil, 9, nil, 2, 5, nil, nil, 7, nil, nil],
            [0, 4, 7, 1, nil, nil, 9, nil, nil, 6],
        ],
        solution: [
            [2, 7, 4, 1, 9, 8, 5, 3, 6, 0],
            [3, 9, 6, 2, 5, 4, 0, 7, 8, 1],
            [0, 4, 7, 1, 8, 3, 9, 2, 5, 6],
        ]
    )

    /// Static medium puzzle (fallback)
    private static let staticMediumPuzzle: TennerGridPuzzle = .init(
        columns: 10,
        rows: 5,
        difficulty: .medium,
        targetSums: [20, 25, 18, 22, 30, 20, 25, 18, 22, 25],
        initialGrid: [
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, 9, nil, nil, 5, nil, nil, 7, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, 3, nil, nil, 8, nil, nil, 2, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ],
        solution: [
            [2, 7, 4, 1, 9, 8, 5, 3, 6, 0],
            [3, 9, 6, 2, 5, 4, 0, 7, 8, 1],
            [0, 4, 7, 1, 8, 3, 9, 2, 5, 6],
            [6, 3, 0, 9, 8, 2, 4, 2, 1, 5],
            [9, 2, 1, 9, 0, 3, 7, 4, 2, 3],
        ]
    )

    /// Static hard puzzle (fallback)
    private static let staticHardPuzzle: TennerGridPuzzle = .init(
        columns: 10,
        rows: 5,
        difficulty: .hard,
        targetSums: [20, 25, 18, 22, 30, 20, 25, 18, 22, 25],
        initialGrid: [
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ],
        solution: [
            [2, 7, 4, 1, 9, 8, 5, 3, 6, 0],
            [3, 9, 6, 2, 5, 4, 0, 7, 8, 1],
            [0, 4, 7, 1, 8, 3, 9, 2, 5, 6],
            [6, 3, 0, 9, 8, 2, 4, 2, 1, 5],
            [9, 2, 1, 9, 0, 3, 7, 4, 2, 3],
        ]
    )

    // MARK: - Completed Grids (for validation tests - 10 columns)

    /// A valid completed 10x3 grid
    static let completedGrid10x3: [[Int]] = [
        [2, 7, 4, 1, 9, 8, 5, 3, 6, 0],
        [3, 9, 6, 2, 5, 4, 0, 7, 8, 1],
        [0, 4, 7, 1, 8, 3, 9, 2, 5, 6],
    ]

    /// Column sums for the completed 10x3 grid
    static let columnSums10x3 = [5, 20, 17, 4, 22, 15, 14, 12, 19, 7]

    /// A valid completed 10x5 grid
    static let completedGrid10x5: [[Int]] = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [9, 0, 1, 2, 3, 4, 5, 6, 7, 8],
        [8, 9, 0, 1, 2, 3, 4, 5, 6, 7],
        [7, 8, 9, 0, 1, 2, 3, 4, 5, 6],
        [6, 7, 8, 9, 0, 1, 2, 3, 4, 5],
    ]

    /// Column sums for the completed 10x5 grid
    static let columnSums10x5 = [30, 25, 20, 15, 10, 15, 20, 25, 30, 35]

    // MARK: - Invalid Test Cases (10 columns)

    /// Grid with adjacent duplicates (invalid)
    static let invalidGrid_adjacentDuplicates: [[Int]] = [
        [0, 0, 2, 3, 4, 5, 6, 7, 8, 9], // 0 appears twice adjacently
        [9, 1, 3, 2, 5, 4, 7, 6, 0, 8],
        [8, 9, 0, 1, 2, 3, 4, 5, 6, 7],
    ]

    /// Grid with row duplicates (invalid)
    static let invalidGrid_rowDuplicates: [[Int]] = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 0], // 0 appears twice in same row
        [9, 2, 1, 4, 3, 6, 5, 8, 7, 1],
        [8, 9, 0, 1, 2, 3, 4, 5, 6, 7],
    ]

    /// Empty 10x3 grid template
    static let emptyGrid10x3: [[Int?]] = Array(
        repeating: Array(repeating: nil, count: 10),
        count: 3
    )

    /// Empty 10x5 grid template
    static let emptyGrid10x5: [[Int?]] = Array(
        repeating: Array(repeating: nil, count: 10),
        count: 5
    )
}

// MARK: - Bundle Token

/// Token class to locate the test bundle
private class BundleToken {}
