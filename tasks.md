# Tenner Grid iOS App - Implementation Tasks

**Project**: Tenner Grid Puzzle Game
**Technology**: SwiftUI + iOS 16+
**Platform**: iPhone & iPad (Universal)
**Domain**: tennergrid.com
**Last Updated**: January 22, 2026

---

## Phase 0: Project Setup & Foundation

### 0.1 Initial Setup

- [x] Create new Xcode project with SwiftUI template, bundle ID `com.tennergrid.app`, iOS 16+ deployment target
- [x] Set up Git repository with `.gitignore` for Xcode/Swift projects
- [x] Create basic folder structure: Models/, ViewModels/, Views/, Services/, Utilities/, Resources/
- [x] Configure Xcode scheme and ensure project builds successfully
- [x] Add SwiftLint configuration file (.swiftlint.yml) with iOS/Swift best practices

### 0.2 Core Data Models

- [x] Create `Difficulty` enum with cases (easy, medium, hard, expert, calculator) and associated properties
- [x] Create `CellPosition` struct with row and column properties
- [x] Create `TennerGridPuzzle` model struct with id, dimensions, difficulty, targetSums, initialGrid, solution
- [x] Create `Cell` model struct with position, value, isInitial, pencilMarks, and state flags
- [x] Write unit tests for all data models in Phase 0.2

### 0.3 Game State Models

- [x] Create `GameState` model with puzzle, currentGrid, pencilMarks, selectedCell, timing, and completion data
- [x] Create `GameAction` struct for undo/redo system with action type, position, old/new values
- [x] Create `GameStatistics` model with games played, win rate, time tracking, and difficulty breakdowns
- [x] Create `Achievement` model with id, title, description, progress, and unlock status
- [x] Write unit tests for all game state models

---

## Phase 1: Core Game Logic

### 1.1 Validation Service

- [x] [COMPLEX] Implement `ValidationService` with method to check if a number placement is valid (no adjacent duplicates, no row duplicates)
- [x] [COMPLEX] Add method to detect all conflicts for a given cell position
- [x] Add method to validate column sum against target sum
- [x] Add method to check if entire puzzle is correctly completed
- [x] Write comprehensive unit tests for `ValidationService` with edge cases

### 1.2 Puzzle Solver

- [x] [COMPLEX] Implement `PuzzleSolver` with backtracking algorithm to solve Tenner Grid puzzles
- [x] [COMPLEX] Add constraint propagation optimization to improve solve speed
- [x] [COMPLEX] Add method to verify a puzzle has a unique solution
- [x] Add method to find the next logical move (for hints)
- [x] Write unit tests for `PuzzleSolver` with various puzzle difficulties

### 1.3 Puzzle Generator

- [x] [COMPLEX] Implement `PuzzleGenerator` to create random valid completed grids
- [x] [COMPLEX] Add method to remove cells based on difficulty while maintaining unique solution
- [x] Add method to calculate column sums from completed grid
- [x] [COMPLEX] Add method to generate full puzzle with specified columns, rows, and difficulty
- [x] Write unit tests ensuring generated puzzles are valid and solvable

### 1.4 Hint Service

- [x] [COMPLEX] Implement `HintService` to identify next cell(s) to fill
- [x] Add method to get all possible valid values for a selected cell
- [x] Add method to reveal the correct value for a cell
- [x] Track hint usage count in game state
- [x] Write unit tests for hint service with various game states

---

## Phase 2: Game State Management

### 2.1 Game View Model

- [x] [COMPLEX] Create `GameViewModel` as ObservableObject with published game state
- [x] Implement cell selection logic with published selectedPosition
- [x] Implement number entry with validation and error handling
- [x] Implement notes/pencil marks toggle and management
- [x] Write unit tests for GameViewModel state changes

### 2.2 Undo/Redo System

- [x] [COMPLEX] Add undo/redo action history stack to GameViewModel
- [x] [COMPLEX] Implement undo method that restores previous game state
- [x] [COMPLEX] Implement redo method that replays undone actions
- [x] Limit history to last 50 actions to manage memory
- [x] Write unit tests for undo/redo with multiple action sequences

