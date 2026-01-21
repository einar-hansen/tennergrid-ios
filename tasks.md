# Tenner Grid iOS App - Implementation Tasks

**Project**: Tenner Grid Puzzle Game
**Technology**: SwiftUI + iOS 16+
**Platform**: iPhone & iPad (Universal)
**Domain**: tennergrid.com
**Last Updated**: January 21, 2026

---

## Phase 0: Project Setup & Foundation

### 0.1 Initial Setup

- [x] Create new Xcode project with SwiftUI template, bundle ID `com.tennergrid.app`, iOS 16+ deployment target
- [x] Set up Git repository with `.gitignore` for Xcode/Swift projects
- [x] Create basic folder structure: Models/, ViewModels/, Views/, Services/, Utilities/, Resources/
- [x] Configure Xcode scheme and ensure project builds successfully
- [ ] Add SwiftLint configuration file (.swiftlint.yml) with iOS/Swift best practices

### 0.2 Core Data Models

- [ ] Create `Difficulty` enum with cases (easy, medium, hard, expert, calculator) and associated properties
- [ ] Create `CellPosition` struct with row and column properties
- [ ] Create `TennerGridPuzzle` model struct with id, dimensions, difficulty, targetSums, initialGrid, solution
- [ ] Create `Cell` model struct with position, value, isInitial, pencilMarks, and state flags
- [ ] Write unit tests for all data models in Phase 0.2

### 0.3 Game State Models

- [ ] Create `GameState` model with puzzle, currentGrid, pencilMarks, selectedCell, timing, and completion data
- [ ] Create `GameAction` struct for undo/redo system with action type, position, old/new values
- [ ] Create `GameStatistics` model with games played, win rate, time tracking, and difficulty breakdowns
- [ ] Create `Achievement` model with id, title, description, progress, and unlock status
- [ ] Write unit tests for all game state models

---

## Phase 1: Core Game Logic

### 1.1 Validation Service

- [ ] Implement `ValidationService` with method to check if a number placement is valid (no adjacent duplicates, no row duplicates)
- [ ] Add method to detect all conflicts for a given cell position
- [ ] Add method to validate column sum against target sum
- [ ] Add method to check if entire puzzle is correctly completed
- [ ] Write comprehensive unit tests for `ValidationService` with edge cases

### 1.2 Puzzle Solver

- [ ] Implement `PuzzleSolver` with backtracking algorithm to solve Tenner Grid puzzles
- [ ] Add constraint propagation optimization to improve solve speed
- [ ] Add method to verify a puzzle has a unique solution
- [ ] Add method to find the next logical move (for hints)
- [ ] Write unit tests for `PuzzleSolver` with various puzzle difficulties

### 1.3 Puzzle Generator

- [ ] Implement `PuzzleGenerator` to create random valid completed grids
- [ ] Add method to remove cells based on difficulty while maintaining unique solution
- [ ] Add method to calculate column sums from completed grid
- [ ] Add method to generate full puzzle with specified columns, rows, and difficulty
- [ ] Write unit tests ensuring generated puzzles are valid and solvable

### 1.4 Hint Service

- [ ] Implement `HintService` to identify next cell(s) to fill
- [ ] Add method to get all possible valid values for a selected cell
- [ ] Add method to reveal the correct value for a cell
- [ ] Track hint usage count in game state
- [ ] Write unit tests for hint service with various game states

---

## Phase 2: Game State Management

### 2.1 Game View Model

- [ ] Create `GameViewModel` as ObservableObject with published game state
- [ ] Implement cell selection logic with published selectedPosition
- [ ] Implement number entry with validation and error handling
- [ ] Implement notes/pencil marks toggle and management
- [ ] Write unit tests for GameViewModel state changes

### 2.2 Undo/Redo System

- [ ] Add undo/redo action history stack to GameViewModel
- [ ] Implement undo method that restores previous game state
- [ ] Implement redo method that replays undone actions
- [ ] Limit history to last 50 actions to manage memory
- [ ] Write unit tests for undo/redo with multiple action sequences

### 2.3 Timer & Game Flow

- [ ] Add timer tracking to GameViewModel with start, pause, resume functionality
- [ ] Implement pause/resume game state management
- [ ] Implement completion check after each number entry
- [ ] Trigger win state when puzzle is correctly completed
- [ ] Write unit tests for timer and game flow state transitions

### 2.4 Puzzle Manager

