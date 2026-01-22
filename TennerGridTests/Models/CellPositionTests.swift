//
//  CellPositionTests.swift
//  TennerGridTests
//
//  Created by Claude on 2026-01-22.
//

@testable import TennerGrid
import Testing

struct CellPositionTests {
    // MARK: - Initialization Tests

    @Test func initialization() {
        let position = CellPosition(row: 3, column: 5)
        #expect(position.row == 3)
        #expect(position.column == 5)
    }

    @Test func zeroPosition() {
        let position = CellPosition(row: 0, column: 0)
        #expect(position.row == 0)
        #expect(position.column == 0)
    }

    // MARK: - Equatable Tests

    @Test func equality() {
        let pos1 = CellPosition(row: 2, column: 3)
        let pos2 = CellPosition(row: 2, column: 3)
        let pos3 = CellPosition(row: 2, column: 4)
        let pos4 = CellPosition(row: 3, column: 3)

        #expect(pos1 == pos2)
        #expect(pos1 != pos3)
        #expect(pos1 != pos4)
        #expect(pos3 != pos4)
    }

    // MARK: - Hashable Tests

    @Test func hashable() {
        let pos1 = CellPosition(row: 1, column: 2)
        let pos2 = CellPosition(row: 1, column: 2)
        let pos3 = CellPosition(row: 1, column: 3)

        let set: Set<CellPosition> = [pos1, pos2, pos3]
        #expect(set.count == 2) // pos1 and pos2 should be the same
        #expect(set.contains(pos1))
        #expect(set.contains(pos3))
    }

    // MARK: - Adjacent Positions Tests

    @Test func adjacentPositionsCenter() {
        let position = CellPosition(row: 3, column: 3)
        let adjacent = position.adjacentPositions(maxRows: 6, maxColumns: 6)

        #expect(adjacent.count == 8) // All 8 surrounding cells

        let expected: Set<CellPosition> = [
            CellPosition(row: 2, column: 2), // Top-left
            CellPosition(row: 2, column: 3), // Top
            CellPosition(row: 2, column: 4), // Top-right
            CellPosition(row: 3, column: 2), // Left
            CellPosition(row: 3, column: 4), // Right
            CellPosition(row: 4, column: 2), // Bottom-left
            CellPosition(row: 4, column: 3), // Bottom
            CellPosition(row: 4, column: 4), // Bottom-right
        ]

        #expect(Set(adjacent) == expected)
    }

    @Test func adjacentPositionsTopLeftCorner() {
        let position = CellPosition(row: 0, column: 0)
        let adjacent = position.adjacentPositions(maxRows: 5, maxColumns: 5)

        #expect(adjacent.count == 3) // Only right, bottom-right, and bottom

        let expected: Set<CellPosition> = [
            CellPosition(row: 0, column: 1), // Right
            CellPosition(row: 1, column: 0), // Bottom
            CellPosition(row: 1, column: 1), // Bottom-right
        ]

        #expect(Set(adjacent) == expected)
    }

    @Test func adjacentPositionsBottomRightCorner() {
        let position = CellPosition(row: 4, column: 4)
        let adjacent = position.adjacentPositions(maxRows: 5, maxColumns: 5)

        #expect(adjacent.count == 3) // Only left, top-left, and top

        let expected: Set<CellPosition> = [
            CellPosition(row: 3, column: 3), // Top-left
            CellPosition(row: 3, column: 4), // Top
            CellPosition(row: 4, column: 3), // Left
        ]

        #expect(Set(adjacent) == expected)
    }

    @Test func adjacentPositionsTopEdge() {
        let position = CellPosition(row: 0, column: 2)
        let adjacent = position.adjacentPositions(maxRows: 5, maxColumns: 5)

        #expect(adjacent.count == 5) // Top row, not corners

        let expected: Set<CellPosition> = [
            CellPosition(row: 0, column: 1), // Left
            CellPosition(row: 0, column: 3), // Right
            CellPosition(row: 1, column: 1), // Bottom-left
            CellPosition(row: 1, column: 2), // Bottom
            CellPosition(row: 1, column: 3), // Bottom-right
        ]

        #expect(Set(adjacent) == expected)
    }

    @Test func adjacentPositionsLeftEdge() {
        let position = CellPosition(row: 2, column: 0)
        let adjacent = position.adjacentPositions(maxRows: 5, maxColumns: 5)

        #expect(adjacent.count == 5) // Left edge, not corners

        let expected: Set<CellPosition> = [
            CellPosition(row: 1, column: 0), // Top
            CellPosition(row: 1, column: 1), // Top-right
            CellPosition(row: 2, column: 1), // Right
            CellPosition(row: 3, column: 0), // Bottom
            CellPosition(row: 3, column: 1), // Bottom-right
        ]

        #expect(Set(adjacent) == expected)
    }

    // MARK: - Row Positions Tests

    @Test func testRowPositions() {
        let position = CellPosition(row: 2, column: 3)
        let rowPositions = position.rowPositions(maxColumns: 6)

        #expect(rowPositions.count == 5) // All columns except self

        let expected: Set<CellPosition> = [
            CellPosition(row: 2, column: 0),
            CellPosition(row: 2, column: 1),
            CellPosition(row: 2, column: 2),
            CellPosition(row: 2, column: 4),
            CellPosition(row: 2, column: 5),
        ]

        #expect(Set(rowPositions) == expected)
        #expect(!rowPositions.contains(position)) // Should not include self
    }

