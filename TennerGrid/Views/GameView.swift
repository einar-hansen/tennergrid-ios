import SwiftUI

/// The main game view composing all game UI components
struct GameView: View {
    // MARK: - Properties

    /// The view model managing game state
    @StateObject private var viewModel: GameViewModel

    /// Scene phase for detecting app backgrounding
    @Environment(\.scenePhase) private var scenePhase

    /// Size class to detect iPad vs iPhone
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Whether the pause menu is showing
    @State private var showingPauseMenu = false

    /// Whether the settings sheet is showing
    @State private var showingSettings = false

    /// Whether the win screen is showing
    @State private var showingWinScreen = false

    /// Focus state for keyboard input
    @FocusState private var isGameFocused: Bool

    /// Persisted zoom level for grid (0.5x to 2.0x)
    @AppStorage("gridZoomLevel") private var persistedZoomLevel: Double = 1.0

    /// Current zoom scale for grid
    @State private var gridZoomScale: CGFloat = 1.0

    /// Callback when user quits the game (for navigation to home)
    var onQuit: (() -> Void)?

    /// Callback when user starts a new game (for navigation to difficulty selection)
    var onNewGame: (() -> Void)?

    // MARK: - Computed Properties

    /// Check if running on iPad based on size classes
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    /// Vertical spacing between components - larger on iPad
    private var verticalSpacing: CGFloat {
        isIPad ? 24 : 16
    }

    // MARK: - Initialization

    /// Creates a new GameView with the given puzzle
    /// - Parameter puzzle: The puzzle to play
    init(puzzle: TennerGridPuzzle) {
        _viewModel = StateObject(wrappedValue: GameViewModel(puzzle: puzzle))
    }