- [ ] Create `PuzzleManager` as ObservableObject to manage puzzle library
- [ ] Implement method to generate new puzzle with specified parameters
- [ ] Implement method to generate daily puzzle (deterministic based on date)
- [ ] Add saved games list management (add, remove, load)
- [ ] Write unit tests for PuzzleManager

---

## Phase 3: Basic UI Components

### 3.1 Cell View

- [ ] Create `CellView` with number display, pre-filled vs user-entered styling
- [ ] Add visual states: empty, selected, error, highlighted, same-number
- [ ] Add pencil marks display in 3x3 grid within cell
- [ ] Add tap gesture handling
- [ ] Test on various screen sizes (SE, standard, Max)

### 3.2 Grid View

- [ ] Create `GridView` with dynamic LazyVGrid layout for 5-10 columns
- [ ] Add column sum display below each column
- [ ] Implement cell selection coordination with GameViewModel
- [ ] Add visual feedback for adjacent cells and same numbers
- [ ] Test grid rendering with different puzzle sizes

### 3.3 Number Pad

- [ ] Create `NumberPadView` with buttons for digits 0-9
- [ ] Show conflict count or disabled state for invalid numbers
- [ ] Highlight currently selected number
- [ ] Add tap handling connected to GameViewModel
- [ ] Test number pad on iPhone and iPad

### 3.4 Game Toolbar

- [ ] Create `GameToolbarView` with Undo, Erase, Notes, and Hint buttons
- [ ] Use SF Symbols for all icons
- [ ] Add ON/OFF indicator for notes mode
- [ ] Add badge showing remaining hints
- [ ] Wire up all toolbar actions to GameViewModel

### 3.5 Game Header

- [ ] Create `GameHeaderView` with timer display (MM:SS format)
- [ ] Add difficulty label with color indicator
- [ ] Add pause button
- [ ] Add settings/menu button
- [ ] Test header layout on different screen sizes

---

## Phase 4: Game Screen Assembly

### 4.1 Main Game View

- [ ] Create `GameView` composing GridView, NumberPad, Toolbar, and Header
- [ ] Add keyboard support for number entry (0-9 keys, backspace)
- [ ] Implement pause overlay that blurs the grid
- [ ] Add basic win screen navigation
- [ ] Test complete game flow: start, play, complete

### 4.2 Pause Menu

- [ ] Create `PauseMenuView` with Resume, Restart, New Game, Settings, Quit options
- [ ] Style as modal overlay with blur background
- [ ] Wire up navigation to each option
- [ ] Add "Are you sure?" confirmation for destructive actions
- [ ] Test pause/resume flow

### 4.3 Win Screen

- [ ] Create `WinScreenView` with congratulations message
- [ ] Display game statistics: time, hints used, difficulty
- [ ] Add celebration animation (simple scale/fade, confetti optional)
- [ ] Add buttons: New Game, Change Difficulty, Home
- [ ] Test win screen with different puzzle completions

---

## Phase 5: Home & Navigation

### 5.1 Home Screen

- [ ] Create `HomeView` with app branding and title
- [ ] Add "Continue Game" card if game is in progress
- [ ] Add "New Game" button that shows difficulty selection
- [ ] Add "Daily Challenge" card with countdown timer
- [ ] Test navigation from home to game screen

### 5.2 Difficulty Selection

- [ ] Create `DifficultySelectionView` as modal sheet
- [ ] List all difficulty levels with color indicators
- [ ] Add optional "Custom Grid Size" option
- [ ] Wire up selection to start new game
- [ ] Test difficulty selection flow

### 5.3 Tab Navigation

- [ ] Create `TabBarView` with 3 tabs: Main, Daily Challenges, Me
- [ ] Use SF Symbols for tab icons
- [ ] Implement tab switching with proper state preservation
- [ ] Set Main tab as default
- [ ] Test tab navigation flow

### 5.4 Daily Challenges View

- [ ] Create `DailyChallengesView` with calendar-style layout
- [ ] Show completion status for each day
- [ ] Display current streak and monthly stats
- [ ] Enable tap to play daily puzzle
- [ ] Test daily puzzle generation and display

### 5.5 Profile/Me View

- [ ] Create `ProfileView` with sections: Awards, Statistics, Settings
- [ ] Add navigation to How to Play, Rules, Help, About
- [ ] Add placeholder for Remove Ads (IAP will come later)
- [ ] Add Restore Purchase button
- [ ] Test all navigation from Me tab

---

## Phase 6: Settings & Preferences

### 6.1 Settings View

