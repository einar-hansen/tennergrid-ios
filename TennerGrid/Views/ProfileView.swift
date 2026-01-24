import SwiftUI

/// Profile/Me view displaying user statistics, achievements, and settings
/// Provides access to game information, help resources, and app preferences
// swiftlint:disable:next swiftui_view_body type_body_length
struct ProfileView: View {
    // MARK: - Properties

    /// State for presenting sheets
    @State private var showingRemoveAds = false
    @State private var showingRestorePurchase = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                awardsSection
                statisticsSection
                settingsSection
                helpSection
                aboutSection
                monetizationSection
            }
            .navigationTitle("Me")
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $showingRemoveAds) {
            removeAdsPlaceholder
        }
        .alert("Restore Purchases", isPresented: $showingRestorePurchase) {
            Button("OK") {
                showingRestorePurchase = false
            }
        } message: {
            Text("Purchase restoration will be implemented in Phase 13.")
        }
    }

    // MARK: - Sections

    /// Awards/Achievements section
    private var awardsSection: some View {
        Section {
            NavigationLink {
                achievementsPlaceholder
            } label: {
                HStack(spacing: 12) {
                    sectionIcon("trophy.fill", color: .yellow)
                    Text("Awards")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        } header: {
            Text("Achievements")
        }
    }

    /// Statistics section
    private var statisticsSection: some View {
        Section {
            NavigationLink {
                statisticsPlaceholder
            } label: {
                HStack(spacing: 12) {
                    sectionIcon("chart.bar.fill", color: .blue)
                    Text("Statistics")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        } header: {
            Text("Progress")
        }
    }

    /// Settings section
    private var settingsSection: some View {
        Section {
            NavigationLink {
                SettingsView()
            } label: {
                HStack(spacing: 12) {
                    sectionIcon("gearshape.fill", color: .gray)
                    Text("Settings")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        } header: {
            Text("Preferences")
        }
    }

    /// Help & Information section
    private var helpSection: some View {
        Section {
            howToPlayLink
            rulesLink
            helpLink
        } header: {
            Text("Learn")
        }
    }

    private var howToPlayLink: some View {
        NavigationLink {
            howToPlayPlaceholder
        } label: {
            HStack(spacing: 12) {
                sectionIcon("book.fill", color: .green)
                Text("How to Play")
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }

    private var rulesLink: some View {
        NavigationLink {
            RulesView()
        } label: {
            HStack(spacing: 12) {
                sectionIcon("list.bullet.rectangle.fill", color: .orange)
                Text("Rules")
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }

    private var helpLink: some View {
        NavigationLink {
            helpPlaceholder
        } label: {
            HStack(spacing: 12) {
                sectionIcon("questionmark.circle.fill", color: .purple)
                Text("Help")
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }

    /// About section
    private var aboutSection: some View {
        Section {
            NavigationLink {
                aboutPlaceholder
            } label: {
                HStack(spacing: 12) {
                    sectionIcon("info.circle.fill", color: .blue)
                    Text("About")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        } header: {
            Text("Information")
        }
    }

    /// Monetization section with Remove Ads and Restore Purchase
    private var monetizationSection: some View {
        Section {
            removeAdsButton
            restorePurchaseButton
        } header: {
            Text("Premium")
        } footer: {
            Text("Purchases will be implemented in Phase 13")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var removeAdsButton: some View {
        Button {
            showingRemoveAds = true
        } label: {
            HStack(spacing: 12) {
                sectionIcon("nosign", color: .red)
                Text("Remove Ads")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text("$2.99")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var restorePurchaseButton: some View {
        Button {
            showingRestorePurchase = true
        } label: {
            HStack(spacing: 12) {
                sectionIcon("arrow.clockwise", color: .blue)
                Text("Restore Purchase")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Helper Views

    /// Creates a section icon with specified SF Symbol and color
    /// - Parameters:
    ///   - systemName: SF Symbol name
    ///   - color: Icon color
    /// - Returns: Icon view
    private func sectionIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(color)
            .cornerRadius(8)
    }

    // MARK: - Placeholder Views

    /// Placeholder for Achievements view (Phase 8.4)
    private var achievementsPlaceholder: some View {
        PlaceholderView(
            icon: "trophy.fill",
            iconColor: .yellow,
            title: "Achievements",
            subtitle: "Coming in Phase 8",
            navigationTitle: "Awards"
        )
    }

    /// Placeholder for Statistics view (Phase 8.1)
    private var statisticsPlaceholder: some View {
        PlaceholderView(
            icon: "chart.bar.fill",
            iconColor: .blue,
            title: "Statistics",
            subtitle: "Coming in Phase 8",
            navigationTitle: "Statistics"
        )
    }

    /// Placeholder for How to Play view (Phase 7.2)
    private var howToPlayPlaceholder: some View {
        PlaceholderView(
            icon: "book.fill",
            iconColor: .green,
            title: "How to Play",
            subtitle: "Coming in Phase 7",
            navigationTitle: "How to Play"
        )
    }

    /// Placeholder for Rules view (Phase 7.1)
    private var rulesPlaceholder: some View {
        PlaceholderView(
            icon: "list.bullet.rectangle.fill",
            iconColor: .orange,
            title: "Rules",
            subtitle: "Coming in Phase 7",
            navigationTitle: "Rules"
        )
    }

    /// Placeholder for Help view
    private var helpPlaceholder: some View {
        PlaceholderView(
            icon: "questionmark.circle.fill",
            iconColor: .purple,
            title: "Help",
            subtitle: "Get help with using the app",
            navigationTitle: "Help"
        )
    }

    /// Placeholder for About view
    private var aboutPlaceholder: some View {
        VStack(spacing: 20) {
            aboutIcon
            aboutTitle
            aboutVersion
            aboutDescription
        }
        .navigationTitle("About")
    }

    private var aboutIcon: some View {
        Image(systemName: "info.circle.fill")
            .font(.system(size: 64))
            .foregroundColor(.blue)
    }

    private var aboutTitle: some View {
        Text("About Tenner Grid")
            .font(.system(size: 28, weight: .bold))
    }

    private var aboutVersion: some View {
        Text("Version 1.0.0")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
    }

    private var aboutDescription: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tenner Grid is the ultimate number puzzle game.")
            Text("Developed with SwiftUI for iOS.")
        }
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .padding(.horizontal, 40)
    }

    /// Placeholder for Remove Ads sheet (Phase 13.6)
    private var removeAdsPlaceholder: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                removeAdsHeader
                removeAdsBenefits
                Spacer()
                removeAdsFooter
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingRemoveAds = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var removeAdsHeader: some View {
        VStack(spacing: 20) {
            Image(systemName: "nosign")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Remove Ads")
                .font(.system(size: 32, weight: .bold))

            Text("Enjoy an ad-free experience for just $2.99")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var removeAdsBenefits: some View {
        VStack(spacing: 16) {
            benefitRow(icon: "checkmark.circle.fill", text: "No banner ads")
            benefitRow(icon: "checkmark.circle.fill", text: "No interstitial ads")
            benefitRow(icon: "checkmark.circle.fill", text: "Support development")
        }
        .padding(.horizontal, 40)
    }

    private var removeAdsFooter: some View {
        VStack(spacing: 12) {
            Text("In-App Purchases coming in Phase 13")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Button {
                showingRemoveAds = false
            } label: {
                Text("Close")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }

    /// Creates a benefit row for the Remove Ads sheet
    /// - Parameters:
    ///   - icon: SF Symbol name
    ///   - text: Benefit description
    /// - Returns: Benefit row view
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Helper Views

/// Reusable placeholder view for sections coming in future phases
// swiftlint:disable:next swiftui_view_body
private struct PlaceholderView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let navigationTitle: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(iconColor)

            Text(title)
                .font(.system(size: 28, weight: .bold))

            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .navigationTitle(navigationTitle)
    }
}

// MARK: - Previews

#Preview("Profile View - Light Mode") {
    ProfileView()
}

#Preview("Profile View - Dark Mode") {
    ProfileView()
        .preferredColorScheme(.dark)
}

#Preview("Remove Ads Sheet") {
    ProfileView()
        .onAppear {
            // Simulate showing the Remove Ads sheet
        }
}
