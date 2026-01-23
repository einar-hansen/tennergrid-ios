import SwiftUI

/// View for selecting difficulty level when starting a new game
/// Displays all available difficulty levels with descriptions and visual indicators
/// Also includes an optional custom game configuration for advanced players
// swiftlint:disable:next swiftui_view_body
struct DifficultySelectionView: View {
    // MARK: - Properties

    /// Callback when a difficulty is selected
    var onSelect: ((Difficulty) -> Void)?

    /// Callback when a custom game is configured
    var onCustomGame: ((Difficulty, Int) -> Void)?

    /// Dismiss action for closing the sheet
    @Environment(\.dismiss) private var dismiss

    /// State to control custom game configuration sheet
    @State private var showingCustomConfiguration = false

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

            customGameCard
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

    // MARK: - Custom Game Card

    /// Custom game configuration card
    private var customGameCard: some View {
        Button {
            showingCustomConfiguration = true
        } label: {
            customGameCardContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingCustomConfiguration) {
            CustomGameConfigurationView(onConfirm: { difficulty, rows in
                onCustomGame?(difficulty, rows)
                dismiss()
            })
        }
    }

    /// Content for custom game card
    private var customGameCardContent: some View {
        HStack(spacing: 16) {
            customColorIndicator
            customCardDetails
            chevronIcon
        }
        .padding(20)
        .background(customCardBackground)
    }

    /// Color indicator for custom game
    private var customColorIndicator: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 8)
    }

    /// Details section for custom game card
    private var customCardDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            customCardHeader
            customCardDescription
        }
        .padding(.vertical, 4)
    }

    /// Header for custom game card
    private var customCardHeader: some View {
        HStack {
            Text("Custom Game")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            customBadge
        }
    }

    /// Custom badge
    private var customBadge: some View {
        Text("CUSTOM")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.8))
            )
    }

    /// Description for custom game card
    private var customCardDescription: some View {
        Text("Choose your own difficulty and grid size")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
    }

    /// Background for custom game card
    private var customCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .purple.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Custom Game Configuration View

/// View for configuring a custom game with difficulty and grid size
// swiftlint:disable:next swiftui_view_body
struct CustomGameConfigurationView: View {
    // MARK: - Properties

    /// Callback when configuration is confirmed
    var onConfirm: ((Difficulty, Int) -> Void)?

    /// Dismiss action for closing the sheet
    @Environment(\.dismiss) private var dismiss

    /// Selected difficulty level
    @State private var selectedDifficulty: Difficulty = .medium

    /// Selected number of rows
    @State private var selectedRows: Int = 5

    // MARK: - Constants

    private let minRows = 3
    private let maxRows = 10

    // MARK: - Body

    var body: some View {
        NavigationView {
            configurationForm
        }
    }

    /// Configuration form with all sections
    private var configurationForm: some View {
        Form {
            difficultySection
            rowsSection
            previewSection
        }
        .navigationTitle("Custom Game")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Start Game") {
                    onConfirm?(selectedDifficulty, selectedRows)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Sections

    /// Section for selecting difficulty
    private var difficultySection: some View {
        Section {
            ForEach(Difficulty.allCases) { difficulty in
                difficultyRow(for: difficulty)
            }
        } header: {
            Text("Difficulty")
        } footer: {
            Text(selectedDifficulty.description)
        }
    }

    /// Row for difficulty selection
    /// - Parameter difficulty: The difficulty level
    /// - Returns: A row view
    private func difficultyRow(for difficulty: Difficulty) -> some View {
        Button {
            selectedDifficulty = difficulty
        } label: {
            HStack {
                Circle()
                    .fill(difficulty.color)
                    .frame(width: 12, height: 12)

                Text(difficulty.displayName)
                    .foregroundColor(.primary)

                Spacer()

                if selectedDifficulty == difficulty {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    /// Section for selecting number of rows
    private var rowsSection: some View {
        Section {
            Picker("Rows", selection: $selectedRows) {
                ForEach(minRows ... maxRows, id: \.self) { rows in
                    Text("\(rows) rows")
                        .tag(rows)
                }
            }
            .pickerStyle(.wheel)
        } header: {
            Text("Grid Size")
        } footer: {
            Text("The grid will have \(selectedRows) rows and 10 columns (standard)")
        }
    }

    /// Preview section showing configuration summary
    private var previewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                previewRow(icon: "slider.horizontal.3", title: "Difficulty", value: selectedDifficulty.displayName)
                previewRow(icon: "square.grid.3x3", title: "Grid Size", value: "\(selectedRows) × 10")
                previewRow(
                    icon: "clock",
                    title: "Estimated Time",
                    value: "~\(selectedDifficulty.estimatedMinutes) min"
                )
                previewRow(icon: "star", title: "Points", value: "\(selectedDifficulty.points) pts")
            }
        } header: {
            Text("Preview")
        }
    }

    /// Preview row with icon and values
    /// - Parameters:
    ///   - icon: SF Symbol name
    ///   - title: Row title
    ///   - value: Row value
    /// - Returns: A preview row view
    private func previewRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
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

#Preview("Difficulty Selection - With Custom Game") {
    DifficultySelectionView(
        onSelect: { _ in },
        onCustomGame: { _, _ in }
    )
}

#Preview("Custom Game Configuration") {
    CustomGameConfigurationView { _, _ in
        // Preview callback - no action needed
    }
}
