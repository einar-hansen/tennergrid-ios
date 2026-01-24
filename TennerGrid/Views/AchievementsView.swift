import SwiftUI

/// Achievements view displaying all achievements with unlock status
/// Shows locked achievements as grayed out, unlocked achievements with icon and date
/// Displays progress bars for progressive achievements
struct AchievementsView: View {
    // MARK: - Properties

    /// Achievement manager for real-time achievement data
    @ObservedObject private var achievementManager: AchievementManager

    /// Selected category filter (nil = all)
    @State private var selectedCategory: Achievement.AchievementCategory?

    // MARK: - Initialization

    init(achievementManager: AchievementManager = .shared) {
        self.achievementManager = achievementManager
    }

    /// Computed property for accessing current achievements
    private var achievements: [Achievement] {
        achievementManager.achievements
    }

    /// Filtered achievements based on selected category
    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category && $0.isVisible }
        }
        return achievements.filter(\.isVisible)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                progressOverview
                categoryFilter
                achievementsGrid
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Awards")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Progress Overview

    private var progressOverview: some View {
        VStack(spacing: 16) {
            achievementPoints
            achievementProgress
        }
        .padding(.horizontal, 16)
    }

    private var achievementPoints: some View {
        HStack(spacing: 16) {
            pointsCard(
                title: "Points Earned",
                value: "\(achievementManager.totalPointsEarned())",
                icon: "star.fill",
                color: .yellow
            )

            pointsCard(
                title: "Total Points",
                value: "\(achievementManager.totalPossiblePoints())",
                icon: "star.circle.fill",
                color: .orange
            )
        }
    }

    /// Creates a points card with title, value, icon, and color
    /// - Parameters:
    ///   - title: Card title
    ///   - value: Point value
    ///   - icon: SF Symbol name
    ///   - color: Card accent color
    /// - Returns: Points card view
    private func pointsCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var achievementProgress: some View {
        let completionPercentage = achievementManager.completionPercentage()
        let unlockedCount = achievementManager.unlockedAchievements().count
        let totalCount = achievements.count

        return VStack(spacing: 12) {
            progressHeader(unlockedCount: unlockedCount, totalCount: totalCount)
            progressBar(percentage: completionPercentage)
            progressLabel(percentage: completionPercentage)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    /// Creates the progress header
    /// - Parameters:
    ///   - unlockedCount: Number of unlocked achievements
    ///   - totalCount: Total number of achievements
    /// - Returns: Progress header view
    private func progressHeader(unlockedCount: Int, totalCount: Int) -> some View {
        HStack {
            Text("Progress")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Text("\(unlockedCount)/\(totalCount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    /// Creates the progress bar
    /// - Parameter percentage: Completion percentage (0.0-1.0)
    /// - Returns: Progress bar view
    private func progressBar(percentage: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 12)

                // Progress
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * percentage, height: 12)
                    .animation(.easeInOut(duration: 0.3), value: percentage)
            }
        }
        .frame(height: 12)
    }

    /// Creates the progress percentage label
    /// - Parameter percentage: Completion percentage (0.0-1.0)
    /// - Returns: Progress label view
    private func progressLabel(percentage: Double) -> some View {
        Text(String(format: "%.0f%% Complete", percentage * 100))
            .font(.system(size: 12))
            .foregroundColor(.secondary)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryFilterButton(category: nil, label: "All")

                ForEach(Achievement.AchievementCategory.allCases, id: \.self) { category in
                    categoryFilterButton(category: category, label: category.displayName)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// Creates a category filter button
    /// - Parameters:
    ///   - category: Category to filter by (nil for all)
    ///   - label: Button label
    /// - Returns: Category filter button view
    private func categoryFilterButton(category: Achievement.AchievementCategory?, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                if let category {
                    Image(systemName: category.iconName)
                        .font(.system(size: 14))
                } else {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 14))
                }

                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(selectedCategory == category ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                selectedCategory == category
                    ? (category?.color ?? .blue)
                    : Color(.systemGray5)
            )
            .cornerRadius(20)
        }
    }

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            ForEach(filteredAchievements) { achievement in
                achievementCard(achievement)
            }
        }
        .padding(.horizontal, 16)
    }

    /// Creates an achievement card with icon, title, description, and progress
    /// - Parameter achievement: Achievement to display
    /// - Returns: Achievement card view
    private func achievementCard(_ achievement: Achievement) -> some View {
        VStack(spacing: 12) {
            achievementIcon(achievement)
            achievementInfo(achievement)
            achievementCardFooter(achievement)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(achievementCardBackground(achievement))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }

    /// Creates the footer section of the achievement card (progress or unlock date)
    /// - Parameter achievement: Achievement
    /// - Returns: Footer view
    @ViewBuilder
    private func achievementCardFooter(_ achievement: Achievement) -> some View {
        if !achievement.isUnlocked, achievement.targetValue > 1 {
            achievementProgressBar(achievement)
        }

        if achievement.isUnlocked {
            achievementUnlockDate(achievement)
        }
    }

    /// Creates the background for the achievement card
    /// - Parameter achievement: Achievement
    /// - Returns: Background color
    private func achievementCardBackground(_ achievement: Achievement) -> Color {
        achievement.isUnlocked ? Color(.systemBackground) : Color(.systemGray6)
    }

    /// Creates the achievement icon
    /// - Parameter achievement: Achievement
    /// - Returns: Icon view
    private func achievementIcon(_ achievement: Achievement) -> some View {
        ZStack {
            Circle()
                .fill(
                    achievement.isUnlocked
                        ? achievement.category.color
                        : Color(.systemGray4)
                )
                .frame(width: 64, height: 64)

            Image(systemName: achievement.displayIconName)
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
    }

    /// Creates the achievement info section (title, description, points)
    /// - Parameter achievement: Achievement
    /// - Returns: Info view
    private func achievementInfo(_ achievement: Achievement) -> some View {
        VStack(spacing: 6) {
            Text(achievement.displayTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(achievement.displayDescription)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)

                Text("\(achievement.points)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }

    /// Creates a progress bar for progressive achievements
    /// - Parameter achievement: Achievement
    /// - Returns: Progress bar view
    private func achievementProgressBar(_ achievement: Achievement) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(achievement.category.color)
                        .frame(
                            width: geometry.size.width * achievement.progress,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: achievement.progress)
                }
            }
            .frame(height: 6)

            Text(achievement.progressText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    /// Creates the unlock date display
    /// - Parameter achievement: Achievement
    /// - Returns: Unlock date view
    private func achievementUnlockDate(_ achievement: Achievement) -> some View {
        Group {
            if let dateString = achievement.formattedUnlockDate {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)

                    Text("Unlocked \(dateString)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Previews

#Preview("Achievements View - Empty") {
    NavigationStack {
        AchievementsView()
    }
}

#Preview("Achievements View - With Data") {
    NavigationStack {
        AchievementsView()
    }
}

#Preview("Achievements View - Dark Mode") {
    NavigationStack {
        AchievementsView()
    }
    .preferredColorScheme(.dark)
}
