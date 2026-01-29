import Foundation
import Testing
@testable import TennerGrid

struct CellTests {
    // MARK: - Initialization Tests

    @Test func defaultInitialization() {
        let position = CellPosition(row: 1, column: 2)
        let cell = Cell(position: position)

        #expect(cell.position == position)
        #expect(cell.value == nil)
        #expect(cell.isInitial == false)
        #expect(cell.pencilMarks.isEmpty)
        #expect(cell.isSelected == false)
        #expect(cell.hasError == false)
        #expect(cell.isHighlighted == false)
        #expect(cell.isSameNumber == false)
        #expect(cell.isNeighbor == false)
    }

    @Test func fullInitialization() {
        let position = CellPosition(row: 2, column: 3)
        let marks: Set<Int> = [1, 2, 3]
        let cell = Cell(
            position: position,
            value: 5,
            isInitial: true,
            pencilMarks: marks,
            isSelected: true,
            hasError: true,
            isHighlighted: true,
            isSameNumber: true,
            isNeighbor: true
        )

        #expect(cell.position == position)
        #expect(cell.value == 5)
        #expect(cell.isInitial == true)
        #expect(cell.pencilMarks == marks)
        #expect(cell.isSelected == true)
        #expect(cell.hasError == true)
        #expect(cell.isHighlighted == true)
        #expect(cell.isSameNumber == true)
        #expect(cell.isNeighbor == true)
    }

    // MARK: - Factory Methods Tests

    @Test func emptyFactory() {
        let position = CellPosition(row: 0, column: 0)
        let cell = Cell.empty(at: position)

        #expect(cell.position == position)
        #expect(cell.value == nil)
        #expect(cell.isInitial == false)
        #expect(cell.pencilMarks.isEmpty)
    }

    @Test func initialFactory() {
        let position = CellPosition(row: 1, column: 1)
        let cell = Cell.initial(at: position, value: 7)

        #expect(cell.position == position)
        #expect(cell.value == 7)
        #expect(cell.isInitial == true)
        #expect(cell.pencilMarks.isEmpty)
    }

    // MARK: - Computed Properties Tests

    @Test func testIsEmpty() {
        let position = CellPosition(row: 0, column: 0)

        let emptyCell = Cell(position: position, value: nil)
        #expect(emptyCell.isEmpty == true)

        let filledCell = Cell(position: position, value: 5)
        #expect(filledCell.isEmpty == false)

        let zeroCell = Cell(position: position, value: 0)
        #expect(zeroCell.isEmpty == false) // 0 is a valid value
    }

    @Test func testIsEditable() {
        let position = CellPosition(row: 0, column: 0)

        let editableCell = Cell(position: position, isInitial: false)
        #expect(editableCell.isEditable == true)

        let initialCell = Cell(position: position, isInitial: true)
        #expect(initialCell.isEditable == false)
    }

    @Test func testHasPencilMarks() {
        let position = CellPosition(row: 0, column: 0)

        let noMarks = Cell(position: position, pencilMarks: [])
        #expect(noMarks.hasPencilMarks == false)

        let withMarks = Cell(position: position, pencilMarks: [1, 2, 3])
        #expect(withMarks.hasPencilMarks == true)

        let singleMark = Cell(position: position, pencilMarks: [5])
        #expect(singleMark.hasPencilMarks == true)
    }

    // MARK: - Modification Methods Tests

