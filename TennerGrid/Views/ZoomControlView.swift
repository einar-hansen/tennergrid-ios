import SwiftUI

/// A view providing zoom controls (zoom in, zoom out, reset)
/// Appears as a floating control overlay in the game view
struct ZoomControlView: View {
    // MARK: - Properties

    /// Action to zoom in
    let onZoomIn: () -> Void

    /// Action to zoom out
    let onZoomOut: () -> Void

    /// Action to reset zoom
    let onResetZoom: () -> Void

    /// Current zoom level for display
    let currentZoom: CGFloat

    // MARK: - Environment

    /// Size class to detect iPad vs iPhone
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // MARK: - Constants

    /// Check if running on iPad based on size classes
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    /// Button size scales with device
    private var buttonSize: CGFloat {
        isIPad ? 44 : 36
    }

    /// Icon size scales with device
    private var iconSize: CGFloat {
        isIPad ? 20 : 16
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Zoom in button
            zoomButton(
                icon: "plus.magnifyingglass",
                label: "Zoom In",
                isEnabled: currentZoom < 2.0,
                action: onZoomIn
            )

            // Current zoom level indicator
            Text("\(Int(currentZoom * 100))%")
                .font(.system(size: isIPad ? 12 : 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: buttonSize)

            // Zoom out button
            zoomButton(
                icon: "minus.magnifyingglass",
                label: "Zoom Out",
                isEnabled: currentZoom > 0.5,
                action: onZoomOut
            )

            // Reset button (1:1)
            zoomButton(
                icon: "1.magnifyingglass",
                label: "Reset Zoom",
                isEnabled: abs(currentZoom - 1.0) > 0.01,
                action: onResetZoom
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Subviews

    /// Individual zoom button
    /// - Parameters:
    ///   - icon: SF Symbol icon name
    ///   - label: Accessibility label
    ///   - isEnabled: Whether the button is enabled
    ///   - action: Action to perform when tapped
    /// - Returns: Button view
    private func zoomButton(
        icon: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(isEnabled ? .primary : .secondary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isEnabled ? [] : .isButton)
    }
}

// MARK: - Previews

#Preview("Zoom Controls - Normal") {
    ZoomControlView(
        onZoomIn: {},
        onZoomOut: {},
        onResetZoom: {},
        currentZoom: 1.0
    )
    .padding()
}

#Preview("Zoom Controls - Zoomed In") {
    ZoomControlView(
        onZoomIn: {},
        onZoomOut: {},
        onResetZoom: {},
        currentZoom: 1.75
    )
    .padding()
}

#Preview("Zoom Controls - Zoomed Out") {
    ZoomControlView(
        onZoomIn: {},
        onZoomOut: {},
        onResetZoom: {},
        currentZoom: 0.5
    )
    .padding()
}
