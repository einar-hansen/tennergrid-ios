import Foundation
import SwiftUI

/// Represents the difficulty levels available in Tenner Grid puzzles
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case extreme

    var id: String {
        rawValue
    }

    /// Display name for the difficulty level
    var displayName: String {
        switch self {
        case .easy:
            "Easy"
        case .medium:
            "Medium"
        case .hard:
            "Hard"
        case .extreme:
            "Extreme"
        }
    }

    /// Color associated with the difficulty level
    var color: Color {
        switch self {
        case .easy:
            .green
        case .medium:
            .blue
        case .hard:
            .orange
        case .extreme:
            .red
        }
    }

    /// Number of pre-filled cells as a percentage (0.0 to 1.0)
    var prefilledPercentage: Double {
        switch self {
        case .easy:
            0.55 // 55% of cells pre-filled
        case .medium:
            0.45 // 45% of cells pre-filled
        case .hard:
            0.35 // 35% of cells pre-filled
        case .extreme:
            0.25 // 25% of cells pre-filled
        }
    }

    /// Estimated time to complete puzzle in minutes
    var estimatedMinutes: Int {
        switch self {
        case .easy:
            5
        case .medium:
            10
        case .hard:
            20
        case .extreme:
            30
        }
    }

    /// Description of the difficulty level
    var description: String {
        switch self {
        case .easy:
            "Perfect for beginners. Plenty of clues to get you started."
        case .medium:
            "A balanced challenge with moderate pre-filled cells."
        case .hard:
            "Requires logical deduction and strategic thinking."
        case .extreme:
            "Only for experts. Very few clues and maximum challenge."
        }
    }

    /// Points awarded for completing a puzzle of this difficulty
    var points: Int {
        switch self {
        case .easy:
            10
        case .medium:
            25
        case .hard:
            50
        case .extreme:
            100
        }
    }

    /// Minimum number of rows for this difficulty
    var minRows: Int {
        switch self {
        case .easy:
            3
        case .medium:
            4
        case .hard:
            5
        case .extreme:
            6
        }
    }

    /// Maximum number of rows for this difficulty
    var maxRows: Int {
        switch self {
        case .easy:
            5
        case .medium:
            7
        case .hard:
            10
        case .extreme:
            10
        }
    }

    /// Number of columns (always 10 for Tenner Grid)
    /// This is a constant because the game rules require exactly 10 columns
    static let columns: Int = 10
}