    @Test func testWithValue() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, value: 3, pencilMarks: [1, 2, 3])

        let updated = original.withValue(7)

        #expect(updated.value == 7)
        #expect(updated.pencilMarks.isEmpty) // Should clear pencil marks
        #expect(updated.position == position)
    }

    @Test func withValueClearsPencilMarks() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, pencilMarks: [1, 2, 3, 4, 5])

        let updated = original.withValue(5)

        #expect(updated.value == 5)
        #expect(updated.pencilMarks.isEmpty)
    }

    @Test func withValueNil() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, value: 5)

        let updated = original.withValue(nil)

        #expect(updated.value == nil)
        #expect(updated.isEmpty)
    }

    @Test func testWithPencilMarks() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position)

        let marks: Set<Int> = [1, 3, 5, 7]
        let updated = original.withPencilMarks(marks)

        #expect(updated.pencilMarks == marks)
    }

    @Test func testTogglePencilMark() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, pencilMarks: [1, 2, 3])

        // Toggle off existing mark
        let toggledOff = original.togglePencilMark(2)
        #expect(toggledOff.pencilMarks == [1, 3])

        // Toggle on new mark
        let toggledOn = original.togglePencilMark(5)
        #expect(toggledOn.pencilMarks == [1, 2, 3, 5])

        // Toggle same mark twice returns to original
        let doubled = original.togglePencilMark(4).togglePencilMark(4)
        #expect(doubled.pencilMarks == original.pencilMarks)
    }

    @Test func togglePencilMarkInvalidValue() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, pencilMarks: [1, 2])

        let invalidNegative = original.togglePencilMark(-1)
        #expect(invalidNegative.pencilMarks == [1, 2])

        let invalidTooLarge = original.togglePencilMark(10)
        #expect(invalidTooLarge.pencilMarks == [1, 2])
    }

    @Test func togglePencilMarkBoundaries() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position)

        let withZero = original.togglePencilMark(0)
        #expect(withZero.pencilMarks.contains(0))

        let withNine = original.togglePencilMark(9)
        #expect(withNine.pencilMarks.contains(9))
    }

    @Test func testWithSelection() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, isSelected: false)

        let selected = original.withSelection(true)
        #expect(selected.isSelected == true)

        let deselected = selected.withSelection(false)
        #expect(deselected.isSelected == false)
    }

    @Test func testWithError() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, hasError: false)

        let withError = original.withError(true)
        #expect(withError.hasError == true)

        let withoutError = withError.withError(false)
        #expect(withoutError.hasError == false)
    }

    @Test func testWithHighlight() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, isHighlighted: false)

        let highlighted = original.withHighlight(true)
        #expect(highlighted.isHighlighted == true)

        let unhighlighted = highlighted.withHighlight(false)
        #expect(unhighlighted.isHighlighted == false)
    }

    @Test func testWithSameNumber() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, isSameNumber: false)

        let sameNumber = original.withSameNumber(true)
        #expect(sameNumber.isSameNumber == true)

        let notSameNumber = sameNumber.withSameNumber(false)
        #expect(notSameNumber.isSameNumber == false)
    }

    @Test func testWithNeighbor() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(position: position, isNeighbor: false)

        let neighbor = original.withNeighbor(true)
        #expect(neighbor.isNeighbor == true)

        let notNeighbor = neighbor.withNeighbor(false)
        #expect(notNeighbor.isNeighbor == false)
    }

    @Test func testCleared() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(
            position: position,
            value: 5,
            isInitial: false,
            pencilMarks: [1, 2, 3]
        )

        let cleared = original.cleared()

        #expect(cleared.value == nil)
        #expect(cleared.pencilMarks.isEmpty)
        #expect(cleared.position == position)
    }

    @Test func clearedInitialCell() {
        let position = CellPosition(row: 0, column: 0)
        let original = Cell(
            position: position,
            value: 7,
            isInitial: true
        )

        let cleared = original.cleared()

        // Initial cells should not be cleared
        #expect(cleared.value == 7)
        #expect(cleared.isInitial == true)
        #expect(cleared == original)
    }

    // MARK: - Equatable Tests

    @Test func equality() {
        let position = CellPosition(row: 1, column: 2)

        let cell1 = Cell(position: position, value: 5, isInitial: true)
        let cell2 = Cell(position: position, value: 5, isInitial: true)
        let cell3 = Cell(position: position, value: 6, isInitial: true)
        let cell4 = Cell(position: position, value: 5, isInitial: false)

        #expect(cell1 == cell2)
        #expect(cell1 != cell3)
        #expect(cell1 != cell4)
    }

    @Test func equalityWithPencilMarks() {
        let position = CellPosition(row: 0, column: 0)

        let cell1 = Cell(position: position, pencilMarks: [1, 2, 3])
        let cell2 = Cell(position: position, pencilMarks: [3, 2, 1]) // Different order
        let cell3 = Cell(position: position, pencilMarks: [1, 2])

        #expect(cell1 == cell2) // Sets are order-independent
        #expect(cell1 != cell3)
    }

    // MARK: - Hashable Tests

    @Test func hashable() {
        let position = CellPosition(row: 1, column: 2)

        let cell1 = Cell(position: position, value: 5)
        let cell2 = Cell(position: position, value: 5)
        let cell3 = Cell(position: position, value: 6)

        let set: Set<Cell> = [cell1, cell2, cell3]
        #expect(set.count == 2) // cell1 and cell2 should be the same
    }

    // MARK: - CustomStringConvertible Tests

    @Test func descriptionEmpty() {
        let cell = Cell.empty(at: CellPosition(row: 1, column: 2))
        let description = cell.description

        #expect(description.contains("(1, 2)"))
        #expect(description.contains("_")) // Underscore for empty value
    }

    @Test func descriptionWithValue() {
        let cell = Cell(position: CellPosition(row: 1, column: 2), value: 7)
        let description = cell.description

        #expect(description.contains("(1, 2)"))
        #expect(description.contains("7"))
    }

    @Test func descriptionWithFlags() {
        let cell = Cell(
            position: CellPosition(row: 0, column: 0),
            value: 5,
            isInitial: true,
            isSelected: true,
            hasError: true,
            isHighlighted: true,
            isSameNumber: true,
            isNeighbor: true
        )
        let description = cell.description

        #expect(description.contains("I")) // Initial
        #expect(description.contains("S")) // Selected
        #expect(description.contains("E")) // Error
        #expect(description.contains("H")) // Highlighted
        #expect(description.contains("SN")) // Same Number
        #expect(description.contains("N")) // Neighbor
    }

    @Test func descriptionWithPencilMarks() {
        let cell = Cell(
            position: CellPosition(row: 0, column: 0),
            pencilMarks: [1, 3, 5]
        )
        let description = cell.description

        #expect(description.contains("marks:"))
        #expect(description.contains("1"))
        #expect(description.contains("3"))
        #expect(description.contains("5"))
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        let cell = Cell(
            position: CellPosition(row: 2, column: 3),
            value: 7,
            isInitial: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(cell)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"value\":7"))
        #expect(json.contains("\"isInitial\":true"))
    }

    @Test func codableDecoding() throws {
        let json = """
        {
            "position": {"row": 1, "column": 2},
            "value": 5,
            "isInitial": true,
            "pencilMarks": [1, 2, 3],
            "isSelected": false,
            "hasError": false,
            "isHighlighted": false,
            "isSameNumber": false,
            "isNeighbor": false
        }
        """

        let decoder = JSONDecoder()
        let data = try #require(json.data(using: .utf8))
        let cell = try decoder.decode(Cell.self, from: data)

        #expect(cell.position == CellPosition(row: 1, column: 2))
        #expect(cell.value == 5)
        #expect(cell.isInitial == true)
        #expect(cell.pencilMarks == [1, 2, 3])
        #expect(cell.isNeighbor == false)
    }

    @Test func codableRoundTrip() throws {
        let original = Cell(
            position: CellPosition(row: 3, column: 4),
            value: 8,
            isInitial: false,
            pencilMarks: [2, 4, 6, 8],
            isSelected: true,
            hasError: false,
            isHighlighted: true,
            isSameNumber: true,
            isNeighbor: true
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Cell.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Immutability Tests

    @Test func withValueDoesNotMutateOriginal() {
        let original = Cell.empty(at: CellPosition(row: 0, column: 0))
        let modified = original.withValue(5)

        #expect(original.value == nil)
        #expect(modified.value == 5)
    }

    @Test func togglePencilMarkDoesNotMutateOriginal() {
        let original = Cell(
            position: CellPosition(row: 0, column: 0),
            pencilMarks: [1, 2, 3]
        )
        let modified = original.togglePencilMark(4)

        #expect(original.pencilMarks == [1, 2, 3])
        #expect(modified.pencilMarks == [1, 2, 3, 4])
    }

    @Test func clearedDoesNotMutateOriginal() {
        let original = Cell(
            position: CellPosition(row: 0, column: 0),
            value: 5,
            pencilMarks: [1, 2]
        )
        let cleared = original.cleared()

        #expect(original.value == 5)
        #expect(original.pencilMarks == [1, 2])
        #expect(cleared.value == nil)
        #expect(cleared.pencilMarks.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func allPencilMarks() {
        let position = CellPosition(row: 0, column: 0)
        let cell = Cell(position: position, pencilMarks: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

        #expect(cell.pencilMarks.count == 10)
        #expect(cell.hasPencilMarks)
    }

    @Test func valueZero() {
        let cell = Cell(position: CellPosition(row: 0, column: 0), value: 0)

        #expect(cell.value == 0)
        #expect(!cell.isEmpty)
    }

    @Test func valueNine() {
        let cell = Cell(position: CellPosition(row: 0, column: 0), value: 9)

        #expect(cell.value == 9)
        #expect(!cell.isEmpty)
    }

    @Test func multipleModifications() {
        let original = Cell.empty(at: CellPosition(row: 0, column: 0))

        let modified = original
            .withValue(5)
            .withSelection(true)
            .withError(true)
            .withHighlight(true)
            .withSameNumber(true)
            .withNeighbor(true)

        #expect(modified.value == 5)
        #expect(modified.isSelected)
        #expect(modified.hasError)
        #expect(modified.isHighlighted)
        #expect(modified.isSameNumber)
        #expect(modified.isNeighbor)
        #expect(original.isEmpty) // Original unchanged
    }
}
