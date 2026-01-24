import SwiftUI

/// Statistics view displaying comprehensive game statistics
/// Shows overall stats, difficulty breakdowns, and streak information
struct StatisticsView: View {
    // MARK: - Properties

    /// Sample statistics for preview/testing
    /// In production, this would come from a StatisticsManager
    @State private var statistics: GameStatistics

    // MARK: - Initialization

    init(statistics: GameStatistics = .new()) {
        self.statistics = statistics
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overallStatsSection
                streakSection
                if !statistics.difficultyBreakdowns.isEmpty {
                    difficultyBreakdownSection
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Overall Statistics Section

    private var overallStatsSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Overall Statistics", icon: "chart.bar.fill", color: .blue)
            overallStatsCard
        }
        .padding(.horizontal, 16)
    }

    private var overallStatsCard: some View {
        VStack(spacing: 12) {
            statRow(label: "Games Played", value: "\(statistics.gamesPlayed)")
            statRow(label: "Games Completed", value: "\(statistics.gamesCompleted)")

            if statistics.gamesPlayed > 0 {
                statRow(label: "Win Rate", value: statistics.winRatePercentage)
            }

            if statistics.totalTimePlayed > 0 {
                statRow(label: "Total Time Played", value: statistics.formattedTotalTime)
            }

            if let avgTime = statistics.formattedAverageTime {
                statRow(label: "Average Time", value: avgTime)
            }

            if let bestTime = statistics.formattedBestTime {
                statRow(label: "Best Time", value: bestTime)
            }

            if statistics.totalHintsUsed > 0 {
                statRow(label: "Total Hints Used", value: "\(statistics.totalHintsUsed)")
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Streaks", icon: "flame.fill", color: .orange)

            HStack(spacing: 16) {
                streakCard(
                    title: "Current Streak",
                    value: "\(statistics.currentStreak)",
                    icon: "calendar",
                    color: statistics.hasActiveStreak() ? .orange : .gray
                )

                streakCard(
                    title: "Longest Streak",
                    value: "\(statistics.longestStreak)",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
            .padding(.horizontal, 16)
        }
    }

    /// Creates a streak card with title, value, icon, and color
    /// - Parameters:
    ///   - title: Card title
    ///   - value: Streak value
    ///   - icon: SF Symbol name
    ///   - color: Card accent color
    /// - Returns: Streak card view
    private func streakCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Difficulty Breakdown Section

    private var difficultyBreakdownSection: some View {
        VStack(spacing: 16) {
            sectionHeader(
                title: "By Difficulty",
                icon: "slider.horizontal.3",
                color: .purple
            )

            VStack(spacing: 12) {
                ForEach(sortedDifficulties(), id: \.self) { difficulty in
                    difficultyCard(for: difficulty)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// Creates a difficulty breakdown card
    /// - Parameter difficulty: Difficulty level
    /// - Returns: Difficulty card view
    private func difficultyCard(for difficulty: Difficulty) -> some View {
        let stats = statistics.statistics(for: difficulty)

        return VStack(spacing: 16) {
            difficultyCardHeader(difficulty: difficulty, stats: stats)
            difficultyCardStats(stats: stats)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func difficultyCardHeader(
        difficulty: Difficulty,
        stats: GameStatistics.DifficultyStatistics
    ) -> some View {
        HStack {
            Circle()
                .fill(difficulty.color)
                .frame(width: 12, height: 12)

            Text(difficulty.displayName)
                .font(.system(size: 18, weight: .semibold))

            Spacer()

            Text("\(stats.completed)/\(stats.played)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func difficultyCardStats(stats: GameStatistics.DifficultyStatistics) -> some View {
        VStack(spacing: 8) {
            if stats.played > 0 {
                difficultyStatRow(
                    label: "Win Rate",
                    value: String(format: "%.1f%%", stats.winRate * 100)
                )
            }

            if let avgTime = stats.averageTime {
                difficultyStatRow(label: "Average Time", value: formatTime(avgTime))
            }

            if let bestTime = stats.bestTime {
                difficultyStatRow(label: "Best Time", value: formatTime(bestTime))
            }

            if stats.completed > 0 {
                difficultyStatRow(
                    label: "Avg. Hints Used",
                    value: String(format: "%.1f", stats.averageHints)
                )
            }
        }
    }

    /// Creates a stat row within a difficulty card
    /// - Parameters:
    ///   - label: Stat label
    ///   - value: Stat value
    /// - Returns: Stat row view
    private func difficultyStatRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Helper Views

    /// Creates a section header with icon and color
    /// - Parameters:
    ///   - title: Section title
    ///   - icon: SF Symbol name
    ///   - color: Icon color
    /// - Returns: Section header view
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    /// Creates a basic stat row with label and value
    /// - Parameters:
    ///   - label: Stat label
    ///   - value: Stat value
    /// - Returns: Stat row view
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Helper Methods

    /// Returns difficulties sorted by play count (descending)
    /// - Returns: Array of difficulties
    private func sortedDifficulties() -> [Difficulty] {
        statistics.difficultiesByPlayCount()
    }

    /// Formats a time interval as MM:SS
    /// - Parameter time: Time in seconds
    /// - Returns: Formatted string
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

#Preview("Empty Statistics") {
    NavigationStack {
        StatisticsView(statistics: .new())
    }
}

#Preview("Statistics with Data") {
    NavigationStack {
        StatisticsView(statistics: sampleStatistics())
    }
}

#Preview("Statistics - Dark Mode") {
    NavigationStack {
        StatisticsView(statistics: sampleStatistics())
    }
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

private func sampleStatistics() -> GameStatistics {
    var stats = GameStatistics()

    // Record some games for easy difficulty
    stats.recordGameStarted(difficulty: .easy)
    stats.recordGameCompleted(difficulty: .easy, time: 180, hintsUsed: 2, errors: 1)
    stats.recordGameStarted(difficulty: .easy)
    stats.recordGameCompleted(difficulty: .easy, time: 150, hintsUsed: 1, errors: 0)
    stats.recordGameStarted(difficulty: .easy)
    stats.recordGameCompleted(difficulty: .easy, time: 200, hintsUsed: 3, errors: 2)

    // Record some games for medium difficulty
    stats.recordGameStarted(difficulty: .medium)
    stats.recordGameCompleted(difficulty: .medium, time: 420, hintsUsed: 4, errors: 3)
    stats.recordGameStarted(difficulty: .medium)
    stats.recordGameCompleted(difficulty: .medium, time: 380, hintsUsed: 3, errors: 2)

    // Record some games for hard difficulty
    stats.recordGameStarted(difficulty: .hard)
    stats.recordGameCompleted(difficulty: .hard, time: 780, hintsUsed: 8, errors: 5)

    // Add a failed game (started but not completed)
    stats.recordGameStarted(difficulty: .medium)

    return stats
}