- [ ] Create `SettingsView` with game settings section
- [ ] Add toggles: auto-check errors, show timer, highlight same numbers, haptic feedback, sound effects
- [ ] Add appearance section with light/dark/auto theme selector
- [ ] Add notification section with daily reminder toggle
- [ ] Wire all settings to UserDefaults persistence

### 6.2 User Settings Model

- [ ] Create `UserSettings` model with Codable conformance
- [ ] Create `SettingsManager` service to save/load settings
- [ ] Add @AppStorage property wrappers for settings in ViewModels
- [ ] Implement settings observers in GameViewModel
- [ ] Write unit tests for SettingsManager

---

## Phase 7: Tutorial & Onboarding

### 7.1 Rules View

- [ ] Create `RulesView` with visual examples of each rule
- [ ] Rule 1: No adjacent identical numbers (show diagram)
- [ ] Rule 2: No duplicates in rows (show diagram)
- [ ] Rule 3: Column sums must match target (show example)
- [ ] Make accessible from Me → Rules

### 7.2 How to Play View

- [ ] Create `HowToPlayView` with detailed strategy guide
- [ ] Add sections: Basic Rules, Tips & Tricks, Advanced Strategies
- [ ] Include interactive examples (optional)
- [ ] Add "Start Tutorial" button
- [ ] Make accessible from Me → How to Play

### 7.3 First Launch Tutorial

- [ ] Create `OnboardingView` with 3-5 page carousel
- [ ] Page 1: Welcome and game overview
- [ ] Page 2: Basic rules with visuals
- [ ] Page 3: How to play (controls)
- [ ] Add "Skip" and "Get Started" buttons
- [ ] Show only on first launch (use UserDefaults flag)

---

## Phase 8: Statistics & Achievements

### 8.1 Statistics View

- [ ] Create `StatisticsView` with overall stats section
- [ ] Show: total games, win rate, total time, average time
- [ ] Add by-difficulty breakdown with charts
- [ ] Show streak information with calendar view
- [ ] Wire to StatisticsManager service

### 8.2 Statistics Manager

- [ ] Create `StatisticsManager` service with methods to record game completion
- [ ] Add method to update streaks
- [ ] Add method to calculate averages and trends
- [ ] Persist statistics to UserDefaults or local file
- [ ] Write unit tests for statistics calculations

### 8.3 Achievements System

- [ ] Define achievement list with 10-15 achievements
- [ ] Create `AchievementManager` service to check conditions
- [ ] Implement achievement unlock logic
- [ ] Add persistence for achievement status
- [ ] Write unit tests for achievement logic

### 8.4 Achievements View

- [ ] Create `AchievementsView` with grid of achievement cards
- [ ] Show locked achievements as grayed out
- [ ] Show unlocked achievements with icon and date
- [ ] Add progress bars for progressive achievements
- [ ] Add unlock notification/animation

---

## Phase 9: Data Persistence

### 9.1 Local Persistence Setup

- [ ] Choose persistence approach: SwiftData (iOS 17+) or Codable + FileManager
- [ ] Create persistence schema for SavedGame, Statistics, Achievements, Settings
- [ ] Implement migration strategy for schema updates
- [ ] Set up proper file paths and directories
- [ ] Write unit tests for persistence layer

### 9.2 Persistence Manager

- [ ] Create `PersistenceManager` service with save/load methods
- [ ] Implement saveGame and loadGame methods
- [ ] Implement saveStatistics and loadStatistics
- [ ] Implement saveAchievements and loadAchievements
- [ ] Add error handling for file I/O failures

### 9.3 Auto-Save

- [ ] Implement auto-save in GameViewModel when app backgrounds
- [ ] Add save on significant game state changes
- [ ] Load saved game on app launch if present
- [ ] Test save/load by force-quitting app
- [ ] Handle corrupted save files gracefully

---

## Phase 10: Polish & UX

### 10.1 Animations

- [ ] Add number entry animation (scale + fade in)
- [ ] Add error shake animation for invalid moves
- [ ] Add cell selection bounce animation
- [ ] Add smooth transitions between screens
- [ ] Add win celebration confetti or particle effect

### 10.2 Haptic Feedback

- [ ] Create `HapticManager` service with feedback methods
- [ ] Add haptics for cell selection (light impact)
- [ ] Add haptics for number entry (medium impact)
- [ ] Add haptics for errors (notification warning)
- [ ] Add haptics for puzzle completion (notification success)

### 10.3 Sound Effects

- [ ] Add sound assets: click, error, success, button tap
- [ ] Create `SoundManager` service with AVFoundation
- [ ] Implement sound playback methods
- [ ] Respect sound toggle in settings
- [ ] Preload sounds for better performance

