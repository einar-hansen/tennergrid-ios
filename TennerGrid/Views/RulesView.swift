import SwiftUI

/// Rules view displaying visual examples of each Tenner Grid rule
/// Provides clear explanations of game constraints with interactive diagrams
// swiftlint:disable:next swiftui_view_body
struct RulesView: View {
    // MARK: - Properties

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let cellSize: CGFloat = 44

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                rule1Section
                rule2Section
                rule3Section
                objectiveSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("How to Play Tenner Grid")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Master these three simple rules to become a Tenner Grid expert")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Rule 1: No Adjacent Duplicates

    private var rule1Section: some View {
        RuleCard(
            number: 1,
            title: "No Adjacent Identical Numbers",
            description: "Numbers cannot be the same in any adjacent cells, including diagonally adjacent cells.",
            color: .red
        ) {
            Rule1ExamplesView(cellSize: cellSize)
        }
    }

    // MARK: - Rule 2: No Row Duplicates

    private var rule2Section: some View {
        RuleCard(
            number: 2,
            title: "No Duplicates in Rows",
            description: "Each row must contain unique numbers - no number can appear twice in the same row.",
            color: .blue
        ) {
            Rule2ExamplesView(cellSize: cellSize)
        }
    }

    // MARK: - Rule 3: Column Sums

    private var rule3Section: some View {
        RuleCard(
            number: 3,
            title: "Column Sums Must Match Target",
            description: "The sum of all numbers in each column must equal the target number shown below that column.",
            color: .purple
        ) {
            Rule3ExamplesView(cellSize: cellSize)
        }
    }

    // MARK: - Objective Section

    private var objectiveSection: some View {
        VStack(spacing: 16) {
            Text("Your Objective")
                .font(.system(size: 24, weight: .bold))

            VStack(alignment: .leading, spacing: 12) {
                ObjectiveRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "Fill all empty cells with numbers from 0 to 9"
                )
                ObjectiveRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "Follow all three rules for every number you place"
                )
                ObjectiveRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "Complete the puzzle when all cells are filled correctly"
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.bottom, 20)
    }
}

// MARK: - Supporting Views

/// Card view for displaying a rule with number, title, description, and example
private struct RuleCard<Content: View>: View {
    let number: Int
    let title: String
    let description: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        // swiftlint:disable:next closure_body_length
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Text("\(number)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // Example content
            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

/// Example cell view for rule demonstrations
private struct ExampleCell: View {
    let value: Int?
    let isInitial: Bool
    let hasError: Bool
    let size: CGFloat

    init(value: Int?, isInitial: Bool = false, hasError: Bool = false, size: CGFloat = 44) {
        self.value = value
        self.isInitial = isInitial
        self.hasError = hasError
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )

            // Value
            if let value {
                Text(String(value))
                    .font(.system(size: size * 0.5, weight: isInitial ? .bold : .semibold, design: .rounded))
                    .foregroundColor(textColor)
            }
        }
        .frame(width: size, height: size)
    }

    private var backgroundColor: Color {
        if hasError {
            Color.red.opacity(0.15)
        } else if isInitial {
            Color(uiColor: .secondarySystemGroupedBackground)
        } else {
            Color(uiColor: .systemBackground)
        }
    }

    private var borderColor: Color {
        if hasError {
            .red
        } else {
            Color(uiColor: .separator)
        }
    }

    private var borderWidth: CGFloat {
        hasError ? 2 : 1
    }

    private var textColor: Color {
        if hasError {
            .red
        } else if isInitial {
            .primary
        } else {
            .blue
        }
    }
}

/// Examples view for Rule 1: No Adjacent Duplicates
// swiftlint:disable:next swiftui_view_body
private struct Rule1ExamplesView: View {
    let cellSize: CGFloat

    var body: some View {
        // swiftlint:disable:next closure_body_length
        VStack(spacing: 20) {
            // Invalid example
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("❌ Invalid")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                    Spacer()
                }

                HStack(spacing: 4) {
                    ExampleCell(value: 3, isInitial: false, hasError: true, size: cellSize)
                    ExampleCell(value: 3, isInitial: false, hasError: true, size: cellSize)
                    ExampleCell(value: 1, isInitial: false, hasError: false, size: cellSize)
                }
                HStack(spacing: 4) {
                    ExampleCell(value: 5, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 3, isInitial: false, hasError: true, size: cellSize)
                    ExampleCell(value: 7, isInitial: false, hasError: false, size: cellSize)
                }

                Text("The three 3's are touching each other")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()
            }

            Divider()

            // Valid example
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("✅ Valid")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Spacer()
                }

                HStack(spacing: 4) {
                    ExampleCell(value: 3, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 5, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 1, isInitial: false, hasError: false, size: cellSize)
                }
                HStack(spacing: 4) {
                    ExampleCell(value: 2, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 7, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 3, isInitial: false, hasError: false, size: cellSize)
                }

                Text("No adjacent cells have the same number")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

/// Examples view for Rule 2: No Row Duplicates
// swiftlint:disable:next swiftui_view_body
private struct Rule2ExamplesView: View {
    let cellSize: CGFloat

    var body: some View {
        // swiftlint:disable:next closure_body_length
        VStack(spacing: 20) {
            // Invalid example
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("❌ Invalid")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                    Spacer()
                }

                HStack(spacing: 4) {
                    ExampleCell(value: 5, isInitial: false, hasError: true, size: cellSize)
                    ExampleCell(value: 3, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 1, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 7, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 5, isInitial: false, hasError: true, size: cellSize)
                }

                Text("The number 5 appears twice in this row")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()
            }

            Divider()

            // Valid example
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("✅ Valid")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Spacer()
                }

                HStack(spacing: 4) {
                    ExampleCell(value: 5, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 3, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 1, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 7, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 2, isInitial: false, hasError: false, size: cellSize)
                }

                Text("All numbers in the row are unique")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

/// Examples view for Rule 3: Column Sums
// swiftlint:disable closure_body_length
// swiftlint:disable:next swiftui_view_body
private struct Rule3ExamplesView: View {
    let cellSize: CGFloat

    var body: some View {
        VStack(spacing: 20) {
            // Example column
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Example Column")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }

                VStack(spacing: 4) {
                    ExampleCell(value: 5, isInitial: true, hasError: false, size: cellSize)
                    ExampleCell(value: 3, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 7, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 2, isInitial: false, hasError: false, size: cellSize)
                    ExampleCell(value: 6, isInitial: true, hasError: false, size: cellSize)

                    // Sum display
                    Text("23")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.purple)
                        .frame(width: cellSize, height: 32)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }

                HStack {
                    Text("5 + 3 + 7 + 2 + 6 = ")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("23 ✅")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }

                Text("The sum matches the target")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

// swiftlint:enable closure_body_length

/// Objective row with icon and text
// swiftlint:disable:next swiftui_view_body
private struct ObjectiveRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Previews

#Preview("Rules View - Light Mode") {
    NavigationStack {
        RulesView()
    }
}

#Preview("Rules View - Dark Mode") {
    NavigationStack {
        RulesView()
            .preferredColorScheme(.dark)
    }
}

#Preview("Rules View - Compact") {
    NavigationStack {
        RulesView()
    }
}
