import SwiftUI

/// The main home screen of the Tenner Grid app
/// Displays app branding, game options, and navigation to various features
// swiftlint:disable:next swiftui_view_body
struct HomeView: View {
    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                appBranding
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                Spacer()

                welcomeMessage
                    .padding(.bottom, 20)

                Spacer()
            }
        }
    }

    // MARK: - Subviews

    /// Background gradient for the home screen
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.3),
                Color.green.opacity(0.2),
                Color.orange.opacity(0.1),
                Color.clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    /// App branding section with title and icon
    private var appBranding: some View {
        VStack(spacing: 16) {
            appIcon
            appTitle
            appTagline
        }
    }

    /// App icon display
    private var appIcon: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue,
                            Color.green,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)

            // Grid icon representation
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
    }

    /// App title
    private var appTitle: some View {
        Text("Tenner Grid")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.blue,
                        Color.green,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    /// App tagline
    private var appTagline: some View {
        Text("The Ultimate Number Puzzle")
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
    }

    /// Welcome message at the bottom
    private var welcomeMessage: some View {
        VStack(spacing: 8) {
            Text("Welcome!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Text("More features coming soon")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews

#Preview("Home View - Light Mode") {
    HomeView()
}

#Preview("Home View - Dark Mode") {
    HomeView()
        .preferredColorScheme(.dark)
}

#Preview("Home View - Compact") {
    HomeView()
}

#Preview("Home View - Large") {
    HomeView()
}
