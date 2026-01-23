import Foundation
import Testing
@testable import TennerGrid

struct AchievementTests {
    // MARK: - Initialization Tests

    @Test func basicInitialization() {
        let achievement = Achievement(
            id: "test_achievement",
            title: "Test Achievement",
            achievementDescription: "Complete a test",
            category: .games,
            iconName: "star.fill",
            targetValue: 10,
            isHidden: false,
            points: 50
        )

        #expect(achievement.id == "test_achievement")
        #expect(achievement.title == "Test Achievement")
        #expect(achievement.achievementDescription == "Complete a test")
        #expect(achievement.category == .games)
        #expect(achievement.iconName == "star.fill")
        #expect(achievement.targetValue == 10)
        #expect(achievement.isHidden == false)
        #expect(achievement.points == 50)
        #expect(achievement.progress == 0.0)
        #expect(achievement.isUnlocked == false)
        #expect(achievement.unlockedAt == nil)
    }

    @Test func initializationWithDefaults() {
        let achievement = Achievement(
            id: "simple",
            title: "Simple",
            achievementDescription: "A simple achievement",
            category: .mastery,
            iconName: "checkmark"
        )

        #expect(achievement.targetValue == 1)
        #expect(achievement.isHidden == false)
        #expect(achievement.points == 10)
    }

    // MARK: - Factory Methods Tests

    @Test func oneTimeFactoryMethod() {
        let achievement = Achievement.oneTime(
            id: "first_win",
            title: "First Win",
            achievementDescription: "Win your first game",
            category: .games,
            iconName: "flag.fill",
            points: 15
        )

        #expect(achievement.targetValue == 1)
        #expect(achievement.isHidden == false)
        #expect(achievement.points == 15)
    }

    @Test func oneTimeHiddenFactoryMethod() {
        let achievement = Achievement.oneTime(
            id: "secret",
            title: "Secret Achievement",
            achievementDescription: "Find the secret",
            category: .special,
            iconName: "sparkles",
            isHidden: true,
            points: 100
        )

        #expect(achievement.isHidden == true)
        #expect(achievement.targetValue == 1)
    }

    @Test func progressiveFactoryMethod() {
        let achievement = Achievement.progressive(
            id: "win_100",
            title: "Centurion",
            achievementDescription: "Win 100 games",
            category: .games,
            iconName: "100.circle",
            targetValue: 100,
            points: 200
        )

        #expect(achievement.targetValue == 100)
        #expect(achievement.isHidden == false)
        #expect(achievement.points == 200)
    }

    // MARK: - AchievementCategory Tests

    @Test func categoryDisplayNames() {
        #expect(Achievement.AchievementCategory.games.displayName == "Games Played")
        #expect(Achievement.AchievementCategory.difficulty.displayName == "Difficulty Mastery")
        #expect(Achievement.AchievementCategory.speed.displayName == "Speed Running")
        #expect(Achievement.AchievementCategory.mastery.displayName == "Perfect Play")
        #expect(Achievement.AchievementCategory.streaks.displayName == "Dedication")
        #expect(Achievement.AchievementCategory.special.displayName == "Special")
    }

    @Test func categoryIconNames() {
        #expect(Achievement.AchievementCategory.games.iconName == "gamecontroller.fill")
        #expect(Achievement.AchievementCategory.difficulty.iconName == "chart.bar.fill")
        #expect(Achievement.AchievementCategory.speed.iconName == "clock.fill")
        #expect(Achievement.AchievementCategory.mastery.iconName == "star.fill")
        #expect(Achievement.AchievementCategory.streaks.iconName == "flame.fill")
        #expect(Achievement.AchievementCategory.special.iconName == "trophy.fill")
    }

