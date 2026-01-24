import SwiftUI

/// Helper views and modifiers for testing accessibility features
/// Specifically focused on Dynamic Type testing with largest text sizes

// MARK: - Dynamic Type Testing Environment

struct DynamicTypeTestEnvironment: ViewModifier {
    let sizeCategory: DynamicTypeSize

    func body(content: Content) -> some View {
        content
            .environment(\.dynamicTypeSize, sizeCategory)
    }
}

extension View {
    /// Applies a specific Dynamic Type size for testing purposes
    /// - Parameter sizeCategory: The Dynamic Type size to apply
    /// - Returns: View with applied Dynamic Type size
    func testDynamicTypeSize(_ sizeCategory: DynamicTypeSize) -> some View {
        modifier(DynamicTypeTestEnvironment(sizeCategory: sizeCategory))
    }
}

// MARK: - Accessibility Testing Sizes

/// Common Dynamic Type sizes used for accessibility testing
enum AccessibilityTestSize {
    /// Extra Small - Minimum size (below default)
    static let extraSmall: DynamicTypeSize = .xSmall

    /// Default - System default size (using 'large' which is the iOS default)
    static let systemDefault: DynamicTypeSize = .large

    /// Extra Large - First accessibility size
    static let extraLarge: DynamicTypeSize = .xLarge

    /// Extra Extra Large - Moderate accessibility size
    static let extraExtraLarge: DynamicTypeSize = .xxLarge

    /// Extra Extra Extra Large - Large accessibility size
    static let extraExtraExtraLarge: DynamicTypeSize = .xxxLarge

    /// Accessibility Medium - First dedicated accessibility category
    static let accessibilityMedium: DynamicTypeSize = .accessibility1

    /// Accessibility Large - Large accessibility category
    static let accessibilityLarge: DynamicTypeSize = .accessibility2

    /// Accessibility Extra Large - Very large accessibility category
    static let accessibilityExtraLarge: DynamicTypeSize = .accessibility3

    /// Accessibility Extra Extra Large - Extremely large accessibility category
    static let accessibilityExtraExtraLarge: DynamicTypeSize = .accessibility4

    /// Accessibility Extra Extra Extra Large - Maximum size
    static let accessibilityMaximum: DynamicTypeSize = .accessibility5

    /// All test sizes for comprehensive testing
    static let allSizes: [DynamicTypeSize] = [
        extraSmall,
        systemDefault,
        extraLarge,
        extraExtraLarge,
        extraExtraExtraLarge,
        accessibilityMedium,
        accessibilityLarge,
        accessibilityExtraLarge,
        accessibilityExtraExtraLarge,
        accessibilityMaximum,
    ]

    /// Critical test sizes (default, large, and maximum) for quick testing
    static let criticalSizes: [DynamicTypeSize] = [
        systemDefault,
        extraExtraExtraLarge,
        accessibilityMaximum,
    ]
}

// MARK: - Accessibility Test Scenarios

/// A view that displays a component at multiple Dynamic Type sizes for visual comparison
struct DynamicTypeSizeComparison<Content: View>: View {
    let title: String
    let content: () -> Content
    let sizes: [DynamicTypeSize]

    init(
        title: String,
        sizes: [DynamicTypeSize] = AccessibilityTestSize.criticalSizes,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.sizes = sizes
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(Array(sizes.enumerated()), id: \.offset) { _, size in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sizeLabel(for: size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        content()
                            .testDynamicTypeSize(size)
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.vertical)
        }
    }

    private func sizeLabel(for size: DynamicTypeSize) -> String {
        switch size {
        case .xSmall: "Extra Small (xSmall)"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large (Default)"
        case .xLarge: "Extra Large (xLarge)"
        case .xxLarge: "XX Large (xxLarge)"
        case .xxxLarge: "XXX Large (xxxLarge)"
        case .accessibility1: "Accessibility Medium (accessibility1)"
        case .accessibility2: "Accessibility Large (accessibility2)"
        case .accessibility3: "Accessibility Extra Large (accessibility3)"
        case .accessibility4: "Accessibility XX Large (accessibility4)"
        case .accessibility5: "Accessibility Maximum (accessibility5)"
        default: "Unknown Size"
        }
    }
}

// MARK: - Recommended Dynamic Type Constraints