### 2.3 Timer & Game Flow

- [x] Add timer tracking to GameViewModel with start, pause, resume functionality
- [x] Implement pause/resume game state management
- [x] Implement completion check after each number entry
- [x] Trigger win state when puzzle is correctly completed
- [x] Write unit tests for timer and game flow state transitions

### 2.4 Puzzle Manager

- [x] Create `PuzzleManager` as ObservableObject to manage puzzle library
- [x] Implement method to generate new puzzle with specified parameters
- [x] Implement method to generate daily puzzle (deterministic based on date)
- [x] Add saved games list management (add, remove, load)
- [x] Write unit tests for PuzzleManager

---

## Phase 3: Basic UI Components

### 3.1 Cell View

- [x] Create `CellView` with number display, pre-filled vs user-entered styling
- [x] Add visual states: empty, selected, error, highlighted, same-number
- [x] Add pencil marks display in 3x3 grid within cell
- [x] Add tap gesture handling
- [x] Test on various screen sizes (SE, standard, Max)

### 3.2 Grid View

- [x] Create `GridView` with dynamic LazyVGrid layout for 5-10 columns
- [x] Add column sum display below each column
- [x] Implement cell selection coordination with GameViewModel
- [x] Add visual feedback for adjacent cells and same numbers
- [x] Test grid rendering with different puzzle sizes

### 3.3 Number Pad

- [x] Create `NumberPadView` with buttons for digits 0-9
- [x] Show conflict count or disabled state for invalid numbers
- [x] Highlight currently selected number
- [x] Add tap handling connected to GameViewModel
- [x] Test number pad on iPhone and iPad

### 3.4 Game Toolbar

- [x] Create `GameToolbarView` with Undo, Erase, Notes, and Hint buttons
- [x] Use SF Symbols for all icons
- [x] Add ON/OFF indicator for notes mode
- [x] Add badge showing remaining hints
- [x] Wire up all toolbar actions to GameViewModel

### 3.5 Game Header

- [x] Create `GameHeaderView` with timer display (MM:SS format)
- [x] Add difficulty label with color indicator
- [x] Add pause button
- [x] Add settings/menu button
- [x] Test header layout on different screen sizes

---

## Phase 4: Game Screen Assembly

### 4.1 Main Game View

- [x] Create `GameView` composing GridView, NumberPad, Toolbar, and Header
- [x] Add keyboard support for number entry (0-9 keys, backspace)
- [x] Implement pause overlay that blurs the grid
- [x] Add basic win screen navigation
- [x] Test complete game flow: start, play, complete

### 4.2 Pause Menu

- [x] Create `PauseMenuView` with Resume, Restart, New Game, Settings, Quit options
- [x] Style as modal overlay with blur background
- [x] Wire up navigation to each option
- [x] Add "Are you sure?" confirmation for destructive actions
- [x] Test pause/resume flow

### 4.3 Win Screen

- [x] Create `WinScreenView` with congratulations message
- [x] Display game statistics: time, hints used, difficulty
- [x] Add celebration animation (simple scale/fade, confetti optional)
- [x] Add buttons: New Game, Change Difficulty, Home
- [x] Test win screen with different puzzle completions

### 4.4 Game UI Enhancements

- [x] Fix grid dimensions: Always use 10 columns (required for neighbor rule), rows variable 3-10
- [x] Update `PuzzleGenerator` to enforce 10 columns constraint
- [x] Update `Difficulty` settings to work with 10-column grids only
- [x] Remove column spacing in GridView - make columns adjacent with no gaps
- [x] Add landscape/horizontal layout support for better iPad experience. Landscape is important for iPhone.
- [x] Implement intelligent number pad disabling based on column remaining sum
    - Calculate remaining sum needed for each column (target - current sum)
    - Disable numbers in number pad that exceed column's remaining sum
- [x] Add visual highlighting for neighbor cells when a cell is selected
    - Apply darker/lighter color overlay to all 8 adjacent cells (including diagonals)
    - Update cell selection visual feedback to show constraint helpers
    - Test neighbor highlighting with different cell positions (corners, edges, center)
