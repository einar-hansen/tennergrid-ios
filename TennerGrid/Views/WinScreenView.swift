import SwiftUI

/// A win screen view displayed when the puzzle is successfully completed
/// Shows game statistics and provides options for next actions
// swiftlint:disable:next swiftui_view_body
struct WinScreenView: View {
    // MARK: - Properties

    /// The difficulty of the completed puzzle
    let difficulty: Difficulty

    /// Total time taken to complete the puzzle (in seconds)
    let elapsedTime: TimeInterval

    /// Number of hints used during the game
    let hintsUsed: Int

    /// Number of errors made during the game
    let errorCount: Int

    /// Callback when new game is tapped
    let onNewGame: () -> Void

    /// Callback when change difficulty is tapped
    let onChangeDifficulty: () -> Void

    /// Callback when home is tapped
    let onHome: () -> Void

    // MARK: - State

    /// Animation state for celebration
    @State private var animationAmount: CGFloat = 0

    /// Confetti particles for celebration effect
    @State private var confettiParticles: [ConfettiParticle] = []

    /// Trophy bounce animation state
    @State private var trophyBounce: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient
            winContent
            confettiOverlay
        }
        .onAppear(perform: startAnimation)
    }

    // MARK: - Subviews

    /// Background gradient with celebration colors
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                difficulty.color.opacity(0.3),
                difficulty.color.opacity(0.1),
                Color.clear,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// Main win content container
    private var winContent: some View {
        VStack(spacing: 0) {
            celebrationHeader
                .padding(.top, 40)
                .padding(.bottom, 32)

            statisticsSection
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

            actionButtons
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 40)
    }

    /// The celebration header with trophy icon and congratulations message
    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            trophyIcon

            Text("Congratulations!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .opacity(animationAmount)
                .animation(.easeIn(duration: 0.4).delay(0.3), value: animationAmount)

            Text("Puzzle Completed")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .opacity(animationAmount)
                .animation(.easeIn(duration: 0.4).delay(0.4), value: animationAmount)
        }
    }

    /// Animated trophy icon
    private var trophyIcon: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: 72))
            .foregroundStyle(difficulty.color.gradient)
            .scaleEffect(animationAmount * trophyBounce)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)
                    .delay(0.1),
                value: animationAmount
            )
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                value: trophyBounce
            )
    }

    /// Statistics section showing game performance
    private var statisticsSection: some View {
        VStack(spacing: 20) {
            statisticRows
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(statisticsBackground)
        .opacity(animationAmount)
        .animation(.easeIn(duration: 0.4).delay(0.5), value: animationAmount)
    }

    /// Statistics rows
    private var statisticRows: some View {
        Group {
            difficultyRow
            timeRow
            hintsRow
            errorsRow
        }
    }

    /// Difficulty statistic row
    private var difficultyRow: some View {
        statisticRow(
            label: "Difficulty",
            value: difficulty.displayName,
            icon: "chart.bar.fill",
            color: difficulty.color
        )
    }

    /// Time statistic row
    private var timeRow: some View {
        statisticRow(
            label: "Time",
            value: formattedTime,
            icon: "clock.fill",
            color: .blue
        )
    }

    /// Hints statistic row
    private var hintsRow: some View {
        statisticRow(
            label: "Hints Used",
            value: "\(hintsUsed)",
            icon: "lightbulb.fill",
            color: .orange
        )
    }

    /// Errors statistic row
    private var errorsRow: some View {
        statisticRow(
            label: "Errors",
            value: "\(errorCount)",
            icon: "exclamationmark.triangle.fill",
            color: errorCount > 0 ? .red : .green
        )
    }

    /// Background for statistics section
    private var statisticsBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground).opacity(0.5))
    }

    /// Creates a statistic row with label, value, icon, and color
    /// - Parameters:
    ///   - label: The statistic label
    ///   - value: The statistic value
    ///   - icon: The SF Symbol name for the icon
    ///   - color: The icon color
    /// - Returns: A styled statistic row view
    private func statisticRow(
        label: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color.gradient)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }

    /// Action buttons for next steps
    private var actionButtons: some View {
        VStack(spacing: 16) {
            newGameButton
            changeDifficultyButton
            homeButton
        }
    }

    /// New game button
    private var newGameButton: some View {
        actionButton(
            title: "New Game",
            icon: "plus.circle.fill",
            color: .green,
            action: onNewGame
        )
        .opacity(animationAmount)
        .animation(.easeIn(duration: 0.4).delay(0.6), value: animationAmount)
    }

    /// Change difficulty button
    private var changeDifficultyButton: some View {
        actionButton(
            title: "Change Difficulty",
            icon: "slider.horizontal.3",
            color: .blue,
            action: onChangeDifficulty
        )
        .opacity(animationAmount)
        .animation(.easeIn(duration: 0.4).delay(0.7), value: animationAmount)
    }

    /// Home button
    private var homeButton: some View {
        actionButton(
            title: "Home",
            icon: "house.fill",
            color: .gray,
            action: onHome
        )
        .opacity(animationAmount)
        .animation(.easeIn(duration: 0.4).delay(0.8), value: animationAmount)
    }

    /// Creates an action button with icon and title
    /// - Parameters:
    ///   - title: The button title text
    ///   - icon: The SF Symbol name for the icon
    ///   - color: The button's color theme
    ///   - action: The action to perform when tapped
    /// - Returns: A styled action button view
    private func actionButton(
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
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(winScreenButtonHint(for: title))
    }

    // MARK: - Accessibility

    /// Accessibility hint for action buttons
    /// - Parameter title: The button title
    /// - Returns: Hint describing what the button does
    private func winScreenButtonHint(for title: String) -> String {
        switch title {
        case "New Game":
            "Double tap to start a new puzzle with the same difficulty"
        case "Change Difficulty":
            "Double tap to select a different difficulty level"
        case "Home":
            "Double tap to return to the home screen"
        default:
            "Double tap to activate"
        }
    }

    // MARK: - Computed Properties

    /// Formatted time string (MM:SS)
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Confetti

    /// Confetti overlay for celebration effect
    private var confettiOverlay: some View {
        ZStack {
            ForEach(confettiParticles) { particle in
                ConfettiView(particle: particle)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Animation

    /// Starts the celebration animation
    private func startAnimation() {
        animationAmount = 1.0
        generateConfetti()

        // Start trophy bounce after initial animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            trophyBounce = 1.05
        }
    }

    /// Generates confetti particles for celebration
    private func generateConfetti() {
        let particleCount = 50
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

        confettiParticles = (0 ..< particleCount).map { index in
            ConfettiParticle(
                id: index,
                color: colors.randomElement() ?? .blue,
                startX: CGFloat.random(in: 0 ... 1),
                delay: Double.random(in: 0 ... 0.5),
                duration: Double.random(in: 2 ... 4),
                angle: Double.random(in: 0 ... 360)
            )
        }
    }
}

// MARK: - Confetti Particle Model

/// Represents a single confetti particle with animation properties
struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let delay: Double
    let duration: Double
    let angle: Double
}