    /// Creates a new GameView with the given view model
    /// - Parameter viewModel: The view model to use
    init(viewModel: GameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main game content
            gameContent
                .blur(radius: viewModel.gameState.isPaused ? 10 : 0)
                .disabled(viewModel.gameState.isPaused)
                .animation(.easeInOut(duration: 0.25), value: viewModel.gameState.isPaused)

            // Pause overlay
            if viewModel.gameState.isPaused {
                pauseOverlay
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }

            // Achievement unlock notifications
            AchievementUnlockNotificationContainer(
                achievements: .init(
                    get: { viewModel.newlyUnlockedAchievements },
                    set: { _ in }
                )
            )

            // Zoom controls (bottom-trailing corner)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZoomControlView(
                        onZoomIn: handleZoomIn,
                        onZoomOut: handleZoomOut,
                        onResetZoom: handleResetZoom,
                        currentZoom: gridZoomScale
                    )
                    .padding(.trailing, isIPad ? 24 : 16)
                    .padding(.bottom, isIPad ? 24 : 16)
                }
            }
            .opacity(viewModel.gameState.isPaused ? 0 : 1)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.gameState.isPaused)
        .modifier(KeyboardSupportModifier(viewModel: viewModel, isGameFocused: $isGameFocused))
        .onAppear {
            // Initialize zoom from persisted value
            gridZoomScale = CGFloat(persistedZoomLevel)
        }
        .onChange(of: viewModel.gameState.isCompleted) { isCompleted in
            if isCompleted {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay for completion animation
                    showingWinScreen = true
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            settingsPlaceholder
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingWinScreen) {
            winScreenPlaceholder
                .presentationDetents([.large])
                .interactiveDismissDisabled()
        }
        .modifier(ScenePhaseModifier(scenePhase: scenePhase, viewModel: viewModel))
    }

    // MARK: - Subviews

    /// Main game content layout - adapts to portrait or landscape
    private var gameContent: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape layout
                landscapeLayout
            } else {
                // Portrait layout (original)
                portraitLayout
            }
        }
    }

    /// Portrait layout - vertical arrangement
    private var portraitLayout: some View {
        VStack(spacing: verticalSpacing) {
            // Header with timer, difficulty, and controls
            GameHeaderView(
                viewModel: viewModel,
                onPause: handlePause,
                onSettings: handleSettings
            )

            Spacer()

            // Main puzzle grid
            GridView(viewModel: viewModel, zoomScale: $gridZoomScale)

            Spacer()

            // Game toolbar with action buttons
            GameToolbarView(viewModel: viewModel)
                .padding(.bottom, isIPad ? 12 : 8)

            // Number pad for input
            NumberPadView(viewModel: viewModel)
                .padding(.bottom, isIPad ? 24 : 16)
        }
    }

    /// Landscape layout - horizontal arrangement
    private var landscapeLayout: some View {
        HStack(spacing: isIPad ? 32 : 20) {
            // Left side: Grid takes most of the space
            VStack(spacing: isIPad ? 12 : 8) {
                // Compact header for landscape
                GameHeaderView(
                    viewModel: viewModel,
                    onPause: handlePause,
                    onSettings: handleSettings
                )

                // Main puzzle grid
                GridView(viewModel: viewModel, zoomScale: $gridZoomScale)
            }
            .frame(maxWidth: .infinity)

            // Right side: Controls in a vertical stack
            VStack(spacing: isIPad ? 24 : 16) {
                Spacer()

                // Game toolbar with action buttons
                GameToolbarView(viewModel: viewModel)

                Spacer()
                    .frame(maxHeight: isIPad ? 50 : 40)

                // Number pad for input
                NumberPadView(viewModel: viewModel)

                Spacer()
            }
            .frame(maxWidth: isIPad ? 500 : 400) // Larger control panel on iPad
            .padding(.trailing, isIPad ? 24 : 16)
        }
        .padding(.horizontal, isIPad ? 24 : 16)
    }

    /// Pause overlay shown when game is paused
    private var pauseOverlay: some View {
        PauseMenuView(
            onResume: handleResume,
            onRestart: handleRestart,
            onNewGame: handleNewGame,
            onSettings: handleSettings,
            onQuit: handleQuit
        )
        .transition(.opacity)
    }

    /// Settings view with close button
    private var settingsPlaceholder: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingSettings = false
                        }
                    }
                }
        }
    }

    /// Win screen displayed when puzzle is completed
    private var winScreenPlaceholder: some View {
        WinScreenView(
            difficulty: viewModel.gameState.puzzle.difficulty,
            elapsedTime: viewModel.elapsedTime,
            hintsUsed: viewModel.gameState.hintsUsed,
            errorCount: viewModel.gameState.errorCount,
            onNewGame: {
                showingWinScreen = false
                handleNewGame()
            },
            onChangeDifficulty: {
                showingWinScreen = false
                handleNewGame()
            },
            onHome: {
                showingWinScreen = false
                handleQuit()
            }
        )
    }

    // MARK: - Actions

    /// Handles the pause button tap
    private func handlePause() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.pauseTimer()
        }
    }

    /// Handles the resume button tap
    private func handleResume() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.resumeTimer()
        }
    }

    /// Handles the settings button tap
    private func handleSettings() {
        showingSettings = true
    }

    /// Handles the restart button tap
    /// Resets the game to its initial state
    private func handleRestart() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Create a new game state from the same puzzle
            let newGameState = GameState(puzzle: viewModel.gameState.puzzle)
            viewModel.resetToState(newGameState)
            viewModel.resumeTimer()
        }
    }

    /// Handles the new game button tap
    /// Triggers navigation to difficulty selection
    private func handleNewGame() {
        onNewGame?()
    }

    /// Handles the quit button tap
    /// Triggers navigation back to home
    private func handleQuit() {
        onQuit?()
    }

    // MARK: - Zoom Controls

    /// Zoom in the grid by 0.25x
    private func handleZoomIn() {
        let newZoom = min(gridZoomScale + 0.25, 2.0)
        withAnimation(.easeOut(duration: 0.2)) {
            gridZoomScale = newZoom
        }
        persistedZoomLevel = Double(newZoom)
    }

    /// Zoom out the grid by 0.25x
    private func handleZoomOut() {
        let newZoom = max(gridZoomScale - 0.25, 0.5)
        withAnimation(.easeOut(duration: 0.2)) {
            gridZoomScale = newZoom
        }
        persistedZoomLevel = Double(newZoom)
    }

    /// Reset zoom to 1.0x
    private func handleResetZoom() {
        withAnimation(.easeOut(duration: 0.2)) {
            gridZoomScale = 1.0
        }
        persistedZoomLevel = 1.0
    }
}

// MARK: - Scene Phase Modifier

/// A view modifier that handles app backgrounding/foregrounding
private struct ScenePhaseModifier: ViewModifier {
    let scenePhase: ScenePhase
    @ObservedObject var viewModel: GameViewModel

    @State private var previousPhase: ScenePhase = .active

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _ in
                handleScenePhaseChange()
            }
    }

    /// Handles changes in scene phase (app backgrounding/foregrounding)
    private func handleScenePhaseChange() {
        switch scenePhase {
        case .background:
            // App is going to background - pause and save
            viewModel.handleAppBackground()
            previousPhase = .background
        case .active:
            // App is becoming active - resume if needed
            if previousPhase == .background || previousPhase == .inactive {
                viewModel.handleAppForeground()
            }
            previousPhase = .active
        case .inactive:
            // App is inactive (e.g., user pressed home or opened app switcher)
            // Pause timer immediately to prevent time from elapsing while not actively playing
            // Don't change game pause state - user can still resume when returning to active
            if viewModel.isTimerRunning {
                viewModel.pauseTimerWithoutPausingGame()
            }
            previousPhase = .inactive
        @unknown default:
            break
        }
    }
}

// MARK: - Keyboard Support Modifier