- [x] Ensure performance with real-time neighbor updates during selection

---

## Phase 5: Home & Navigation

### 5.1 Home Screen

- [x] Create `HomeView` with app branding and title
- [x] Add "Continue Game" card if game is in progress
- [x] Add "New Game" button that shows difficulty selection
- [x] Add "Daily Challenge" card with countdown timer
- [x] Test navigation from home to game screen

### 5.2 Difficulty Selection

- [x] Create `DifficultySelectionView` as modal sheet
- [x] List all difficulty levels with color indicators
- [x] Add optional "Custom Grid Size" option
- [x] Wire up selection to start new game
- [x] Test difficulty selection flow

### 5.3 Tab Navigation

- [x] Create `TabBarView` with 3 tabs: Main, Daily Challenges, Me
- [x] Use SF Symbols for tab icons
- [x] Implement tab switching with proper state preservation
- [x] Set Main tab as default
- [x] Test tab navigation flow

### 5.4 Daily Challenges View

- [x] Create `DailyChallengesView` with calendar-style layout
- [x] Show completion status for each day
- [x] Display current streak and monthly stats
- [x] Enable tap to play daily puzzle
- [x] Test daily puzzle generation and display

### 5.5 Profile/Me View

- [x] Create `ProfileView` with sections: Awards, Statistics, Settings
- [x] Add navigation to How to Play, Rules, Help, About
- [x] Add placeholder for Remove Ads (IAP will come later)
- [x] Add Restore Purchase button
- [x] Test all navigation from Me tab

---

## Phase 6: Settings & Preferences

### 6.1 Settings View

- [x] Create `SettingsView` with game settings section
- [x] Add toggles: auto-check errors, show timer, highlight same numbers, haptic feedback, sound effects
- [x] Add appearance section with light/dark/auto theme selector
- [x] Add notification section with daily reminder toggle
- [x] Wire all settings to UserDefaults persistence

### 6.2 User Settings Model

- [x] Create `UserSettings` model with Codable conformance
- [x] Create `SettingsManager` service to save/load settings
- [x] Add @AppStorage property wrappers for settings in ViewModels
- [x] Implement settings observers in GameViewModel
- [x] Write unit tests for SettingsManager

---

## Phase 7: Tutorial & Onboarding

### 7.1 Rules View

- [x] Create `RulesView` with visual examples of each rule
- [x] Rule 1: No adjacent identical numbers (show diagram)
- [x] Rule 2: No duplicates in rows (show diagram)
- [x] Rule 3: Column sums must match target (show example)
- [x] Make accessible from Me → Rules

### 7.2 How to Play View

- [x] Create `HowToPlayView` with detailed strategy guide
- [x] Add sections: Basic Rules, Tips & Tricks, Advanced Strategies
- [x] Include interactive examples (optional)
- [x] Add "Start Tutorial" button
- [x] Make accessible from Me → How to Play

### 7.3 First Launch Tutorial

- [x] Create `OnboardingView` with 3-5 page carousel
- [x] Page 1: Welcome and game overview
- [x] Page 2: Basic rules with visuals
- [x] Page 3: How to play (controls)
- [x] Add "Skip" and "Get Started" buttons
- [x] Show only on first launch (use UserDefaults flag)

---

## Phase 8: Statistics & Achievements

### 8.1 Statistics View

- [x] Create `StatisticsView` with overall stats section
- [x] Show: total games, win rate, total time, average time
- [x] Add by-difficulty breakdown with charts
- [x] Show streak information with calendar view
- [x] Wire to StatisticsManager service

### 8.2 Statistics Manager

- [x] [COMPLEX] Create `StatisticsManager` service with methods to record game completion
- [x] Add method to update streaks
- [x] [COMPLEX] Add method to calculate averages and trends
- [x] Persist statistics to UserDefaults or local file
- [x] Write unit tests for statistics calculations

### 8.3 Achievements System

- [x] Define achievement list with 10-15 achievements
- [x] Create `AchievementManager` service to check conditions
- [x] Implement achievement unlock logic
- [x] Add persistence for achievement status
- [x] Write unit tests for achievement logic