    @Test func categoryAllCases() {
        let allCases = Achievement.AchievementCategory.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.games))
        #expect(allCases.contains(.difficulty))
        #expect(allCases.contains(.speed))
        #expect(allCases.contains(.mastery))
        #expect(allCases.contains(.streaks))
        #expect(allCases.contains(.special))
    }

    // MARK: - Progress Management Tests

    @Test func updateProgressFromZero() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        let unlocked = achievement.updateProgress(currentValue: 1)

        #expect(achievement.progress == 1.0)
        #expect(unlocked)
        #expect(achievement.isUnlocked)
    }

    @Test func updateProgressPartial() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star",
            targetValue: 10
        )

        let unlocked = achievement.updateProgress(currentValue: 5)

        #expect(achievement.progress == 0.5)
        #expect(!unlocked)
        #expect(!achievement.isUnlocked)
    }

    @Test func updateProgressToCompletion() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star",
            targetValue: 10
        )

        achievement.updateProgress(currentValue: 5)
        let unlocked = achievement.updateProgress(currentValue: 10)

        #expect(achievement.progress == 1.0)
        #expect(unlocked)
        #expect(achievement.isUnlocked)
        #expect(achievement.unlockedAt != nil)
    }

    @Test func updateProgressBeyondTarget() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star",
            targetValue: 10
        )

        achievement.updateProgress(currentValue: 15)

        #expect(achievement.progress == 1.0)
        #expect(achievement.isUnlocked)
    }

    @Test func updateProgressWhenAlreadyUnlocked() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        achievement.unlock()
        let unlocked = achievement.updateProgress(currentValue: 2)

        #expect(!unlocked) // Already unlocked
        #expect(achievement.progress == 1.0)
    }

    @Test func unlockSetsFlags() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        let beforeUnlock = Date()
        achievement.unlock()
        let afterUnlock = Date()

        #expect(achievement.isUnlocked)
        #expect(achievement.progress == 1.0)
        #expect(achievement.unlockedAt != nil)
        #expect(achievement.unlockedAt! >= beforeUnlock)
        #expect(achievement.unlockedAt! <= afterUnlock)
    }

    @Test func unlockWhenAlreadyUnlockedDoesNothing() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        achievement.unlock()
        let firstUnlockDate = achievement.unlockedAt

        achievement.unlock()
        let secondUnlockDate = achievement.unlockedAt

        #expect(firstUnlockDate == secondUnlockDate)
    }

    @Test func resetClearsProgress() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        achievement.unlock()
        achievement.reset()

        #expect(!achievement.isUnlocked)
        #expect(achievement.progress == 0.0)
        #expect(achievement.unlockedAt == nil)
    }

    // MARK: - Computed Properties Tests

    @Test func progressPercentageZero() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        #expect(achievement.progressPercentage == 0)
    }

    @Test func progressPercentagePartial() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star",
            targetValue: 10
        )

        achievement.updateProgress(currentValue: 7)

        #expect(achievement.progressPercentage == 70)
    }

    @Test func progressPercentageFull() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        achievement.unlock()

        #expect(achievement.progressPercentage == 100)
    }

    @Test func currentValueCalculation() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star",
            targetValue: 20
        )

        achievement.updateProgress(currentValue: 5)
        #expect(achievement.currentValue == 5)

        achievement.updateProgress(currentValue: 15)
        #expect(achievement.currentValue == 15)
    }

    @Test func progressText() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star",
            targetValue: 50
        )

        achievement.updateProgress(currentValue: 20)

        #expect(achievement.progressText == "20/50")
    }

    @Test func isVisibleWhenNotHidden() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star",
            isHidden: false
        )

        #expect(achievement.isVisible)
    }

    @Test func isVisibleWhenHiddenAndLocked() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .special,
            iconName: "star",
            isHidden: true
        )

        #expect(!achievement.isVisible)
    }

    @Test func isVisibleWhenHiddenButUnlocked() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .special,
            iconName: "star",
            isHidden: true
        )

        achievement.unlock()

        #expect(achievement.isVisible)
    }

    @Test func displayTitleWhenUnlocked() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Amazing Achievement",
            achievementDescription: "You did it!",
            category: .games,
            iconName: "star",
            isHidden: true
        )

        achievement.unlock()

        #expect(achievement.displayTitle == "Amazing Achievement")
    }

    @Test func displayTitleWhenHiddenAndLocked() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Secret Achievement",
            achievementDescription: "Find the secret",
            category: .special,
            iconName: "star",
            isHidden: true
        )

        #expect(achievement.displayTitle == "???")
    }

    @Test func displayTitleWhenNotHidden() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Public Achievement",
            achievementDescription: "Everyone can see this",
            category: .games,
            iconName: "star",
            isHidden: false
        )

        #expect(achievement.displayTitle == "Public Achievement")
    }

    @Test func displayDescriptionWhenUnlocked() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "The real description",
            category: .games,
            iconName: "star",
            isHidden: true
        )

        achievement.unlock()

        #expect(achievement.displayDescription == "The real description")
    }

    @Test func displayDescriptionWhenHiddenAndLocked() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "The real description",
            category: .special,
            iconName: "star",
            isHidden: true
        )

        #expect(achievement.displayDescription.contains("hidden"))
    }

    @Test func displayIconNameWhenUnlocked() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test",
            category: .games,
            iconName: "trophy.fill",
            isHidden: true
        )

        achievement.unlock()

        #expect(achievement.displayIconName == "trophy.fill")
    }

    @Test func displayIconNameWhenHiddenAndLocked() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test",
            category: .special,
            iconName: "trophy.fill",
            isHidden: true
        )

        #expect(achievement.displayIconName == "questionmark.circle.fill")
    }

    @Test func formattedUnlockDateWhenNotUnlocked() {
        let achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test",
            category: .games,
            iconName: "star"
        )

        #expect(achievement.formattedUnlockDate == nil)
    }

    @Test func formattedUnlockDateWhenUnlocked() {
        var achievement = Achievement.oneTime(
            id: "test",
            title: "Test",
            achievementDescription: "Test",
            category: .games,
            iconName: "star"
        )

        achievement.unlock()

        #expect(achievement.formattedUnlockDate != nil)
        #expect(!achievement.formattedUnlockDate!.isEmpty)
    }

    // MARK: - Predefined Achievements Tests

    @Test func allAchievementsCount() {
        let achievements = Achievement.allAchievements

        #expect(achievements.count == 16)
    }

    @Test func allAchievementsHaveUniqueIds() {
        let achievements = Achievement.allAchievements
        let ids = achievements.map(\.id)
        let uniqueIds = Set(ids)

        #expect(ids.count == uniqueIds.count)
    }

    @Test func allAchievementsHaveValidPoints() {
        let achievements = Achievement.allAchievements

        for achievement in achievements {
            #expect(achievement.points > 0)
        }
    }

    @Test func firstGameAchievementExists() {
        let achievements = Achievement.allAchievements
        let firstGame = achievements.first { $0.id == "first_game" }

        #expect(firstGame != nil)
        #expect(firstGame?.category == .games)
        #expect(firstGame?.targetValue == 1)
    }

    @Test func calculatorAchievementIsHidden() {
        let achievements = Achievement.allAchievements
        let calculator = achievements.first { $0.id == "calculator_complete" }

        #expect(calculator != nil)
        #expect(calculator?.isHidden == true)
        #expect(calculator?.category == .special)
    }

    @Test func progressiveAchievementsHaveCorrectTargets() {
        let achievements = Achievement.allAchievements
        let games10 = achievements.first { $0.id == "games_10" }
        let games50 = achievements.first { $0.id == "games_50" }
        let games100 = achievements.first { $0.id == "games_100" }

        #expect(games10?.targetValue == 10)
        #expect(games50?.targetValue == 50)
        #expect(games100?.targetValue == 100)
    }

    @Test func streakAchievementsExist() {
        let achievements = Achievement.allAchievements
        let streak3 = achievements.first { $0.id == "streak_3" }
        let streak7 = achievements.first { $0.id == "streak_7" }
        let streak30 = achievements.first { $0.id == "streak_30" }

        #expect(streak3 != nil)
        #expect(streak7 != nil)
        #expect(streak30 != nil)
        #expect(streak3?.category == .streaks)
    }

    @Test func speedAchievementsExist() {
        let achievements = Achievement.allAchievements
        let speedEasy = achievements.first { $0.id == "speed_easy" }
        let speedMedium = achievements.first { $0.id == "speed_medium" }
        let speedHard = achievements.first { $0.id == "speed_hard" }

        #expect(speedEasy != nil)
        #expect(speedMedium != nil)
        #expect(speedHard != nil)
        #expect(speedEasy?.category == .speed)
    }

    @Test func masteryAchievementsExist() {
        let achievements = Achievement.allAchievements
        let noHints = achievements.first { $0.id == "no_hints" }
        let perfect = achievements.first { $0.id == "perfect_game" }

        #expect(noHints != nil)
        #expect(perfect != nil)
        #expect(noHints?.category == .mastery)
        #expect(perfect?.category == .mastery)
    }

    // MARK: - Equatable Tests

    @Test func equalityWithIdenticalAchievements() {
        let achievement1 = Achievement(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        let achievement2 = Achievement(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        #expect(achievement1 == achievement2)
    }

    @Test func equalityWithDifferentIds() {
        let achievement1 = Achievement(
            id: "test1",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        let achievement2 = Achievement(
            id: "test2",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        #expect(achievement1 != achievement2)
    }

    @Test func equalityAfterUnlock() {
        var achievement1 = Achievement(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        let achievement2 = Achievement(
            id: "test",
            title: "Test",
            achievementDescription: "Test achievement",
            category: .games,
            iconName: "star"
        )

        achievement1.unlock()

        #expect(achievement1 != achievement2)
    }

    // MARK: - Codable Tests

    @Test func codableEncoding() throws {
        var achievement = Achievement(
            id: "test",
            title: "Test Achievement",
            achievementDescription: "Test description",
            category: .games,
            iconName: "star.fill",
            targetValue: 10,
            points: 50
        )

        achievement.updateProgress(currentValue: 5)

        let encoder = JSONEncoder()
        let data = try encoder.encode(achievement)

        #expect(!data.isEmpty)
    }

    @Test func codableDecoding() throws {
        var original = Achievement(
            id: "test",
            title: "Test Achievement",
            achievementDescription: "Test description",
            category: .games,
            iconName: "star.fill",
            targetValue: 10,
            points: 50
        )

        original.updateProgress(currentValue: 5)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Achievement.self, from: data)

        #expect(decoded == original)
    }

    @Test func codableRoundTrip() throws {
        var achievement = Achievement(
            id: "complex_test",
            title: "Complex Test",
            achievementDescription: "A complex achievement for testing",
            category: .mastery,
            iconName: "crown.fill",
            targetValue: 25,
            isHidden: true,
            points: 100
        )

        achievement.updateProgress(currentValue: 15)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(achievement)
        let decoded = try decoder.decode(Achievement.self, from: encoded)

        #expect(decoded.id == achievement.id)
        #expect(decoded.title == achievement.title)
        #expect(decoded.achievementDescription == achievement.achievementDescription)
        #expect(decoded.category == achievement.category)
        #expect(decoded.iconName == achievement.iconName)
        #expect(decoded.targetValue == achievement.targetValue)
        #expect(decoded.isHidden == achievement.isHidden)
        #expect(decoded.points == achievement.points)
        #expect(decoded.progress == achievement.progress)
        #expect(decoded.isUnlocked == achievement.isUnlocked)
    }

    @Test func codableRoundTripUnlockedAchievement() throws {
        var achievement = Achievement.oneTime(
            id: "unlocked_test",
            title: "Unlocked Test",
            achievementDescription: "An unlocked achievement",
            category: .games,
            iconName: "checkmark"
        )

        achievement.unlock()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(achievement)
        let decoded = try decoder.decode(Achievement.self, from: encoded)

        #expect(decoded.isUnlocked == true)
        #expect(decoded.progress == 1.0)
        #expect(decoded.unlockedAt != nil)
    }

    // MARK: - Identifiable Tests

    @Test func identifiableIdProperty() {
        let achievement = Achievement(
            id: "unique_id",
            title: "Test",
            achievementDescription: "Test",
            category: .games,
            iconName: "star"
        )

        #expect(achievement.id == "unique_id")
    }

    // MARK: - CustomStringConvertible Tests

    @Test func descriptionContainsKeyInfo() {
        var achievement = Achievement.progressive(
            id: "test_100",
            title: "Century",
            achievementDescription: "Reach 100",
            category: .games,
            iconName: "100.circle",
            targetValue: 100,
            points: 200
        )

        achievement.updateProgress(currentValue: 50)

        let description = achievement.description

        #expect(description.contains("Achievement"))
        #expect(description.contains("test_100"))
        #expect(description.contains("Century"))
        #expect(description.contains("50/100"))
        #expect(description.contains("200"))
    }

    @Test func descriptionForHiddenAchievement() {
        let achievement = Achievement.oneTime(
            id: "secret",
            title: "Secret",
            achievementDescription: "Find the secret",
            category: .special,
            iconName: "sparkles",
            isHidden: true
        )

        let description = achievement.description

        #expect(description.contains("???"))
    }

    // MARK: - Edge Cases

    @Test func zeroTargetValue() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            achievementDescription: "Test",
            category: .games,
            iconName: "star",
            targetValue: 0
        )

        // Should handle division by zero gracefully
        #expect(achievement.targetValue == 0)
    }

    @Test func veryLargeTargetValue() {
        var achievement = Achievement.progressive(
            id: "marathon",
            title: "Marathon",
            achievementDescription: "Play 10000 games",
            category: .games,
            iconName: "figure.run",
            targetValue: 10000
        )

        achievement.updateProgress(currentValue: 5000)

        #expect(achievement.progress == 0.5)
        #expect(achievement.progressPercentage == 50)
    }

    @Test func multipleProgressUpdates() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test",
            category: .games,
            iconName: "star",
            targetValue: 100
        )

        achievement.updateProgress(currentValue: 10)
        #expect(achievement.progress == 0.1)

        achievement.updateProgress(currentValue: 50)
        #expect(achievement.progress == 0.5)

        achievement.updateProgress(currentValue: 75)
        #expect(achievement.progress == 0.75)

        achievement.updateProgress(currentValue: 100)
        #expect(achievement.progress == 1.0)
        #expect(achievement.isUnlocked)
    }

    @Test func progressUpdateBackwards() {
        var achievement = Achievement.progressive(
            id: "test",
            title: "Test",
            achievementDescription: "Test",
            category: .games,
            iconName: "star",
            targetValue: 100
        )

        achievement.updateProgress(currentValue: 50)
        #expect(achievement.progress == 0.5)

        // Update with lower value (should still work)
        achievement.updateProgress(currentValue: 25)
        #expect(achievement.progress == 0.25)
    }
}