### 10.4 Dark Mode

- [ ] Define dark mode color palette in Assets
- [ ] Test all screens in dark mode
- [ ] Ensure sufficient contrast for accessibility
- [ ] Fix any color/visibility issues
- [ ] Test dynamic switching between light/dark

### 10.5 Accessibility

- [ ] Add VoiceOver labels to all interactive elements
- [ ] Test complete game flow with VoiceOver enabled
- [ ] Support Dynamic Type (scalable fonts)
- [ ] Test with largest accessibility text sizes
- [ ] Add high contrast support for color-blind users

---

## Phase 11: iPad Optimization

### 11.1 iPad Layouts

- [ ] Optimize GridView layout for iPad screen sizes
- [ ] Create horizontal layout for landscape orientation
- [ ] Adjust spacing and sizing for larger screens
- [ ] Test on iPad Mini, iPad Air, iPad Pro
- [ ] Ensure all tap targets are appropriately sized

### 11.2 Multitasking Support

- [ ] Test app in Split View mode
- [ ] Test app in Slide Over mode
- [ ] Ensure layout adapts to narrow widths
- [ ] Handle size class transitions smoothly
- [ ] Test all features in multitasking modes

### 11.3 Keyboard & Pencil Support

- [ ] Add hardware keyboard shortcuts (0-9, arrows, delete, hints)
- [ ] Add keyboard discoverability (Cmd key visualization)
- [ ] Support Apple Pencil for cell selection (optional)
- [ ] Test keyboard navigation flow
- [ ] Document keyboard shortcuts in Help

---

## Phase 12: Testing & Quality

### 12.1 Unit Test Coverage

- [ ] Achieve 80%+ code coverage for Models
- [ ] Achieve 80%+ code coverage for Services (ValidationService, PuzzleGenerator, PuzzleSolver)
- [ ] Achieve 70%+ code coverage for ViewModels
- [ ] Fix any failing tests
- [ ] Add tests for edge cases and error conditions

### 12.2 UI Testing

- [ ] Create UI test for complete game flow: launch → new game → play → win
- [ ] Create UI test for pause/resume flow
- [ ] Create UI test for hint system
- [ ] Create UI test for undo/redo
- [ ] Create UI test for daily challenge

### 12.3 Performance Testing

- [ ] Profile app with Instruments for memory leaks
- [ ] Ensure 60 FPS during gameplay
- [ ] Optimize puzzle generation to <1 second
- [ ] Test app launch time (<2 seconds)
- [ ] Test on older devices (iPhone SE)

### 12.4 Device Testing

- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPhone 15 Pro (standard size)
- [ ] Test on iPhone 15 Pro Max (large screen)
- [ ] Test on iPad Mini
- [ ] Test on iPad Pro 12.9"

---

## Phase 13: Monetization Preparation

### 13.1 AdMob Integration Setup

- [ ] Create AdMob account and register app
- [ ] Add Google Mobile Ads SDK via Swift Package Manager
- [ ] Configure AdMob App ID in Info.plist
- [ ] Initialize Mobile Ads SDK on app launch
- [ ] Test ads display in simulator (test ad units)

### 13.2 Ad Manager Service

- [ ] Create `AdManager` service to load and display banner ads
- [ ] Implement interstitial ad loading and display
- [ ] Implement rewarded video ad loading and display
- [ ] Add ad lifecycle event handlers
- [ ] Test ads on physical device (simulator shows test ads only)

### 13.3 Ad Placement UI

- [ ] Add banner ad to bottom of HomeView (dismissible)
- [ ] Add interstitial ad after puzzle completion (max 1 per 5 min)
- [ ] Create "Watch Ad to Play" flow for free users
- [ ] Add "Watch Ad for Hint" option
- [ ] Respect "ads removed" flag for premium users

### 13.4 In-App Purchase Setup

- [ ] Create non-consumable IAP product in App Store Connect: "Remove Ads" ($2.99)
- [ ] Configure App Store Connect with product ID, descriptions, pricing
- [ ] Add StoreKit configuration file for local testing
- [ ] Create sandbox test accounts
- [ ] Test IAP purchase flow in sandbox

### 13.5 IAP Manager Service

- [ ] Create `IAPManager` service with StoreKit 2
- [ ] Implement product fetching from App Store
- [ ] Implement purchase flow with error handling
- [ ] Implement restore purchases functionality
- [ ] Persist purchase status to UserDefaults and verify on launch

