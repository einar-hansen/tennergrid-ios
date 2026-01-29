import Foundation

/// Static puzzles for SwiftUI previews
enum PreviewPuzzles {
    // MARK: - Easy Puzzles

    /// Easy 10x3 puzzle for small preview
    static let easy3Row: TennerGridPuzzle = .init(
        columns: 10,
        rows: 3,
        difficulty: .easy,
        targetSums: [12, 15, 13, 14, 16, 11, 17, 10, 18, 9],
        initialGrid: [
            [0, 1, nil, 3, nil, 5, nil, 7, nil, 9],
            [nil, 2, 3, nil, 5, nil, 7, nil, 9, nil],
            [2, nil, 4, nil, 6, nil, 8, nil, 0, nil],
        ],
        solution: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [4, 2, 3, 5, 5, 1, 7, 0, 9, 0],
            [8, 2, 8, 6, 7, 5, 4, 3, 1, 0],
        ]
    )

    /// Easy 10x5 puzzle (standard size)
    static let easy5Row: TennerGridPuzzle = .init(
        columns: 10,
        rows: 5,
        difficulty: .easy,
        targetSums: [20, 25, 22, 28, 18, 30, 15, 27, 23, 17],
        initialGrid: [
            [0, 1, nil, 3, nil, 5, nil, 7, nil, 9],
            [nil, 2, 3, nil, 5, nil, 7, nil, 9, nil],
            [2, nil, 4, nil, 6, nil, 8, nil, 0, nil],
            [nil, 3, nil, 5, nil, 7, nil, 9, nil, 1],
            [4, nil, 6, nil, 8, nil, 0, nil, 2, nil],
        ],
        solution: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [4, 2, 3, 5, 5, 6, 7, 8, 9, 0],
            [2, 9, 4, 8, 6, 3, 8, 1, 0, 5],
            [6, 3, 7, 5, 1, 7, 0, 9, 4, 1],
            [8, 0, 6, 7, 2, 9, 1, 2, 2, 2],
        ]
    )

    // MARK: - Medium Puzzles

    /// Medium 10x4 puzzle
    static let medium4Row: TennerGridPuzzle = .init(
        columns: 10,
        rows: 4,
        difficulty: .medium,
        targetSums: [18, 20, 16, 22, 14, 24, 12, 26, 10, 28],
        initialGrid: [
            [0, nil, nil, nil, nil, 5, nil, nil, nil, 9],
            [nil, nil, 3, nil, nil, nil, nil, 8, nil, nil],
            [nil, 4, nil, nil, 6, nil, nil, nil, 0, nil],
            [nil, nil, nil, 7, nil, nil, 1, nil, nil, nil],
        ],
        solution: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [9, 8, 3, 7, 2, 6, 1, 8, 0, 5],
            [3, 4, 5, 6, 6, 4, 3, 2, 0, 7],
            [6, 7, 6, 6, 2, 9, 2, 9, 2, 7],
        ]
    )

    /// Medium 10x5 puzzle (standard size)
    static let medium5Row: TennerGridPuzzle = .init(
        columns: 10,
        rows: 5,
        difficulty: .medium,
        targetSums: [22, 27, 24, 30, 20, 32, 18, 29, 25, 23],
        initialGrid: [
            [nil, 1, nil, nil, nil, 5, nil, nil, nil, nil],
            [nil, nil, nil, nil, 5, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, 3],
        ],
        solution: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 0],
            [8, 9, 0, 1, 2, 3, 4, 5, 6, 7],
            [4, 7, 2, 6, 4, 4, 8, 7, 1, 7],
        ]
    )

    // MARK: - Hard Puzzles

    /// Hard 10x5 puzzle
    static let hard5Row: TennerGridPuzzle = .init(
        columns: 10,
        rows: 5,
        difficulty: .hard,
        targetSums: [24, 29, 26, 32, 22, 34, 20, 31, 27, 25],
        initialGrid: [
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, 3],
        ],
        solution: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 0],
            [8, 9, 0, 1, 2, 3, 4, 5, 6, 7],
            [6, 9, 4, 8, 6, 6, 0, 9, 3, 6],
        ]
    )

    /// Hard 10x6 puzzle (larger)
    static let hard6Row: TennerGridPuzzle = .init(
        columns: 10,
        rows: 6,
        difficulty: .hard,
        targetSums: [30, 35, 32, 38, 28, 40, 26, 37, 33, 31],
        initialGrid: [
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ],
        solution: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 0],
            [8, 9, 0, 1, 2, 3, 4, 5, 6, 7],
            [5, 6, 7, 8, 9, 0, 1, 2, 3, 4],
            [7, 9, 3, 6, 3, 2, 5, 3, 6, 1],
        ]
    )

    /// Hard 10x7 puzzle (maximum size)
    static let hard7Row: TennerGridPuzzle = .init(
        columns: 10,
        rows: 7,
        difficulty: .hard,
        targetSums: [35, 40, 37, 43, 33, 45, 31, 42, 38, 36],
        initialGrid: [
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ],
        solution: [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 0],
            [8, 9, 0, 1, 2, 3, 4, 5, 6, 7],
            [5, 6, 7, 8, 9, 0, 1, 2, 3, 4],
            [7, 9, 3, 6, 3, 2, 5, 3, 6, 1],
            [5, 5, 5, 5, 5, 5, 5, 5, 5, 5],
        ]
    )

    // MARK: - Convenience Accessors

    /// Default puzzle for previews (easy 5-row)
    static var `default`: TennerGridPuzzle {
        easy5Row
    }

    /// Small puzzle for compact previews
    static var small: TennerGridPuzzle {
        easy3Row
    }

    /// Large puzzle for testing layouts
    static var large: TennerGridPuzzle {
        hard7Row
    }
}
