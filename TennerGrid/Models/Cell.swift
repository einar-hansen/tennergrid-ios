//
//  Cell.swift
//  TennerGrid
//
//  Created by Claude on 2026-01-22.
//

import Foundation

/// Represents a single cell in the Tenner Grid puzzle
struct Cell: Equatable, Hashable, Codable {
    /// The position of this cell in the grid
    let position: CellPosition

    /// The current value in the cell (0-9), nil if empty
    var value: Int?

    /// Whether this cell was pre-filled in the initial puzzle
    let isInitial: Bool

    /// Pencil marks (possible values noted by the player)
    /// Set of integers from 0-9 that the player has marked as potential values
    var pencilMarks: Set<Int>

    /// Whether this cell is currently selected by the player
    var isSelected: Bool

    /// Whether this cell has an error (conflicts with game rules)
    var hasError: Bool

    /// Whether this cell should be highlighted (e.g., same value as selected cell)
    var isHighlighted: Bool

    /// Creates a new cell
    /// - Parameters:
    ///   - position: The position of the cell in the grid
    ///   - value: The current value (nil if empty)
    ///   - isInitial: Whether this is a pre-filled cell
    ///   - pencilMarks: Set of pencil marks (defaults to empty set)
    ///   - isSelected: Whether the cell is selected (defaults to false)
    ///   - hasError: Whether the cell has an error (defaults to false)
    ///   - isHighlighted: Whether the cell is highlighted (defaults to false)
    init(
        position: CellPosition,
        value: Int? = nil,
        isInitial: Bool = false,
        pencilMarks: Set<Int> = [],
        isSelected: Bool = false,
        hasError: Bool = false,
        isHighlighted: Bool = false
    ) {
        self.position = position
        self.value = value
        self.isInitial = isInitial
        self.pencilMarks = pencilMarks
        self.isSelected = isSelected
        self.hasError = hasError
        self.isHighlighted = isHighlighted
    }
}

// MARK: - Computed Properties

extension Cell {
    /// Whether the cell is empty (has no value)
    var isEmpty: Bool {
        value == nil
    }

    /// Whether the cell can be edited (not initial and not pre-filled)
    var isEditable: Bool {
        !isInitial
    }

    /// Whether the cell has any pencil marks
    var hasPencilMarks: Bool {
        !pencilMarks.isEmpty
    }
}

// MARK: - Modification Helpers

extension Cell {
    /// Creates a copy of this cell with a new value
    /// - Parameter newValue: The new value to set
    /// - Returns: A new Cell with the updated value
    func withValue(_ newValue: Int?) -> Cell {
        var cell = self
        cell.value = newValue
        // Clear pencil marks when a value is set
        if newValue != nil {
            cell.pencilMarks = []
        }
        return cell
    }

    /// Creates a copy of this cell with updated pencil marks
    /// - Parameter marks: The new pencil marks
    /// - Returns: A new Cell with the updated pencil marks
    func withPencilMarks(_ marks: Set<Int>) -> Cell {
        var cell = self
        cell.pencilMarks = marks
        return cell
    }

    /// Creates a copy of this cell with a pencil mark toggled
    /// - Parameter mark: The pencil mark to toggle (0-9)
    /// - Returns: A new Cell with the toggled pencil mark
    func togglePencilMark(_ mark: Int) -> Cell {
        guard mark >= 0, mark <= 9 else { return self }
        var cell = self
        if cell.pencilMarks.contains(mark) {
            cell.pencilMarks.remove(mark)
        } else {
            cell.pencilMarks.insert(mark)
        }
        return cell
    }

    /// Creates a copy of this cell with selection state updated
    /// - Parameter selected: Whether the cell should be selected
    /// - Returns: A new Cell with updated selection state
    func withSelection(_ selected: Bool) -> Cell {
        var cell = self
        cell.isSelected = selected
        return cell
    }

    /// Creates a copy of this cell with error state updated
    /// - Parameter error: Whether the cell has an error
    /// - Returns: A new Cell with updated error state
    func withError(_ error: Bool) -> Cell {
        var cell = self
        cell.hasError = error
        return cell
    }

    /// Creates a copy of this cell with highlight state updated
    /// - Parameter highlighted: Whether the cell should be highlighted
    /// - Returns: A new Cell with updated highlight state
    func withHighlight(_ highlighted: Bool) -> Cell {
        var cell = self
        cell.isHighlighted = highlighted
        return cell
    }

    /// Clears the cell's value and pencil marks
    /// - Returns: A new Cell with value and pencil marks cleared
    func cleared() -> Cell {
        guard isEditable else { return self }
        var cell = self
        cell.value = nil
        cell.pencilMarks = []
        return cell
    }
}

// MARK: - Factory Methods

extension Cell {
    /// Creates an empty cell at the specified position
    /// - Parameter position: The position of the cell
    /// - Returns: A new empty Cell
    static func empty(at position: CellPosition) -> Cell {
        Cell(position: position)
    }

    /// Creates a pre-filled initial cell
    /// - Parameters:
    ///   - position: The position of the cell
    ///   - value: The pre-filled value
    /// - Returns: A new initial Cell
    static func initial(at position: CellPosition, value: Int) -> Cell {
        Cell(position: position, value: value, isInitial: true)
    }
}

// MARK: - CustomStringConvertible

extension Cell: CustomStringConvertible {
    var description: String {
        let valueStr = value.map { String($0) } ?? "_"
        let flags = [
            isInitial ? "I" : nil,
            isSelected ? "S" : nil,
            hasError ? "E" : nil,
            isHighlighted ? "H" : nil,
        ].compactMap { $0 }.joined(separator: ",")

        let flagsStr = flags.isEmpty ? "" : " [\(flags)]"
        let marksStr = hasPencilMarks ? " marks:\(Array(pencilMarks).sorted())" : ""

        return "Cell(\(position): \(valueStr)\(flagsStr)\(marksStr))"
    }
}