// MARK: - Confetti View

/// A view that renders and animates a single confetti particle
// swiftlint:disable:next swiftui_view_body
struct ConfettiView: View {
    let particle: ConfettiParticle

    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(particle.color)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(isAnimating ? particle.angle + 360 : particle.angle))
                .position(
                    x: geometry.size.width * particle.startX,
                    y: isAnimating ? geometry.size.height + 50 : -50
                )
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(
                        .linear(duration: particle.duration)
                            .delay(particle.delay)
                    ) {
                        isAnimating = true
                    }
                }
        }
    }
}

// MARK: - Previews

#Preview("Win Screen - Easy") {
    WinScreenView(
        difficulty: .easy,
        elapsedTime: 180, // 3 minutes
        hintsUsed: 2,
        errorCount: 0,
        onNewGame: {},
        onChangeDifficulty: {},
        onHome: {}
    )
}

#Preview("Win Screen - Medium") {
    WinScreenView(
        difficulty: .medium,
        elapsedTime: 420, // 7 minutes
        hintsUsed: 5,
        errorCount: 3,
        onNewGame: {},
        onChangeDifficulty: {},
        onHome: {}
    )
}

#Preview("Win Screen - Hard") {
    WinScreenView(
        difficulty: .hard,
        elapsedTime: 900, // 15 minutes
        hintsUsed: 0,
        errorCount: 1,
        onNewGame: {},
        onChangeDifficulty: {},
        onHome: {}
    )
}

#Preview("Win Screen - Dark Mode") {
    WinScreenView(
        difficulty: .medium,
        elapsedTime: 300,
        hintsUsed: 3,
        errorCount: 2,
        onNewGame: {},
        onChangeDifficulty: {},
        onHome: {}
    )
    .preferredColorScheme(.dark)
}