extension View {
    /// Applies recommended Dynamic Type size limits for game UI elements
    /// Game grid and number pad should not scale beyond xxxLarge to maintain playability
    /// - Returns: View with constrained Dynamic Type scaling
    func gameElementDynamicTypeLimit() -> some View {
        dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// Applies recommended Dynamic Type size limits for text-heavy content
    /// Text content can scale up to accessibility3 for better readability
    /// - Returns: View with constrained Dynamic Type scaling
    func textContentDynamicTypeLimit() -> some View {
        dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    /// Applies recommended Dynamic Type size limits for navigation elements
    /// Navigation elements should not scale excessively to prevent layout issues
    /// - Returns: View with constrained Dynamic Type scaling
    func navigationElementDynamicTypeLimit() -> some View {
        dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

// MARK: - Testing Documentation

/*
 # Dynamic Type Accessibility Testing Guide

 ## Overview
 This file provides utilities for testing the app with various Dynamic Type sizes,
 especially the largest accessibility sizes (accessibility3, accessibility4, accessibility5).

 ## Testing Approach

 ### 1. Automated Testing with Previews
 Use `DynamicTypeSizeComparison` to create SwiftUI previews that show components
 at multiple sizes side-by-side:

 ```swift
 #Preview("Dynamic Type Test") {
     DynamicTypeSizeComparison(title: "Game Header Test") {
         GameHeaderView(viewModel: testViewModel, onPause: {}, onSettings: {})
     }
 }
 ```

 ### 2. Manual Testing on Device
 To test with actual Dynamic Type settings:

 1. Open Settings app on iOS device
 2. Go to Accessibility > Display & Text Size > Larger Text
 3. Enable "Larger Accessibility Sizes"
 4. Drag slider to maximum (accessibility5)
 5. Open the app and test all screens

 ### 3. Critical Test Scenarios

 **Game View:**
 - ✓ Grid remains visible and usable (cells may need to shrink slightly)
 - ✓ Number pad buttons remain tappable (minimum 44pt tap targets)
 - ✓ Column sums are readable
 - ✓ Timer and difficulty labels don't overflow

 **Home View:**
 - ✓ Cards resize appropriately
 - ✓ Text doesn't truncate unexpectedly
 - ✓ Buttons remain accessible

 **Settings & Profile:**
 - ✓ List items have adequate spacing
 - ✓ Toggle switches remain aligned
 - ✓ Long text wraps properly

 **Pause Menu & Win Screen:**
 - ✓ Modal content fits on screen
 - ✓ Buttons stack vertically if needed
 - ✓ Text is readable and doesn't overlap

 ### 4. Dynamic Type Size Limits

 Some UI elements have maximum size limits to maintain usability:

 - **Game Elements** (grid, number pad): Limited to xxxLarge
   - Rationale: Excessive scaling breaks game layout and playability

 - **Text Content** (rules, help): Limited to accessibility3
   - Rationale: Allows large text while preventing extreme overflow

 - **Navigation**: Limited to xxLarge
   - Rationale: Tab bar and navigation must remain compact

 ### 5. Known Constraints

 **Cell View:**
 - Cell numbers use fixed relative sizing (not Dynamic Type)
 - Rationale: Cells must fit in grid; text scales with cell size instead

 **Pencil Marks:**
 - Pencil marks use fixed relative sizing
 - Rationale: Must fit 10 digits in small cell space

 **Column Sums:**
 - Use Dynamic Type with limit to maintain grid alignment

 ## Testing Checklist

 - [ ] Test at default size (large) - baseline
 - [ ] Test at xxxLarge - typical large preference
 - [ ] Test at accessibility1 - first accessibility level
 - [ ] Test at accessibility3 - moderate accessibility
 - [ ] Test at accessibility5 - maximum accessibility

 For each size:
 - [ ] Launch app and navigate through onboarding
 - [ ] Play a complete game (start to finish)
 - [ ] Access all tabs (Main, Daily, Me)
 - [ ] Open settings and change preferences
 - [ ] View statistics and achievements
 - [ ] Pause and resume game
 - [ ] Complete a puzzle and see win screen

 ## Issues to Watch For

 1. **Text Truncation**: Text cuts off with "..." unexpectedly
 2. **Overlapping Elements**: UI elements overlap each other
 3. **Off-screen Content**: Content extends beyond screen bounds
 4. **Broken Layouts**: Spacing or alignment breaks down
 5. **Unreadable Text**: Text too small despite Dynamic Type
 6. **Touch Target Size**: Buttons smaller than 44x44 points
 7. **Scroll Issues**: Content not scrollable when it should be

 ## Recommendations

 - Use `.lineLimit(nil)` or `.lineLimit(2...4)` for text that should wrap
 - Use `ScrollView` for content that might overflow at large sizes
 - Use `.minimumScaleFactor()` sparingly and only for fixed-size containers
 - Prefer VStack over HStack for accessibility (vertical layouts scale better)
 - Test both portrait and landscape orientations
 - Test on smallest (iPhone SE) and largest (iPad Pro) devices
 */
