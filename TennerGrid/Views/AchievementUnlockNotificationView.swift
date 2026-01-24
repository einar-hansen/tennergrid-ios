import Foundation
import SwiftUI

/// A notification view that displays when an achievement is unlocked
/// Features a slide-in animation with confetti-like particles and celebration effects
// swiftlint:disable:next swiftui_view_body
struct AchievementUnlockNotificationView: View {
    // MARK: - Properties

    /// The achievement that was unlocked
    let achievement: Achievement

    /// Whether the notification is currently showing
    @Binding var isShowing: Bool

    /// Callback when the notification is dismissed
    var onDismiss: (() -> Void)?

    /// Animation state for the notification
    @State private var offset: CGFloat = -200
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var showConfetti = false

    /// Auto-dismiss timer
    private let autoDismissDuration: TimeInterval = 4.0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            notificationCard
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer()
        }
        .background(
            ZStack {
                if showConfetti {
                    confettiOverlay
                }
            }
        )
        .offset(y: offset)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            presentNotification()
        }
    }

    // MARK: - Notification Card

    private var notificationCard: some View {
        HStack(spacing: 16) {
            achievementIcon

            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked!")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(achievement.displayTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)

                    Text("+\(achievement.points) points")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            dismissButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            achievement.category.color,
                            achievement.category.color.opacity(0.6),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .onTapGesture {
            dismissNotification()
        }
    }

    // MARK: - Achievement Icon

    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            achievement.category.color,
                            achievement.category.color.opacity(0.7),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .shadow(color: achievement.category.color.opacity(0.3), radius: 8, x: 0, y: 4)

            Image(systemName: achievement.displayIconName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(iconRotation))
        }
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button {
            dismissNotification()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color(.systemGray5))
                )
        }
    }

    // MARK: - Confetti Overlay

    private var confettiOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0 ..< 30, id: \.self) { index in
                    AchievementConfettiParticle(
                        color: confettiColor(for: index),
                        containerWidth: geometry.size.width,
                        containerHeight: geometry.size.height
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helper Methods

    /// Gets a random color for confetti particles
    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .orange, .yellow, .green, .red,
            achievement.category.color,
        ]
        return colors[index % colors.count]
    }

    /// Presents the notification with animation
    private func presentNotification() {
        // Start with offset and fade in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            offset = 0
            opacity = 1
            scale = 1.0
        }

        // Icon celebration rotation
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 10).delay(0.2)) {
            iconRotation = 360
        }

        // Show confetti after slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showConfetti = true
            }
        }

        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDuration) {
            dismissNotification()
        }
    }

    /// Dismisses the notification with animation
    private func dismissNotification() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -200
            opacity = 0
            scale = 0.8
        }

        // Call onDismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
            onDismiss?()
        }
    }
}

// MARK: - Confetti Particle

/// A single confetti particle with random animation for achievement unlocks
private struct AchievementConfettiParticle: View {
    let color: Color
    let containerWidth: CGFloat
    let containerHeight: CGFloat

    @State private var xPosition: CGFloat
    @State private var yPosition: CGFloat = -20
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    private let size: CGFloat
    private let duration: Double
    private let delay: Double

    init(color: Color, containerWidth: CGFloat, containerHeight: CGFloat) {
        self.color = color
        self.containerWidth = containerWidth
        self.containerHeight = containerHeight

        // Random initial horizontal position
        _xPosition = State(initialValue: CGFloat.random(in: 0 ... containerWidth))

        // Random size
        size = CGFloat.random(in: 4 ... 12)

        // Random animation duration and delay
        duration = Double.random(in: 2.0 ... 4.0)
        delay = Double.random(in: 0 ... 0.5)
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(x: xPosition, y: yPosition)
            .onAppear {
                withAnimation(
                    .easeIn(duration: duration)
                        .delay(delay)
                ) {
                    yPosition = containerHeight + 20
                    rotation = Double.random(in: 360 ... 720)
                    opacity = 0
                }
            }
    }
}

// MARK: - Container View

/// Container view that manages multiple achievement notifications
/// Displays them in a queue, showing one at a time
// swiftlint:disable:next swiftui_view_body
struct AchievementUnlockNotificationContainer: View {
    /// The achievements to display
    @Binding var achievements: [Achievement]

    /// Currently displayed achievement
    @State private var currentAchievement: Achievement?

    /// Whether a notification is currently showing
    @State private var isShowingNotification = false

    var body: some View {
        ZStack {
            if let achievement = currentAchievement, isShowingNotification {
                AchievementUnlockNotificationView(
                    achievement: achievement,
                    isShowing: $isShowingNotification,
                    onDismiss: {
                        currentAchievement = nil
                        showNextAchievement()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(1000)
            }
        }
        .onChange(of: achievements) { _ in
            if !achievements.isEmpty, !isShowingNotification {
                showNextAchievement()
            }
        }
        .onAppear {
            if !achievements.isEmpty, !isShowingNotification {
                showNextAchievement()
            }
        }
    }

    /// Shows the next achievement in the queue
    private func showNextAchievement() {
        guard !achievements.isEmpty else { return }

        // Small delay between notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentAchievement = achievements.removeFirst()
            isShowingNotification = true
        }
    }
}

// MARK: - Previews

#Preview("Single Achievement") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        AchievementUnlockNotificationView(
            achievement: Achievement.allAchievements[0],
            isShowing: .constant(true)
        )
    }
}

#Preview("Multiple Achievements") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        AchievementUnlockNotificationContainer(
            achievements: .constant([
                Achievement.allAchievements[0],
                Achievement.allAchievements[1],
                Achievement.allAchievements[2],
            ])
        )
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        AchievementUnlockNotificationView(
            achievement: Achievement.allAchievements[0],
            isShowing: .constant(true)
        )
    }
    .preferredColorScheme(.dark)
}
