import Foundation
import Testing
@testable import TennerGrid

struct GameActionTests {
    // MARK: - Initialization Tests

    @Test func basicInitialization() {
        let position = CellPosition(row: 1, column: 2)
        let action = GameAction(
            type: .setValue,
            position: position,
            oldValue: nil,
            newValue: 5
        )

        #expect(action.type == .setValue)
        #expect(action.position == position)
        #expect(action.oldValue == nil)
        #expect(action.newValue == 5)
        #expect(action.oldPencilMarks.isEmpty)
        #expect(action.newPencilMarks.isEmpty)
    }

    @Test func initializationWithPencilMarks() {
        let position = CellPosition(row: 0, column: 0)
        let oldMarks: Set<Int> = [1, 2, 3]
        let newMarks: Set<Int> = [1, 2, 3, 4]

        let action = GameAction(
            type: .setPencilMarks,
            position: position,
            oldPencilMarks: oldMarks,
            newPencilMarks: newMarks
        )

        #expect(action.type == .setPencilMarks)
        #expect(action.position == position)
        #expect(action.oldPencilMarks == oldMarks)
        #expect(action.newPencilMarks == newMarks)
    }

    @Test func initializationWithDefaultTimestamp() {
        let before = Date()
        let action = GameAction(
            type: .clearCell,
            position: CellPosition(row: 0, column: 0)
        )
        let after = Date()

        #expect(action.timestamp >= before)
        #expect(action.timestamp <= after)
    }

    @Test func initializationWithCustomTimestamp() {
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        let action = GameAction(
            type: .setValue,
            position: CellPosition(row: 1, column: 1),
            timestamp: customDate
        )

        #expect(action.timestamp == customDate)
    }

    // MARK: - ActionType Tests

    @Test func actionTypeRawValues() {
        #expect(GameAction.ActionType.setValue.rawValue == "setValue")
        #expect(GameAction.ActionType.clearValue.rawValue == "clearValue")
        #expect(GameAction.ActionType.setPencilMarks.rawValue == "setPencilMarks")
        #expect(GameAction.ActionType.clearPencilMarks.rawValue == "clearPencilMarks")
        #expect(GameAction.ActionType.togglePencilMark.rawValue == "togglePencilMark")
        #expect(GameAction.ActionType.clearCell.rawValue == "clearCell")
    }

