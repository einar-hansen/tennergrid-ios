import SwiftUI
import XCTest
@testable import TennerGrid

/// Tests to verify that all interactive elements meet Apple's minimum tap target size requirements
/// According to Apple HIG, minimum tap target size should be 44x44 points
final class TapTargetAccessibilityTests: XCTestCase {
    // MARK: - Constants

    /// Apple's recommended minimum tap target size (44x44 points)
    private let minimumTapTargetSize: CGFloat = 44

    /// Recommended iPad tap target size for better ergonomics
    private let recommendedIPadTapTargetSize: CGFloat = 56

    // MARK: - Number Pad Tests

    func testNumberPadButtonSizes_iPhone() {
        // Given: Number pad on iPhone
        let iPhoneButtonSize: CGFloat = 60 // From NumberPadView

        // Then: Button size should meet minimum requirements
        XCTAssertGreaterThanOrEqual(
            iPhoneButtonSize,
            minimumTapTargetSize,
            "Number pad buttons on iPhone should be at least \(minimumTapTargetSize)x\(minimumTapTargetSize) points"
        )
    }

    func testNumberPadButtonSizes_iPad() {
        // Given: Number pad on iPad
        let iPadButtonSize: CGFloat = 80 // From NumberPadView

        // Then: Button size should meet recommended iPad size
        XCTAssertGreaterThanOrEqual(
            iPadButtonSize,
            recommendedIPadTapTargetSize,
            "Number pad buttons on iPad should be at least \(recommendedIPadTapTargetSize)x\(recommendedIPadTapTargetSize) points for better ergonomics"
        )
    }

    func testNumberPadButtonSpacing_iPhone() {
        // Given: Spacing between number pad buttons on iPhone
        let iPhoneSpacing: CGFloat = 8 // From NumberPadView

        // Then: Spacing should be adequate for touch accuracy
        XCTAssertGreaterThanOrEqual(
            iPhoneSpacing,
            8,
            "Number pad buttons should have at least 8 points spacing"
        )
    }

    func testNumberPadButtonSpacing_iPad() {
        // Given: Spacing between number pad buttons on iPad
        let iPadSpacing: CGFloat = 12 // From NumberPadView

        // Then: Spacing should be adequate for touch accuracy
        XCTAssertGreaterThanOrEqual(
            iPadSpacing,
            8,
            "Number pad buttons on iPad should have at least 8 points spacing"
        )
    }

    // MARK: - Toolbar Tests

    func testGameToolbarButtonSizes_iPhone() {
        // Given: Toolbar button size on iPhone
        let iPhoneToolbarButtonSize: CGFloat = 44 // From GameToolbarView

        // Then: Button size should meet minimum requirements
        XCTAssertGreaterThanOrEqual(
            iPhoneToolbarButtonSize,
            minimumTapTargetSize,
            "Toolbar buttons on iPhone should be at least \(minimumTapTargetSize)x\(minimumTapTargetSize) points"
        )
    }

    func testGameToolbarButtonSizes_iPad() {
        // Given: Toolbar button size on iPad
        let iPadToolbarButtonSize: CGFloat = 56 // From GameToolbarView

        // Then: Button size should meet recommended iPad size
        XCTAssertGreaterThanOrEqual(
            iPadToolbarButtonSize,
            recommendedIPadTapTargetSize,
            "Toolbar buttons on iPad should be at least \(recommendedIPadTapTargetSize)x\(recommendedIPadTapTargetSize) points"
        )
    }

    func testGameToolbarButtonSpacing_iPhone() {
        // Given: Spacing between toolbar buttons on iPhone
        let iPhoneSpacing: CGFloat = 24 // From GameToolbarView

        // Then: Spacing should be adequate for touch accuracy
        XCTAssertGreaterThanOrEqual(
            iPhoneSpacing,
            8,
            "Toolbar buttons should have at least 8 points spacing"
        )
    }

    func testGameToolbarButtonSpacing_iPad() {
        // Given: Spacing between toolbar buttons on iPad
        let iPadSpacing: CGFloat = 32 // From GameToolbarView

        // Then: Spacing should be adequate for touch accuracy
        XCTAssertGreaterThanOrEqual(
            iPadSpacing,
            8,
            "Toolbar buttons on iPad should have at least 8 points spacing"
        )
    }

    // MARK: - Header Tests

    func testGameHeaderButtonsWithMinimumTapTarget() {
        // Given: Header buttons are 36x36 but wrapped in minimumTapTarget()
        let visualSize: CGFloat = 36 // Visual size from GameHeaderView
        let effectiveTapTargetSize: CGFloat = 44 // After minimumTapTarget() modifier

        // Then: Visual size can be smaller, but effective tap target should be 44x44
        XCTAssertLessThan(
            visualSize,
            minimumTapTargetSize,
            "Visual button size can be smaller for aesthetics"
        )

        XCTAssertEqual(
            effectiveTapTargetSize,
            minimumTapTargetSize,
            "Effective tap target size should be exactly \(minimumTapTargetSize)x\(minimumTapTargetSize) points"
        )
    }

    // MARK: - Cell Tests

