import SwiftUI

/// Extension providing Dynamic Type support for consistent, scalable fonts throughout the app
extension Font {
    // MARK: - App Font Styles

    /// App title font - scales with Dynamic Type
    static var appTitle: Font {
        .scalableSystem(.largeTitle, design: .rounded, weight: .bold)
    }

    /// App tagline font - scales with Dynamic Type
    static var appTagline: Font {
        .scalableSystem(.subheadline, design: .rounded, weight: .medium)
    }

    /// Section header font - scales with Dynamic Type
    static var sectionHeader: Font {
        .scalableSystem(.title2, design: .rounded, weight: .semibold)
    }

    /// Card title font - scales with Dynamic Type
    static var cardTitle: Font {
        .scalableSystem(.title3, design: .rounded, weight: .semibold)
    }

    /// Body text font - scales with Dynamic Type
    static var bodyText: Font {
        .scalableSystem(.body, design: .default, weight: .regular)
    }

    /// Secondary text font - scales with Dynamic Type
    static var secondaryText: Font {
        .scalableSystem(.subheadline, design: .default, weight: .regular)
    }

    /// Caption text font - scales with Dynamic Type
    static var captionText: Font {
        .scalableSystem(.caption, design: .default, weight: .regular)
    }

    /// Button text font - scales with Dynamic Type
    static var buttonText: Font {
        .scalableSystem(.body, design: .rounded, weight: .semibold)
    }

    /// Large button text font - scales with Dynamic Type
    static var largeButtonText: Font {
        .scalableSystem(.title3, design: .rounded, weight: .semibold)
    }

    /// Badge text font - scales with Dynamic Type
    static var badgeText: Font {
        .scalableSystem(.caption2, design: .default, weight: .bold)
    }

    /// Timer text font - scales with Dynamic Type
    static var timerText: Font {
        .scalableSystem(.title3, design: .monospaced, weight: .semibold)
    }

    /// Countdown timer font - scales with Dynamic Type
    static var countdownText: Font {
        .scalableSystem(.title2, design: .monospaced, weight: .bold)
    }

    // MARK: - Game-Specific Fonts

    /// Number pad button font - scales with Dynamic Type
    static var numberPadButton: Font {
        .scalableSystem(.title2, design: .rounded, weight: .medium)
    }

    /// Toolbar button label font - scales with Dynamic Type
    static var toolbarLabel: Font {
        .scalableSystem(.caption, design: .default, weight: .medium)
    }

    /// Difficulty label font - scales with Dynamic Type
    static var difficultyLabel: Font {
        .scalableSystem(.subheadline, design: .default, weight: .medium)
    }

    /// Column sum font - scales with Dynamic Type
    static var columnSum: Font {
        .scalableSystem(.caption, design: .monospaced, weight: .medium)
    }

    // MARK: - Fixed Size Fonts for Special Cases

    /// Cell number font - uses fixed relative sizing based on cell size
    /// This should not use Dynamic Type as it needs to fit within cell constraints
    /// - Parameter cellSize: The size of the cell
    /// - Returns: Font sized relative to cell
    static func cellNumber(cellSize: CGFloat) -> Font {
        Font.system(size: cellSize * 0.48, weight: .regular, design: .rounded)
    }

    /// Cell number font for initial (pre-filled) values - bold variant
    /// - Parameter cellSize: The size of the cell
    /// - Returns: Font sized relative to cell
    static func cellNumberBold(cellSize: CGFloat) -> Font {
        Font.system(size: cellSize * 0.48, weight: .bold, design: .rounded)
    }

    /// Pencil mark font - uses fixed relative sizing based on cell size
    /// - Parameter cellSize: The size of the cell
    /// - Returns: Font sized relative to cell
    static func pencilMark(cellSize: CGFloat) -> Font {
        Font.system(size: cellSize * 0.20, weight: .light, design: .rounded)
    }

    // MARK: - System Font Helper

    /// Creates a system font with design and weight that scales with Dynamic Type
    /// - Parameters:
    ///   - style: The text style (e.g., .body, .title, etc.)
    ///   - design: The font design (default, rounded, monospaced, serif)
    ///   - weight: The font weight
    /// - Returns: A font that scales with Dynamic Type
    private static func scalableSystem(
        _ style: Font.TextStyle,
        design: Font.Design = .default,
        weight: Font.Weight = .regular
    ) -> Font {
        Font.system(style, design: design).weight(weight)
    }
}

// MARK: - View Extension for Dynamic Type

extension View {
    /// Limits the Dynamic Type scaling to a specific range
    /// Useful for preventing text from becoming too large or too small
    /// - Parameters:
    ///   - category: The maximum Dynamic Type category to support
    /// - Returns: A view with limited Dynamic Type scaling
    func limitDynamicTypeSize(to category: DynamicTypeSize) -> some View {
        dynamicTypeSize(...category)
    }

    /// Limits the Dynamic Type scaling to a range
    /// - Parameters:
    ///   - range: The range of Dynamic Type sizes to support
    /// - Returns: A view with limited Dynamic Type scaling
    func limitDynamicTypeSize(to range: ClosedRange<DynamicTypeSize>) -> some View {
        dynamicTypeSize(range)
    }
}