    @Test func actionTypeAllCases() {
        let allCases = GameAction.ActionType.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.setValue))
        #expect(allCases.contains(.clearValue))
        #expect(allCases.contains(.setPencilMarks))
        #expect(allCases.contains(.clearPencilMarks))
        #expect(allCases.contains(.togglePencilMark))
        #expect(allCases.contains(.clearCell))
    }

    // MARK: - Factory Method Tests

    @Test func setValueFactoryMethod() {
        let position = CellPosition(row: 2, column: 3)
        let action = GameAction.setValue(at: position, from: nil, to: 7)

        #expect(action.type == .setValue)
        #expect(action.position == position)
        #expect(action.oldValue == nil)
        #expect(action.newValue == 7)
        #expect(action.oldPencilMarks.isEmpty)
        #expect(action.newPencilMarks.isEmpty)
    }

    @Test func setValueFactoryMethodWithExistingValue() {
        let position = CellPosition(row: 1, column: 1)
        let action = GameAction.setValue(at: position, from: 3, to: 8)

        #expect(action.type == .setValue)
        #expect(action.oldValue == 3)
        #expect(action.newValue == 8)
    }

    @Test func setValueFactoryMethodClearingMarks() {
        let position = CellPosition(row: 0, column: 0)
        let marks: Set<Int> = [1, 2, 3]
        let action = GameAction.setValue(at: position, from: nil, to: 5, clearingMarks: marks)

        #expect(action.type == .setValue)
        #expect(action.oldValue == nil)
        #expect(action.newValue == 5)
        #expect(action.oldPencilMarks == marks)
        #expect(action.newPencilMarks.isEmpty)
    }

    @Test func clearValueFactoryMethod() {
        let position = CellPosition(row: 3, column: 4)
        let action = GameAction.clearValue(at: position, from: 9)

        #expect(action.type == .clearValue)
        #expect(action.position == position)
        #expect(action.oldValue == 9)
        #expect(action.newValue == nil)
    }

    @Test func setPencilMarksFactoryMethod() {
        let position = CellPosition(row: 2, column: 2)
        let oldMarks: Set<Int> = [1, 2]
        let newMarks: Set<Int> = [1, 2, 3, 4]

        let action = GameAction.setPencilMarks(at: position, from: oldMarks, to: newMarks)

        #expect(action.type == .setPencilMarks)
        #expect(action.position == position)
        #expect(action.oldPencilMarks == oldMarks)
        #expect(action.newPencilMarks == newMarks)
    }

    @Test func togglePencilMarkFactoryMethod() {
        let position = CellPosition(row: 1, column: 3)
        let oldMarks: Set<Int> = [1, 2, 3]
        let newMarks: Set<Int> = [1, 2, 3, 4]

        let action = GameAction.togglePencilMark(4, at: position, from: oldMarks, to: newMarks)

        #expect(action.type == .togglePencilMark)
        #expect(action.position == position)
        #expect(action.oldPencilMarks == oldMarks)
        #expect(action.newPencilMarks == newMarks)
    }

    @Test func clearCellFactoryMethod() {
        let position = CellPosition(row: 4, column: 4)
        let marks: Set<Int> = [1, 5, 9]

        let action = GameAction.clearCell(at: position, from: 7, clearingMarks: marks)

        #expect(action.type == .clearCell)
        #expect(action.position == position)
        #expect(action.oldValue == 7)
        #expect(action.newValue == nil)
        #expect(action.oldPencilMarks == marks)
        #expect(action.newPencilMarks.isEmpty)
    }

    @Test func clearCellFactoryMethodWithoutValue() {
        let position = CellPosition(row: 0, column: 1)
        let marks: Set<Int> = [2, 4, 6]

        let action = GameAction.clearCell(at: position, from: nil, clearingMarks: marks)

        #expect(action.oldValue == nil)
        #expect(action.newValue == nil)
        #expect(action.oldPencilMarks == marks)
    }

    // MARK: - Property Tests

    @Test func changedValueTrue() {
        let action = GameAction.setValue(at: CellPosition(row: 0, column: 0), from: 3, to: 7)
        #expect(action.changedValue)
    }

    @Test func changedValueFalse() {
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 0, column: 0),
            from: [1, 2],
            to: [1, 2, 3]
        )
        #expect(!action.changedValue)
    }

    @Test func changedValueNilToValue() {
        let action = GameAction.setValue(at: CellPosition(row: 0, column: 0), from: nil, to: 5)
        #expect(action.changedValue)
    }

    @Test func changedValueValueToNil() {
        let action = GameAction.clearValue(at: CellPosition(row: 0, column: 0), from: 5)
        #expect(action.changedValue)
    }

    @Test func changedPencilMarksTrue() {
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 1, column: 1),
            from: [1, 2],
            to: [1, 2, 3]
        )
        #expect(action.changedPencilMarks)
    }

    @Test func changedPencilMarksFalse() {
        let marks: Set<Int> = [1, 2, 3]
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 1, column: 1),
            from: marks,
            to: marks
        )
        #expect(!action.changedPencilMarks)
    }

    @Test func madeChangesValue() {
        let action = GameAction.setValue(at: CellPosition(row: 0, column: 0), from: nil, to: 5)
        #expect(action.madeChanges)
    }

    @Test func madeChangesPencilMarks() {
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 0, column: 0),
            from: [1],
            to: [1, 2]
        )
        #expect(action.madeChanges)
    }

    @Test func madeChangesBoth() {
        let action = GameAction(
            type: .clearCell,
            position: CellPosition(row: 0, column: 0),
            oldValue: 5,
            newValue: nil,
            oldPencilMarks: [1, 2, 3],
            newPencilMarks: []
        )
        #expect(action.madeChanges)
    }

    @Test func madeChangesNone() {
        let action = GameAction(
            type: .setValue,
            position: CellPosition(row: 0, column: 0),
            oldValue: 5,
            newValue: 5,
            oldPencilMarks: [],
            newPencilMarks: []
        )
        #expect(!action.madeChanges)
    }

    // MARK: - Inverse Tests

    @Test func inverseSetValue() {
        let action = GameAction.setValue(at: CellPosition(row: 1, column: 2), from: 3, to: 7)
        let inverse = action.inverse()

        #expect(inverse.type == action.type)
        #expect(inverse.position == action.position)
        #expect(inverse.oldValue == action.newValue)
        #expect(inverse.newValue == action.oldValue)
        #expect(inverse.timestamp == action.timestamp)
    }

    @Test func inverseClearValue() {
        let action = GameAction.clearValue(at: CellPosition(row: 0, column: 0), from: 5)
        let inverse = action.inverse()

        #expect(inverse.oldValue == nil)
        #expect(inverse.newValue == 5)
    }

    @Test func inversePencilMarks() {
        let oldMarks: Set<Int> = [1, 2]
        let newMarks: Set<Int> = [1, 2, 3, 4]
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 2, column: 3),
            from: oldMarks,
            to: newMarks
        )
        let inverse = action.inverse()

        #expect(inverse.oldPencilMarks == newMarks)
        #expect(inverse.newPencilMarks == oldMarks)
    }

    @Test func inverseDoubleInverse() {
        let action = GameAction.setValue(at: CellPosition(row: 1, column: 1), from: 2, to: 8)
        let inverse = action.inverse()
        let doubleInverse = inverse.inverse()

        #expect(doubleInverse.oldValue == action.oldValue)
        #expect(doubleInverse.newValue == action.newValue)
        #expect(doubleInverse.oldPencilMarks == action.oldPencilMarks)
        #expect(doubleInverse.newPencilMarks == action.newPencilMarks)
    }

    // MARK: - Equatable Tests

    @Test func equalityIdentical() {
        let position = CellPosition(row: 1, column: 2)
        let timestamp = Date()

        let action1 = GameAction(
            type: .setValue,
            position: position,
            oldValue: 3,
            newValue: 7,
            timestamp: timestamp
        )
        let action2 = GameAction(
            type: .setValue,
            position: position,
            oldValue: 3,
            newValue: 7,
            timestamp: timestamp
        )

        #expect(action1 == action2)
    }

    @Test func equalityDifferentType() {
        let position = CellPosition(row: 1, column: 2)
        let timestamp = Date()

        let action1 = GameAction(type: .setValue, position: position, timestamp: timestamp)
        let action2 = GameAction(type: .clearValue, position: position, timestamp: timestamp)

        #expect(action1 != action2)
    }

    @Test func equalityDifferentPosition() {
        let action1 = GameAction(
            type: .setValue,
            position: CellPosition(row: 0, column: 0)
        )
        let action2 = GameAction(
            type: .setValue,
            position: CellPosition(row: 0, column: 1)
        )

        #expect(action1 != action2)
    }

    @Test func equalityDifferentValues() {
        let position = CellPosition(row: 1, column: 1)
        let action1 = GameAction.setValue(at: position, from: 3, to: 7)
        let action2 = GameAction.setValue(at: position, from: 3, to: 8)

        #expect(action1 != action2)
    }

    @Test func equalityDifferentPencilMarks() {
        let position = CellPosition(row: 1, column: 1)
        let action1 = GameAction.setPencilMarks(at: position, from: [1, 2], to: [1, 2, 3])
        let action2 = GameAction.setPencilMarks(at: position, from: [1, 2], to: [1, 2, 4])

        #expect(action1 != action2)
    }

    // MARK: - Codable Tests

    @Test func codableEncodingSetValue() throws {
        let action = GameAction.setValue(
            at: CellPosition(row: 2, column: 3),
            from: 5,
            to: 8
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"type\":\"setValue\""))
        #expect(json.contains("\"row\":2"))
        #expect(json.contains("\"column\":3"))
        #expect(json.contains("\"oldValue\":5"))
        #expect(json.contains("\"newValue\":8"))
    }

    @Test func codableDecodingSetValue() throws {
        let json = """
        {
            "type": "setValue",
            "position": {"row": 1, "column": 2},
            "oldValue": 3,
            "newValue": 7,
            "oldPencilMarks": [],
            "newPencilMarks": [],
            "timestamp": 1000000
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        let action = try decoder.decode(GameAction.self, from: data)

        #expect(action.type == .setValue)
        #expect(action.position == CellPosition(row: 1, column: 2))
        #expect(action.oldValue == 3)
        #expect(action.newValue == 7)
    }

    @Test func codableEncodingWithPencilMarks() throws {
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 0, column: 0),
            from: [1, 2],
            to: [1, 2, 3, 4]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"type\":\"setPencilMarks\""))
        #expect(json.contains("\"oldPencilMarks\""))
        #expect(json.contains("\"newPencilMarks\""))
    }

    @Test func codableRoundTrip() throws {
        let original = GameAction.setValue(
            at: CellPosition(row: 3, column: 4),
            from: 2,
            to: 9,
            clearingMarks: [1, 2, 3]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(GameAction.self, from: data)

        #expect(decoded.type == original.type)
        #expect(decoded.position == original.position)
        #expect(decoded.oldValue == original.oldValue)
        #expect(decoded.newValue == original.newValue)
        #expect(decoded.oldPencilMarks == original.oldPencilMarks)
        #expect(decoded.newPencilMarks == original.newPencilMarks)
    }

    @Test func codableRoundTripAllActionTypes() throws {
        let actions = [
            GameAction.setValue(at: CellPosition(row: 0, column: 0), from: nil, to: 5),
            GameAction.clearValue(at: CellPosition(row: 1, column: 1), from: 7),
            GameAction.setPencilMarks(at: CellPosition(row: 2, column: 2), from: [1], to: [1, 2]),
            GameAction.togglePencilMark(3, at: CellPosition(row: 3, column: 3), from: [1, 2], to: [1, 2, 3]),
            GameAction.clearCell(at: CellPosition(row: 4, column: 4), from: 8, clearingMarks: [1, 2, 3]),
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in actions {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(GameAction.self, from: data)
            #expect(decoded.type == original.type)
            #expect(decoded.position == original.position)
        }
    }

    // MARK: - CustomStringConvertible Tests

    @Test func descriptionSetValue() {
        let action = GameAction.setValue(at: CellPosition(row: 1, column: 2), from: 3, to: 7)
        let description = action.description

        #expect(description.contains("setValue"))
        #expect(description.contains("(1, 2)"))
        #expect(description.contains("value"))
        #expect(description.contains("3"))
        #expect(description.contains("7"))
    }

    @Test func descriptionClearValue() {
        let action = GameAction.clearValue(at: CellPosition(row: 0, column: 0), from: 5)
        let description = action.description

        #expect(description.contains("clearValue"))
        #expect(description.contains("(0, 0)"))
        #expect(description.contains("5"))
        #expect(description.contains("nil"))
    }

    @Test func descriptionSetPencilMarks() {
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 2, column: 3),
            from: [1, 2],
            to: [1, 2, 3]
        )
        let description = action.description

        #expect(description.contains("setPencilMarks"))
        #expect(description.contains("(2, 3)"))
        #expect(description.contains("marks"))
    }

    @Test func descriptionNoChanges() {
        let action = GameAction(
            type: .setValue,
            position: CellPosition(row: 1, column: 1),
            oldValue: 5,
            newValue: 5
        )
        let description = action.description

        #expect(description.contains("setValue"))
        #expect(description.contains("(1, 1)"))
    }

    // MARK: - Edge Cases

    @Test func actionWithZeroValue() {
        let action = GameAction.setValue(at: CellPosition(row: 0, column: 0), from: nil, to: 0)
        #expect(action.newValue == 0)
        #expect(action.changedValue)
    }

    @Test func actionWithAllPencilMarks() {
        let allMarks: Set<Int> = Set(0 ... 9)
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 1, column: 1),
            from: [],
            to: allMarks
        )

        #expect(action.newPencilMarks.count == 10)
        #expect(action.changedPencilMarks)
    }

    @Test func actionWithEmptyToEmptyPencilMarks() {
        let action = GameAction.setPencilMarks(
            at: CellPosition(row: 2, column: 2),
            from: [],
            to: []
        )

        #expect(!action.changedPencilMarks)
        #expect(!action.madeChanges)
    }

    @Test func multipleActionsAtSamePosition() {
        let position = CellPosition(row: 1, column: 1)
        let action1 = GameAction.setValue(at: position, from: nil, to: 5)
        let action2 = GameAction.setValue(at: position, from: 5, to: 8)
        let action3 = GameAction.clearValue(at: position, from: 8)

        #expect(action1.position == action2.position)
        #expect(action2.position == action3.position)
        #expect(action1.newValue == action2.oldValue)
        #expect(action2.newValue == action3.oldValue)
    }

    @Test func actionChainInverseRestoresOriginal() {
        // Simulate a sequence of actions and their inverses
        let position = CellPosition(row: 2, column: 2)

        // Action 1: Set value 5
        let action1 = GameAction.setValue(at: position, from: nil, to: 5)

        // Action 2: Change to 8
        let action2 = GameAction.setValue(at: position, from: 5, to: 8)

        // Inverse action 2 should restore to 5
        let inverse2 = action2.inverse()
        #expect(inverse2.oldValue == 8)
        #expect(inverse2.newValue == 5)

        // Inverse action 1 should restore to nil
        let inverse1 = action1.inverse()
        #expect(inverse1.oldValue == 5)
        #expect(inverse1.newValue == nil)
    }
}