/// A view modifier that adds hardware keyboard support for the game
/// On iOS 17+, supports number keys 0-9 for entry, backspace for clearing, and arrow keys for navigation
/// On iOS 16, keyboard support is not available (requires on-screen controls)
private struct KeyboardSupportModifier: ViewModifier {
    /// The game view model to send input to
    @ObservedObject var viewModel: GameViewModel

    /// Focus state binding for keyboard input
    @FocusState.Binding var isGameFocused: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .focusable()
                .focused($isGameFocused)
                .onAppear {
                    isGameFocused = true
                }
                .modifier(KeyboardInputModifierIOS17(viewModel: viewModel))
        } else {
            // iOS 16 fallback - hardware keyboard support is not available
            // Users must use the on-screen number pad
            content
        }
    }
}

/// iOS 17+ specific keyboard input handler
/// Separated to avoid availability warnings in the main modifier
@available(iOS 17.0, *)
private struct KeyboardInputModifierIOS17: ViewModifier {
    /// The game view model to send input to
    @ObservedObject var viewModel: GameViewModel

    /// Number keys 0-9
    private static let numberKeys: Set<KeyEquivalent> = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    ]

    /// Delete/backspace keys
    private static let deleteKeys: Set<KeyEquivalent> = [
        .delete,
    ]

    /// Arrow keys for navigation
    private static let arrowKeys: Set<KeyEquivalent> = [
        .upArrow, .downArrow, .leftArrow, .rightArrow,
    ]

    func body(content: Content) -> some View {
        content
            .onKeyPress(keys: Self.numberKeys) { keyPress in
                handleNumberKey(keyPress)
            }
            .onKeyPress(keys: Self.deleteKeys) { _ in
                handleDeleteKey()
            }
            .onKeyPress(keys: Self.arrowKeys) { keyPress in
                handleArrowKey(keyPress)
            }
    }

    // MARK: - Key Handlers

    /// Handles number key presses (0-9)
    private func handleNumberKey(_ keyPress: KeyPress) -> KeyPress.Result {
        guard !viewModel.gameState.isPaused,
              !viewModel.gameState.isCompleted
        else {
            return .ignored
        }

        // Extract the number from the key character
        guard let character = keyPress.characters.first,
              let number = Int(String(character)),
              number >= 0, number <= 9
        else {
            return .ignored
        }

        // Enter the number
        viewModel.enterNumber(number)
        return .handled
    }

    /// Handles delete/backspace key presses
    private func handleDeleteKey() -> KeyPress.Result {
        guard !viewModel.gameState.isPaused,
              !viewModel.gameState.isCompleted,
              viewModel.selectedPosition != nil
        else {
            return .ignored
        }

        // Clear the selected cell
        viewModel.clearSelectedCell()
        return .handled
    }

    /// Handles arrow key presses for cell navigation
    private func handleArrowKey(_ keyPress: KeyPress) -> KeyPress.Result {
        guard !viewModel.gameState.isPaused,
              !viewModel.gameState.isCompleted
        else {
            return .ignored
        }

        let puzzle = viewModel.gameState.puzzle
        let currentPosition = viewModel.selectedPosition ?? CellPosition(row: 0, column: 0)

        var newRow = currentPosition.row
        var newColumn = currentPosition.column

        switch keyPress.key {
        case .upArrow:
            newRow = max(0, currentPosition.row - 1)
        case .downArrow:
            newRow = min(puzzle.rows - 1, currentPosition.row + 1)
        case .leftArrow:
            newColumn = max(0, currentPosition.column - 1)
        case .rightArrow:
            newColumn = min(puzzle.columns - 1, currentPosition.column + 1)
        default:
            return .ignored
        }

        let newPosition = CellPosition(row: newRow, column: newColumn)
        if newPosition != currentPosition {
            viewModel.selectCell(at: newPosition)
        }

        return .handled
    }
}

// MARK: - Previews

#Preview("Game View - Easy") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
}

#Preview("Game View - Medium") {
    GameView(puzzle: PreviewPuzzles.medium4Row)
}

#Preview("Game View - Hard") {
    GameView(puzzle: PreviewPuzzles.hard5Row)
}

#Preview("Dark Mode") {
    GameView(puzzle: PreviewPuzzles.medium5Row)
        .preferredColorScheme(.dark)
}

#Preview("iPhone SE - Small") {
    GameView(puzzle: PreviewPuzzles.easy3Row)
}

#Preview("iPhone 15 Pro Max") {
    GameView(puzzle: PreviewPuzzles.hard5Row)
}

#Preview("iPad") {
    GameView(puzzle: PreviewPuzzles.hard7Row)
}

#Preview("Landscape - iPhone") {
    GameView(puzzle: PreviewPuzzles.medium5Row)
        .previewInterfaceOrientation(.landscapeLeft)
}

#Preview("Landscape - iPad") {
    GameView(puzzle: PreviewPuzzles.hard7Row)
        .previewInterfaceOrientation(.landscapeRight)
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
}
