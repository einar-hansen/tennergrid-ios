import SwiftUI

/// A pause menu view displayed when the game is paused
/// Provides options to resume, restart, start a new game, access settings, or quit
struct PauseMenuView: View {
    // MARK: - Properties

    /// Callback when resume is tapped
    let onResume: () -> Void

    /// Callback when restart is tapped (confirmed)
    let onRestart: () -> Void

    /// Callback when new game is tapped (confirmed)
    let onNewGame: () -> Void

    /// Callback when settings is tapped
    let onSettings: () -> Void

    /// Callback when quit is tapped (confirmed)
    let onQuit: () -> Void

    // MARK: - State

    /// Whether to show the restart confirmation alert
    @State private var showingRestartConfirmation = false

    /// Whether to show the new game confirmation alert
    @State private var showingNewGameConfirmation = false

    /// Whether to show the quit confirmation alert
    @State private var showingQuitConfirmation = false

    /// Animation state for menu appearance
    @State private var isAnimated = false

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundBlur
            menuContent
        }
        .alert("Restart Game?", isPresented: $showingRestartConfirmation, actions: restartAlertActions) {
            Text("This will restart the current puzzle. Your progress will be lost.")
        }
        .alert("Start New Game?", isPresented: $showingNewGameConfirmation, actions: newGameAlertActions) {
            Text("This will start a new puzzle. Your current game will be lost.")
        }
        .alert("Quit Game?", isPresented: $showingQuitConfirmation, actions: quitAlertActions) {
            Text("Are you sure you want to quit? Your progress will be lost.")
        }
    }

    // MARK: - Subviews

    /// Semi-transparent background with blur
    private var backgroundBlur: some View {
        Color.themeOverlayBackground
            .ignoresSafeArea()
            .blur(radius: 2)
    }

    /// Main menu content container
    private var menuContent: some View {
        VStack(spacing: 0) {
            menuHeader
                .padding(.top, 24)
                .padding(.bottom, 32)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : -20)

            menuButtons
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 40)
        .scaleEffect(isAnimated ? 1 : 0.9)
        .opacity(isAnimated ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isAnimated = true
            }
        }
    }

    /// The header section with pause icon and title
    private var menuHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue.gradient)

            Text("Game Paused")
                .font(.system(size: 28, weight: .bold, design: .rounded))
        }
    }

    /// All menu buttons in a vertical stack
    private var menuButtons: some View {
        VStack(spacing: 16) {
            menuButton(
                title: "Resume",
                icon: "play.fill",
                color: .blue,
                action: onResume
            )
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.1), value: isAnimated)

            menuButton(
                title: "Restart",
                icon: "arrow.clockwise",
                color: .orange,
                action: { showingRestartConfirmation = true }
            )
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.15), value: isAnimated)

            menuButton(
                title: "New Game",
                icon: "plus.circle.fill",
                color: .green,
                action: { showingNewGameConfirmation = true }
            )
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.2), value: isAnimated)

            menuButton(
                title: "Settings",
                icon: "gearshape.fill",
                color: .gray,
                action: handleSettings
            )
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.25), value: isAnimated)

            menuButton(
                title: "Quit",
                icon: "xmark.circle.fill",
                color: .red,
                action: { showingQuitConfirmation = true }
            )
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.3), value: isAnimated)
        }
    }

    /// Creates a menu button with icon and title
    /// - Parameters:
    ///   - title: The button title text
    ///   - icon: The SF Symbol name for the icon
    ///   - color: The button's color theme
    ///   - action: The action to perform when tapped
    /// - Returns: A styled menu button view
    private func menuButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.gradient)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(menuButtonHint(for: title))
    }

    // MARK: - Accessibility

    /// Accessibility hint for menu buttons
    /// - Parameter title: The button title
    /// - Returns: Hint describing what the button does
    private func menuButtonHint(for title: String) -> String {
        switch title {
        case "Resume":
            "Double tap to resume the game"
        case "Restart":
            "Double tap to restart the current puzzle from the beginning"
        case "New Game":
            "Double tap to start a new puzzle with different difficulty"
        case "Settings":
            "Double tap to access game settings"
        case "Quit":
            "Double tap to quit and return to the home screen"
        default:
            "Double tap to activate"
        }
    }

    /// Custom button style with scale animation on press
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }

    // MARK: - Alert Actions

    /// Actions for the restart confirmation alert
    @ViewBuilder
    private func restartAlertActions() -> some View {
        Button("Cancel", role: .cancel) {}
        Button("Restart", role: .destructive, action: onRestart)
    }

    /// Actions for the new game confirmation alert
    @ViewBuilder
    private func newGameAlertActions() -> some View {
        Button("Cancel", role: .cancel) {}
        Button("New Game", role: .destructive, action: onNewGame)
    }

    /// Actions for the quit confirmation alert
    @ViewBuilder
    private func quitAlertActions() -> some View {
        Button("Cancel", role: .cancel) {}
        Button("Quit", role: .destructive, action: onQuit)
    }

    // MARK: - Actions

    /// Handles the settings button tap
    /// Resumes the game first, then shows settings
    private func handleSettings() {
        onResume()
        onSettings()
    }
}

// MARK: - Previews

#Preview("Pause Menu") {
    ZStack {
        // Mock game background
        Color.themeBackground
            .ignoresSafeArea()

        PauseMenuView(
            onResume: {},
            onRestart: {},
            onNewGame: {},
            onSettings: {},
            onQuit: {}
        )
    }
}

#Preview("Pause Menu - Dark Mode") {
    ZStack {
        Color.themeBackground
            .ignoresSafeArea()

        PauseMenuView(
            onResume: {},
            onRestart: {},
            onNewGame: {},
            onSettings: {},
            onQuit: {}
        )
    }
    .preferredColorScheme(.dark)
}