    @Test func rowPositionsSingleColumn() {
        let position = CellPosition(row: 0, column: 0)
        let rowPositions = position.rowPositions(maxColumns: 1)

        #expect(rowPositions.isEmpty) // No other columns
    }

    // MARK: - Column Positions Tests

    @Test func testColumnPositions() {
        let position = CellPosition(row: 3, column: 2)
        let columnPositions = position.columnPositions(maxRows: 6)

        #expect(columnPositions.count == 5) // All rows except self

        let expected: Set<CellPosition> = [
            CellPosition(row: 0, column: 2),
            CellPosition(row: 1, column: 2),
            CellPosition(row: 2, column: 2),
            CellPosition(row: 4, column: 2),
            CellPosition(row: 5, column: 2),
        ]

        #expect(Set(columnPositions) == expected)
        #expect(!columnPositions.contains(position)) // Should not include self
    }

    @Test func columnPositionsSingleRow() {
        let position = CellPosition(row: 0, column: 0)
        let columnPositions = position.columnPositions(maxRows: 1)

        #expect(columnPositions.isEmpty) // No other rows
    }

    // MARK: - isAdjacent Tests

    @Test func isAdjacentHorizontal() {
        let pos1 = CellPosition(row: 2, column: 3)
        let pos2 = CellPosition(row: 2, column: 4)

        #expect(pos1.isAdjacent(to: pos2))
        #expect(pos2.isAdjacent(to: pos1))
    }

    @Test func isAdjacentVertical() {
        let pos1 = CellPosition(row: 2, column: 3)
        let pos2 = CellPosition(row: 3, column: 3)

        #expect(pos1.isAdjacent(to: pos2))
        #expect(pos2.isAdjacent(to: pos1))
    }

    @Test func isAdjacentDiagonal() {
        let pos1 = CellPosition(row: 2, column: 3)
        let pos2 = CellPosition(row: 3, column: 4)

        #expect(pos1.isAdjacent(to: pos2))
        #expect(pos2.isAdjacent(to: pos1))
    }

    @Test func isNotAdjacentSamePosition() {
        let pos = CellPosition(row: 2, column: 3)

        #expect(!pos.isAdjacent(to: pos))
    }

    @Test func isNotAdjacentTooFar() {
        let pos1 = CellPosition(row: 2, column: 3)
        let pos2 = CellPosition(row: 2, column: 5) // 2 columns away
        let pos3 = CellPosition(row: 4, column: 3) // 2 rows away
        let pos4 = CellPosition(row: 4, column: 5) // 2 rows and 2 columns away

        #expect(!pos1.isAdjacent(to: pos2))
        #expect(!pos1.isAdjacent(to: pos3))
        #expect(!pos1.isAdjacent(to: pos4))
    }

    @Test func isAdjacentAllDirections() {
        let center = CellPosition(row: 3, column: 3)

        let allAdjacentPositions = [
            CellPosition(row: 2, column: 2), // Top-left
            CellPosition(row: 2, column: 3), // Top
            CellPosition(row: 2, column: 4), // Top-right
            CellPosition(row: 3, column: 2), // Left
            CellPosition(row: 3, column: 4), // Right
            CellPosition(row: 4, column: 2), // Bottom-left
            CellPosition(row: 4, column: 3), // Bottom
            CellPosition(row: 4, column: 4), // Bottom-right
        ]

        for adjacentPos in allAdjacentPositions {
            #expect(center.isAdjacent(to: adjacentPos),
                    "\(center) should be adjacent to \(adjacentPos)")
        }
    }

    // MARK: - CustomStringConvertible Tests

    @Test func testDescription() {
        let position = CellPosition(row: 3, column: 5)
        #expect(position.description == "(3, 5)")
    }

    @Test func descriptionZero() {
        let position = CellPosition(row: 0, column: 0)
        #expect(position.description == "(0, 0)")
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        let position = CellPosition(row: 2, column: 4)
        let encoder = JSONEncoder()
        let data = try encoder.encode(position)

        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"row\":2"))
        #expect(json.contains("\"column\":4"))
    }

    @Test func codableDecoding() throws {
        let json = """
        {"row":3,"column":7}
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let position = try decoder.decode(CellPosition.self, from: data)

        #expect(position.row == 3)
        #expect(position.column == 7)
    }

    @Test func codableRoundTrip() throws {
        let original = CellPosition(row: 5, column: 9)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(CellPosition.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Edge Cases

    @Test func adjacentPositionsInSmallGrid() {
        let position = CellPosition(row: 1, column: 1)
        let adjacent = position.adjacentPositions(maxRows: 3, maxColumns: 3)

        #expect(adjacent.count == 8) // All 8 surrounding cells in 3x3 grid
    }

    @Test func adjacentPositionsInSingleCellGrid() {
        let position = CellPosition(row: 0, column: 0)
        let adjacent = position.adjacentPositions(maxRows: 1, maxColumns: 1)

        #expect(adjacent.isEmpty) // No adjacent cells in 1x1 grid
    }

    @Test func largeGridPositions() {
        let position = CellPosition(row: 50, column: 50)
        let adjacent = position.adjacentPositions(maxRows: 100, maxColumns: 100)

        #expect(adjacent.count == 8) // Should still have 8 adjacent cells
    }
}
