# GridView Tests

This directory contains UI component tests for the TennerGrid app's views.

## GridViewTests.swift

Comprehensive test suite for the GridView component that displays the Tenner Grid puzzle.

### Test Coverage

#### Grid Rendering Tests (Different Puzzle Sizes)
- **testGridRendering5x5**: Verifies GridView renders correctly with minimum size (5×5)
- **testGridRendering6x5**: Tests 6×5 grid rendering
- **testGridRendering7x5**: Tests 7×5 grid rendering (standard size)
- **testGridRendering8x5**: Tests 8×5 grid rendering
- **testGridRendering9x5**: Tests 9×5 grid rendering
- **testGridRendering10x5**: Tests maximum size (10×5) grid rendering

#### Column Sum Display Tests
- **testColumnSumsDisplay**: Validates that column sums are displayed correctly for all puzzle sizes (5-10 columns)
- Ensures target sums are within valid range (0-45 for 5 rows)

#### Cell Positioning Tests
- **testCellPositioning**: Verifies cells are correctly positioned in the grid
- Tests corner cells (top-left, top-right, bottom-left, bottom-right) and middle cells

#### Visual State Tests
- **testGridSelectionUpdates**: Ensures grid updates correctly when cells are selected
- **testGridWithDifferentDifficulties**: Tests grid rendering with all difficulty levels (easy, medium, hard, expert)
- Validates difficulty-based pre-filled cell counts

#### Layout Tests
- **testGridLayoutAdaptability**: Tests grid adaptation to different size classes (compact/regular)
- Ensures compatibility with various device sizes

#### Performance Tests
- **testGridRenderingPerformance**: Measures performance of creating GridView with maximum puzzle size
- **testCellSelectionPerformance**: Measures performance of selecting all cells in a 10×5 grid

#### Edge Cases
- **testMinimumPuzzleSize**: Validates handling of minimum size (5×5)
- **testMaximumPuzzleSize**: Validates handling of maximum size (10×5)
- **testEmptyPuzzle**: Tests grid with no pre-filled cells
- **testColumnCompletionDetection**: Verifies correct detection of completed columns

### Test Methodology

All tests follow the Given-When-Then pattern:
1. **Given**: Set up the puzzle and view model
2. **When**: Perform the action (e.g., create GridView, select cell)
3. **Then**: Verify the expected outcome

### Dependencies

Tests depend on:
- `PuzzleGenerator`: For creating test puzzles
- `GameViewModel`: For managing game state
- `TennerGridPuzzle`: Core puzzle model
- `Cell` and `CellPosition`: Cell models

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Or use xcodebuild directly
xcodebuild -scheme TennerGrid \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    test
```

### Test Results Expected

All tests should pass with:
- ✅ All puzzle sizes (5×5 through 10×5) render correctly
- ✅ Column sums display correctly for all sizes
- ✅ Cell positioning is accurate
- ✅ Selection and difficulty variations work properly
- ✅ Layout adapts to different size classes
- ✅ Performance is acceptable for maximum puzzle size
- ✅ Edge cases are handled correctly