### 13.6 Remove Ads View

- [ ] Create `RemoveAdsView` explaining benefits
- [ ] Show product price from App Store
- [ ] Add Purchase button with loading state
- [ ] Add Restore Purchase button
- [ ] Handle success/failure states with user feedback

---

## Phase 14: App Store Preparation

### 14.1 App Metadata

- [ ] Create app icon (1024x1024) following design guidelines
- [ ] Generate all required icon sizes in Assets catalog
- [ ] Write compelling app description for App Store
- [ ] Choose keywords for App Store Optimization (ASO)
- [ ] Set app categories: Games > Puzzle, Games > Board

### 14.2 Screenshots & Preview

- [ ] Create iPhone screenshots for 6.7", 6.5", 5.5" displays
- [ ] Create iPad screenshots for 12.9" and 11" displays
- [ ] Add text overlays highlighting key features
- [ ] Create app preview video (15-30 seconds) showing gameplay
- [ ] Test all media displays correctly in App Store Connect

### 14.3 Legal & Privacy

- [ ] Write Privacy Policy covering data collection and usage
- [ ] Write Terms of Service for app usage
- [ ] Host Privacy Policy and Terms on tennergrid.com
- [ ] Add App Tracking Transparency (ATT) prompt with NSUserTrackingUsageDescription
- [ ] Test ATT prompt flow

### 14.4 Final Polish

- [ ] Review all text for typos and consistency
- [ ] Test all features end-to-end on physical device
- [ ] Fix any remaining UI glitches or bugs
- [ ] Ensure no crashes occur during normal usage
- [ ] Set version to 1.0.0 and build number to 1

---

## Phase 15: Launch

### 15.1 Pre-Launch Testing

- [ ] Conduct final QA pass on all features
- [ ] Test IAP purchase and restore on sandbox
- [ ] Test ads display correctly
- [ ] Verify analytics tracking works
- [ ] Check all external links (privacy policy, terms, support)

### 15.2 TestFlight Beta

- [ ] Create archive and upload to App Store Connect
- [ ] Configure TestFlight with beta testing information
- [ ] Invite 10-20 beta testers
- [ ] Collect feedback via TestFlight
- [ ] Fix critical bugs found in beta

### 15.3 App Store Submission

- [ ] Complete all App Store Connect fields
- [ ] Upload final build with version 1.0.0
- [ ] Submit for App Store Review
- [ ] Respond to any review feedback within 24 hours
- [ ] Monitor review status daily

### 15.4 Launch Day

- [ ] Once approved, release app to App Store
- [ ] Announce launch on tennergrid.com
- [ ] Share on social media (if applicable)
- [ ] Monitor for crashes via Crashlytics/Sentry
- [ ] Monitor reviews and respond to users

---

## Phase 16: Post-Launch

### 16.1 Monitoring

- [ ] Track daily active users (DAU) via analytics
- [ ] Monitor crash reports and fix critical issues
- [ ] Track IAP conversion rate
- [ ] Monitor ad revenue and eCPM
- [ ] Review user ratings and feedback

### 16.2 Quick Wins

- [ ] Fix any critical bugs reported by users
- [ ] Respond to user reviews (especially negative ones)
- [ ] Release v1.0.1 with bug fixes if needed
- [ ] Optimize ad placement based on user feedback
- [ ] Add any missing accessibility features

### 16.3 Future Planning

- [ ] Plan v1.1 features based on user requests
- [ ] Consider additional puzzle variants or game modes
- [ ] Explore social features (leaderboards, challenges)
- [ ] Investigate additional monetization (more IAPs, subscriptions)
- [ ] Build roadmap for next 6 months

---

## Summary

**Total Tasks**: 187 tasks organized in 16 phases

**Estimated Timeline**: 10-14 weeks (solo developer, part-time)

**Critical Path (MVP)**:
1. Phase 0-2: Setup + Core Logic (3 weeks)
2. Phase 3-5: UI Development (3 weeks)
3. Phase 6-9: Features & Persistence (3 weeks)
4. Phase 10-13: Polish & Monetization (2 weeks)
5. Phase 14-15: App Store & Launch (2 weeks)

**Quality Gates**:
- Every task must build successfully
- Tests must pass before marking task complete
- SwiftLint warnings must be addressed
- Code must be committed with descriptive message

**Ralph Wiggum Loop Compatibility**:
- Each task is atomic and completable in one iteration
- Tasks are ordered by dependency
- Each task can be built, tested, linted, and committed independently
- Progress is tracked via checkbox format