### 8.4 Achievements View

- [x] Create `AchievementsView` with grid of achievement cards
- [x] Show locked achievements as grayed out
- [x] Show unlocked achievements with icon and date
- [x] Add progress bars for progressive achievements
- [x] Add unlock notification/animation

---

## Phase 9: Data Persistence

### 9.1 Local Persistence Setup

- [x] [COMPLEX] Choose persistence approach: SwiftData (iOS 17+) or Codable + FileManager
- [x] [COMPLEX] Create persistence schema for SavedGame, Statistics, Achievements, Settings
- [x] [COMPLEX] Implement migration strategy for schema updates
- [x] Set up proper file paths and directories
- [x] Write unit tests for persistence layer

### 9.2 Persistence Manager

- [x] [COMPLEX] Create `PersistenceManager` service with save/load methods
- [x] Implement saveGame and loadGame methods
- [x] Implement saveStatistics and loadStatistics
- [x] Implement saveAchievements and loadAchievements
- [x] Add error handling for file I/O failures

### 9.3 Auto-Save

- [x] Implement auto-save in GameViewModel when app backgrounds
- [x] Add save on significant game state changes
- [x] Load saved game on app launch if present
- [x] Test save/load by force-quitting app
- [x] Handle corrupted save files gracefully

---

## Phase 10: Polish & UX

### 10.1 Animations

- [x] Add number entry animation (scale + fade in)
- [x] Add error shake animation for invalid moves
- [x] Add cell selection bounce animation
- [x] Add smooth transitions between screens
- [x] Add win celebration confetti or particle effect

### 10.2 Haptic Feedback

- [x] Create `HapticManager` service with feedback methods
- [x] Add haptics for cell selection (light impact)
- [x] Add haptics for number entry (medium impact)
- [x] Add haptics for errors (notification warning)
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
- [ ] [COMPLEX] Achieve 80%+ code coverage for Services (ValidationService, PuzzleGenerator, PuzzleSolver)
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

- [ ] [COMPLEX] Profile app with Instruments for memory leaks
- [ ] Ensure 60 FPS during gameplay
- [ ] [COMPLEX] Optimize puzzle generation to <1 second
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

- [ ] [COMPLEX] Create AdMob account and register app
- [ ] [COMPLEX] Add Google Mobile Ads SDK via Swift Package Manager
- [ ] Configure AdMob App ID in Info.plist
- [ ] Initialize Mobile Ads SDK on app launch
- [ ] Test ads display in simulator (test ad units)

### 13.2 Ad Manager Service

- [ ] [COMPLEX] Create `AdManager` service to load and display banner ads
- [ ] [COMPLEX] Implement interstitial ad loading and display
- [ ] [COMPLEX] Implement rewarded video ad loading and display
- [ ] Add ad lifecycle event handlers
- [ ] Test ads on physical device (simulator shows test ads only)

### 13.3 Ad Placement UI

- [ ] Add banner ad to bottom of HomeView (dismissible)
- [ ] Add interstitial ad after puzzle completion (max 1 per 5 min)
- [ ] Create "Watch Ad to Play" flow for free users
- [ ] Add "Watch Ad for Hint" option
- [ ] Respect "ads removed" flag for premium users

### 13.4 In-App Purchase Setup

- [ ] [COMPLEX] Create non-consumable IAP product in App Store Connect: "Remove Ads" ($2.99)
- [ ] Configure App Store Connect with product ID, descriptions, pricing
- [ ] Add StoreKit configuration file for local testing
- [ ] Create sandbox test accounts
- [ ] Test IAP purchase flow in sandbox

### 13.5 IAP Manager Service

- [ ] [COMPLEX] Create `IAPManager` service with StoreKit 2
- [ ] [COMPLEX] Implement product fetching from App Store
- [ ] [COMPLEX] Implement purchase flow with error handling
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

**Model Strategy**:
- [COMPLEX] markers use Sonnet for advanced logic
- Unmarked tasks use Haiku for speed
- Build failures automatically use Sonnet

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