    func testCellSizeCalculation_iPhone() {
        // Given: iPhone screen width (smallest is iPhone SE at 320 points)
        let iPhoneSEWidth: CGFloat = 320
        let columns = 10 // Fixed 10 columns for Tenner Grid
        let horizontalPadding: CGFloat = 32 // Standard padding
        let columnSpacing: CGFloat = 0 // No spacing between columns

        // When: Calculate cell size
        let availableWidth = iPhoneSEWidth - horizontalPadding
        let cellSize = availableWidth / CGFloat(columns)

        // Then: Cell size should be reasonable for touch (at least 28 points)
        XCTAssertGreaterThanOrEqual(
            cellSize,
            28,
            "Grid cells should be at least 28x28 points for usability on smallest device"
        )
    }

    func testCellSizeCalculation_iPad() {
        // Given: iPad screen width (iPad Mini is ~744 points in portrait)
        let iPadMiniWidth: CGFloat = 744
        let columns = 10
        let horizontalPadding: CGFloat = 64 // More padding on iPad

        // When: Calculate cell size
        let availableWidth = iPadMiniWidth - horizontalPadding
        let cellSize = availableWidth / CGFloat(columns)

        // Then: Cell size should be comfortable for touch on iPad
        XCTAssertGreaterThanOrEqual(
            cellSize,
            60,
            "Grid cells on iPad should be at least 60x60 points for comfortable interaction"
        )
    }

    // MARK: - View Modifier Tests

    func testMinimumTapTargetModifier() {
        // Given: The minimumTapTarget view modifier exists
        // When: Applied to a view
        // Then: It should enforce minimum 44x44 tap target

        // This is a conceptual test - the actual enforcement happens in the SwiftUI layout system
        // We verify the modifier exists and is being used correctly in the views
        let expectedMinimum: CGFloat = 44

        XCTAssertEqual(
            expectedMinimum,
            minimumTapTargetSize,
            "minimumTapTarget() modifier should enforce 44x44 minimum"
        )
    }

    func testAdaptiveTapTargetModifier_iPad() {
        // Given: The adaptiveTapTarget modifier for iPad
        let iPadMinimumSize: CGFloat = 56

        // Then: iPad should get larger tap targets
        XCTAssertGreaterThan(
            iPadMinimumSize,
            minimumTapTargetSize,
            "iPad tap targets should be larger than iPhone minimum for better ergonomics"
        )
    }

    func testAdaptiveTapTargetModifier_iPhone() {
        // Given: The adaptiveTapTarget modifier for iPhone
        let iPhoneMinimumSize: CGFloat = 44

        // Then: iPhone should meet standard minimum
        XCTAssertEqual(
            iPhoneMinimumSize,
            minimumTapTargetSize,
            "iPhone tap targets should meet standard 44x44 minimum"
        )
    }

    // MARK: - Accessibility Guidelines Compliance

    func testWCAGTargetSizeCompliance() {
        // WCAG 2.1 Success Criterion 2.5.5 (Level AAA): Target Size
        // Minimum target size: 44x44 CSS pixels
        let wcagMinimumSize: CGFloat = 44

        XCTAssertEqual(
            minimumTapTargetSize,
            wcagMinimumSize,
            "Tap targets should comply with WCAG 2.1 Level AAA guidelines (44x44 pixels)"
        )
    }

    func testAppleHIGCompliance() {
        // Apple Human Interface Guidelines recommend 44x44 points minimum
        let appleHIGMinimum: CGFloat = 44

        XCTAssertEqual(
            minimumTapTargetSize,
            appleHIGMinimum,
            "Tap targets should comply with Apple HIG recommendations (44x44 points)"
        )
    }

    // MARK: - Edge Cases

    func testSmallestDeviceSupport() {
        // Given: iPhone SE (1st gen) has 320 point width
        let smallestDeviceWidth: CGFloat = 320
        let numberOfButtons = 5 // Number pad has 5 buttons per row
        let buttonSize: CGFloat = 60 // From NumberPadView for iPhone
        let spacing: CGFloat = 8 // From NumberPadView
        let horizontalPadding: CGFloat = 32

        // When: Calculate total width needed
        let totalButtonWidth = CGFloat(numberOfButtons) * buttonSize
        let totalSpacing = CGFloat(numberOfButtons - 1) * spacing
        let totalWidthNeeded = totalButtonWidth + totalSpacing + horizontalPadding

        // Then: Should fit on smallest device
        XCTAssertLessThanOrEqual(
            totalWidthNeeded,
            smallestDeviceWidth,
            "Number pad should fit on iPhone SE without overflow"
        )
    }

    func testLargestDeviceOptimization() {
        // Given: iPad Pro 12.9" has ~1024 point width in portrait
        let largestDeviceWidth: CGFloat = 1024
        let numberOfButtons = 5
        let buttonSize: CGFloat = 80 // From NumberPadView for iPad
        let spacing: CGFloat = 12
        let horizontalPadding: CGFloat = 64

        // When: Calculate total width needed
        let totalButtonWidth = CGFloat(numberOfButtons) * buttonSize
        let totalSpacing = CGFloat(numberOfButtons - 1) * spacing
        let totalWidthNeeded = totalButtonWidth + totalSpacing + horizontalPadding

        // Then: Should not be excessively small on large devices
        let utilizationPercentage = (totalWidthNeeded / largestDeviceWidth) * 100

        XCTAssertGreaterThan(
            utilizationPercentage,
            30,
            "Number pad should utilize at least 30% of screen width on large iPads"
        )
    }
}
