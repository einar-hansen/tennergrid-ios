import SwiftUI

// MARK: - Tap Target Size Extension

extension View {
    /// Ensures the view meets Apple's minimum recommended tap target size of 44x44 points.
    /// This is particularly important for iPad and accessibility.
    ///
    /// - Parameters:
    ///   - size: The minimum size for the tap target. Defaults to 44 points (Apple's HIG recommendation).
    ///   - alignment: The alignment of the content within the expanded frame. Defaults to center.
    /// - Returns: A view with ensured minimum tap target size.
    func minimumTapTarget(
        size: CGFloat = 44,
        alignment: Alignment = .center
    ) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
            .frame(alignment: alignment)
    }
}

// MARK: - iPad-Aware Tap Target Extension

extension View {
    /// Ensures appropriate tap target sizes based on device type (iPad vs iPhone).
    /// iPad gets larger tap targets for better usability on larger screens.
    ///
    /// - Parameters:
    ///   - horizontalSizeClass: The horizontal size class from the environment
    ///   - verticalSizeClass: The vertical size class from the environment
    ///   - iPadSize: The minimum tap target size for iPad. Defaults to 56 points.
    ///   - iPhoneSize: The minimum tap target size for iPhone. Defaults to 44 points.
    ///   - alignment: The alignment of the content within the expanded frame. Defaults to center.
    /// - Returns: A view with device-appropriate tap target size.
    func adaptiveTapTarget(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        iPadSize: CGFloat = 56,
        iPhoneSize: CGFloat = 44,
        alignment: Alignment = .center
    ) -> some View {
        let isIPad = horizontalSizeClass == .regular && verticalSizeClass == .regular
        let targetSize = isIPad ? iPadSize : iPhoneSize

        return frame(minWidth: targetSize, minHeight: targetSize)
            .contentShape(Rectangle())
            .frame(alignment: alignment)
    }
}

// MARK: - Documentation

/*
 Apple Human Interface Guidelines for Tap Targets:

 • Minimum recommended tap target size: 44×44 points
 • On iPad, consider larger targets (48-56 points) for better ergonomics
 • Ensure adequate spacing between tap targets (at least 8 points)
 • For accessibility, larger targets improve usability for users with motor impairments

 Usage Examples:

 ```swift
 // Basic usage - ensures 44x44 minimum
 Button("Tap Me") {
     // action
 }
 .minimumTapTarget()

 // Custom size
 Button("Large Target") {
     // action
 }
 .minimumTapTarget(size: 56)

 // iPad-aware sizing
 @Environment(\.horizontalSizeClass) private var horizontalSizeClass
 @Environment(\.verticalSizeClass) private var verticalSizeClass

 Button("Adaptive") {
     // action
 }
 .adaptiveTapTarget(
     horizontalSizeClass: horizontalSizeClass,
     verticalSizeClass: verticalSizeClass
 )
 ```

 References:
 - Apple HIG: https://developer.apple.com/design/human-interface-guidelines/buttons
 - WCAG 2.1 Success Criterion 2.5.5: Target Size (Level AAA) - 44×44 CSS pixels
 */
