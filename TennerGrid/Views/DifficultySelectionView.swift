import SwiftUI

/// View for selecting difficulty level when starting a new game
/// Displays all available difficulty levels with descriptions and visual indicators
// swiftlint:disable:next swiftui_view_body
struct DifficultySelectionView: View {
    // MARK: - Properties

    /// Callback when a difficulty is selected
    var onSelect: ((Difficulty) -> Void)?

    /// Dismiss action for closing the sheet
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                        .padding(.top, 20)

                    difficultyOptions
                        .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    /// Header section with title and description
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Choose Your Challenge")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text("Select a difficulty level to start a new puzzle")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }

    /// Difficulty options list
    private var difficultyOptions: some View {
        VStack(spacing: 16) {
            ForEach(Difficulty.allCases) { difficulty in
                difficultyCard(for: difficulty)
            }
        }
    }

    /// Individual difficulty card
    /// - Parameter difficulty: The difficulty level
    /// - Returns: A card showing the difficulty details
    private func difficultyCard(for difficulty: Difficulty) -> some View {
        Button {
            onSelect?(difficulty)
            dismiss()
        } label: {
            difficultyCardContent(for: difficulty)
        }
        .buttonStyle(.plain)
    }

    /// Content for difficulty card
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Card content view
    private func difficultyCardContent(for difficulty: Difficulty) -> some View {
        HStack(spacing: 16) {
            colorIndicator(for: difficulty)
            cardDetails(for: difficulty)
            chevronIcon
        }
        .padding(20)
        .background(cardBackground)
    }

    /// Color indicator bar
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Color indicator view
    private func colorIndicator(for difficulty: Difficulty) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(difficulty.color)
            .frame(width: 8)
    }

    /// Card details section
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Details view
    private func cardDetails(for difficulty: Difficulty) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader(for: difficulty)
            cardDescription(for: difficulty)
            cardMetadata(for: difficulty)
        }
        .padding(.vertical, 4)
    }

    /// Card header with title and badge
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Header view
    private func cardHeader(for difficulty: Difficulty) -> some View {
        HStack {
            Text(difficulty.displayName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            difficultyBadge(for: difficulty)
        }
    }

    /// Card description text
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Description view
    private func cardDescription(for difficulty: Difficulty) -> some View {
        Text(difficulty.description)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
    }

    /// Card metadata row
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Metadata view
    private func cardMetadata(for difficulty: Difficulty) -> some View {
        HStack(spacing: 16) {
            metadataItem(
                icon: "clock.fill",
                text: "~\(difficulty.estimatedMinutes) min"
            )

            metadataItem(
                icon: "square.grid.3x3.fill",
                text: "\(difficulty.minRows)-\(difficulty.maxRows) rows"
            )

            metadataItem(
                icon: "star.fill",
                text: "\(difficulty.points) pts"
            )

            Spacer()
        }
    }

    /// Chevron icon for navigation
    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
    }

    /// Card background with rounded rectangle and shadow
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    /// Difficulty badge view
    /// - Parameter difficulty: The difficulty level
    /// - Returns: A badge showing pre-filled percentage
    private func difficultyBadge(for difficulty: Difficulty) -> some View {
        Text("\(Int(difficulty.prefilledPercentage * 100))% filled")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(difficulty.color.opacity(0.8))
            )
    }

    /// Metadata item with icon and text
    /// - Parameters:
    ///   - icon: SF Symbol name
    ///   - text: Display text
    /// - Returns: Metadata view
    private func metadataItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Difficulty Selection - Light Mode") {
    DifficultySelectionView()
}

#Preview("Difficulty Selection - Dark Mode") {
    DifficultySelectionView()
        .preferredColorScheme(.dark)
}

#Preview("Difficulty Selection - With Action") {
    DifficultySelectionView { _ in
        // Preview callback - no action needed
    }
}
