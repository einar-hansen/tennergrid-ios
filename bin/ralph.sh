#!/usr/bin/env bash
set -euo pipefail

# ralph_ios.sh - iOS/Swift version of Ralph Wiggum task automation
# Unset API key to force Claude Code to use subscription
unset ANTHROPIC_API_KEY

# Add signal handling for clean exit
INTERRUPT_FLAG="/tmp/ralph_interrupt_$$"
trap 'handle_interrupt' INT TERM

handle_interrupt() {
  echo -e "\n${YELLOW}[WARN]${NC} Interrupt signal received. Cleaning up..."
  touch "$INTERRUPT_FLAG"

  # Kill any running xcodebuild processes spawned by this script
  pkill -P $$ xcodebuild 2>/dev/null || true

  # Clean up interrupt flag on exit
  rm -f "$INTERRUPT_FLAG" 2>/dev/null || true

  echo -e "${GREEN}[INFO]${NC} Exiting gracefully..."
  exit 130
}

# Check for interrupt flag at start of each iteration
check_interrupt() {
  if [[ -f "$INTERRUPT_FLAG" ]]; then
    log_info "Interrupt flag detected. Exiting."
    rm -f "$INTERRUPT_FLAG"
    exit 130
  fi
}

# Usage: ./ralph_ios.sh [max_iterations] [tasks_file] [scheme_name]
MAX_ITERATIONS=${1:-50}
TASKS_FILE=${2:-tasks.md}
SCHEME_NAME=${3:-TennerGrid}
COMPLETE_FLAG="tasks_complete"
BUILD_FAILED_FLAG="build_failed"
BUILD_ERROR_LOG="/tmp/ralph_build_errors.log"

# Model configuration - Hybrid approach
DEFAULT_MODEL="haiku"      # Fast model for simple tasks
COMPLEX_MODEL="sonnet"     # Powerful model for complex tasks
CLEAN_INTERVAL=5           # Run clean build every N iterations

# Configuration
XCODE_PROJECT="TennerGrid.xcodeproj"  # Change to your project name
XCODE_WORKSPACE=""  # Set to "TennerGrid.xcworkspace" if using CocoaPods/SPM
# TEST_DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=latest"
TEST_DESTINATION="platform=iOS Simulator,id=2B6CC595-D05B-456B-8DE0-F70C454F354C"


# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
  echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_model() {
  echo -e "${MAGENTA}[MODEL]${NC} $1"
}

# Check if tasks file exists
if [[ ! -f "$TASKS_FILE" ]]; then
  log_error "Tasks file '$TASKS_FILE' not found."
  exit 1
fi

# Check if Xcode project exists
if [[ -n "$XCODE_WORKSPACE" ]] && [[ ! -d "$XCODE_WORKSPACE" ]]; then
  log_error "Xcode workspace '$XCODE_WORKSPACE' not found."
  exit 1
elif [[ -z "$XCODE_WORKSPACE" ]] && [[ ! -d "$XCODE_PROJECT" ]]; then
  log_error "Xcode project '$XCODE_PROJECT' not found."
  exit 1
fi

# Determine build flag
if [[ -n "$XCODE_WORKSPACE" ]]; then
  BUILD_FLAG="-workspace $XCODE_WORKSPACE"
else
  BUILD_FLAG="-project $XCODE_PROJECT"
fi

log_info "Starting Ralph iOS automation"
log_info "Default model: $DEFAULT_MODEL | Complex model: $COMPLEX_MODEL"
log_info "Clean interval: every ${CLEAN_INTERVAL} iterations"
log_info "Tip: Mark complex tasks with [COMPLEX] to use $COMPLEX_MODEL"
echo ""

for i in $(seq 1 "$MAX_ITERATIONS"); do
  ITERATION_START=$(date +%s)
  check_interrupt  # Check if we should exit before starting iteration

  log_info "=========================================="
  log_info "Starting iteration $i of $MAX_ITERATIONS"
  log_info "=========================================="

  # Exit if we've created the completion flag
  if [[ -f "$COMPLETE_FLAG" ]]; then
    log_info "All tasks completed (found $COMPLETE_FLAG). Exiting."
    exit 0
  fi

  # Determine if this is a clean build iteration
  SHOULD_CLEAN=false
  if (( i % CLEAN_INTERVAL == 0 )); then
    SHOULD_CLEAN=true
    log_info "Clean build scheduled for this iteration"
  fi

  # Check if build is currently failing
  BUILD_IS_FAILING=false
  if [[ -f "$BUILD_FAILED_FLAG" ]]; then
    BUILD_IS_FAILING=true
    log_error "🚨 Build failure detected from previous iteration!"
    log_error "Priority: Fix compilation errors before continuing with tasks"
  fi

  # Determine which model to use based on task complexity
  ITERATION_MODEL="$DEFAULT_MODEL"

  if [[ "$BUILD_IS_FAILING" == true ]]; then
    # Build failures might need the smarter model
    ITERATION_MODEL="$COMPLEX_MODEL"
    log_model "Using $COMPLEX_MODEL for build failure fix"
  else
    # Check the next task for complexity markers
    CURRENT_TASK=$(grep -m 1 "^- \[ \]" "$TASKS_FILE" || echo "")

    if [[ "$CURRENT_TASK" == *"[COMPLEX]"* ]]; then
      ITERATION_MODEL="$COMPLEX_MODEL"
      log_model "Complex task detected, using $COMPLEX_MODEL"
      log_debug "Task: $CURRENT_TASK"
    elif [[ "$CURRENT_TASK" == *"[SIMPLE]"* ]]; then
      ITERATION_MODEL="$DEFAULT_MODEL"
      log_model "Simple task detected, using $DEFAULT_MODEL"
      log_debug "Task: $CURRENT_TASK"
    else
      # No marker - use default
      ITERATION_MODEL="$DEFAULT_MODEL"
      log_model "Using default model: $DEFAULT_MODEL"
    fi
  fi

  # Prepare the agent prompt
  if [[ "$BUILD_IS_FAILING" == true ]]; then
    # Build is broken - tell agent to fix it
    AGENT_PROMPT=$(cat <<PROMPT
🚨 **CRITICAL: BUILD IS CURRENTLY FAILING** 🚨

The project failed to compile in the previous iteration. You MUST fix the compilation errors before working on any other tasks.

Build error log is available at: $BUILD_ERROR_LOG

Your task for this iteration:
1. Review the compilation errors in $BUILD_ERROR_LOG
2. Check the recent git history to see what has changed or introduced the errors
3. Fix ALL compilation errors to get the build passing
4. Test that the build succeeds by running:
   xcodebuild build $BUILD_FLAG -scheme "$SCHEME_NAME" -destination "$TEST_DESTINATION"
5. Commit your fixes with message: "Fix compilation errors"

DO NOT work on any tasks from $TASKS_FILE until the build is fixed.

Project context:
- Scheme: $SCHEME_NAME
- Build command: xcodebuild build $BUILD_FLAG -scheme "$SCHEME_NAME" -destination "$TEST_DESTINATION"

Common Swift compilation errors and fixes:
- Duplicate declarations: Remove or rename the duplicate
- Missing imports: Add required import statements
- Type mismatches: Fix type annotations or conversions
- Access control: Adjust public/private/internal modifiers
- Protocol conformance: Implement required methods/properties

Once the build succeeds, the build_failed flag will be automatically removed and normal task work will resume.
PROMPT
)
  else
    # Build is working - proceed with normal tasks
    log_info "Reading tasks from $TASKS_FILE..."

    # Check if there are any uncompleted tasks (lines starting with "- [ ]")
    UNCOMPLETED_COUNT=$(grep -c "^- \[ \]" "$TASKS_FILE" || true)

    if [[ $UNCOMPLETED_COUNT -eq 0 ]]; then
      log_info "No uncompleted tasks found. Creating completion flag."
      touch "$COMPLETE_FLAG"
      exit 0
    fi

    log_info "Found $UNCOMPLETED_COUNT uncompleted task(s)."

    AGENT_PROMPT=$(cat <<PROMPT
You are working through a task list for an iOS/Swift project, one task at a time.

Current tasks file ($TASKS_FILE):
\`\`\`markdown
$(cat "$TASKS_FILE")
\`\`\`

Your instructions:
1. Read the tasks file above carefully.
2. Select EXACTLY ONE uncompleted task (marked with "- [ ]") to work on.
   - Choose the first uncompleted task in the list, OR
   - Choose the most important/blocking task if priority is indicated
   - Ignore any [COMPLEX] or [SIMPLE] markers - these are for the automation script
3. Complete that ONE task fully and thoroughly.
4. For feature tasks: Write the implementation following SwiftUI/Swift best practices
5. For test tasks: Write comprehensive XCTest unit tests with good coverage
6. Build the project to verify no compilation errors:
   xcodebuild build $BUILD_FLAG -scheme "$SCHEME_NAME" -destination "$TEST_DESTINATION"
7. If there are compilation errors, fix them before proceeding
8. Run the relevant tests (or full test suite if appropriate):
   xcodebuild test $BUILD_FLAG -scheme "$SCHEME_NAME" -destination "$TEST_DESTINATION"
9. Ensure all tests pass
10. Commit your changes with a descriptive message mentioning which task you completed
11. After committing, mark the task as done by changing "- [ ]" to "- [x]" in $TASKS_FILE
12. Report which task you completed and summarize what you did

Important:
- Work on ONLY ONE task this iteration
- YOU must build and test - the script will verify after you're done
- Do NOT create the completion flag - the script handles that automatically
- If a task is unclear or blocked, mark it with "- [?]" and explain why in the commit message
- Follow iOS/Swift best practices: MVVM architecture, SwiftUI, Combine, async/await
- Write clean, testable code with proper separation of concerns
- Use guard statements for early returns
- Prefer structs over classes when possible
- Use proper error handling (Result, throws, try/catch)

Project context:
- Scheme: $SCHEME_NAME
- You can build with: xcodebuild build $BUILD_FLAG -scheme "$SCHEME_NAME" -destination "$TEST_DESTINATION"
- You can test with: xcodebuild test $BUILD_FLAG -scheme "$SCHEME_NAME" -destination "$TEST_DESTINATION"

Focus on quality over speed. Make sure each task is truly complete before marking it done.
PROMPT
)
  fi

  check_interrupt  # Check before calling agent

  # Call the agent with the selected model
  AGENT_START=$(date +%s)
  log_info "Calling Claude Code agent..."
  log_model "Active model: $ITERATION_MODEL"
  echo ""

  claude --print \
    --no-session-persistence \
    --model "$ITERATION_MODEL" \
    --permission-mode acceptEdits \
    "$AGENT_PROMPT"

  AGENT_END=$(date +%s)
  AGENT_DURATION=$((AGENT_END - AGENT_START))
  echo ""
  log_debug "Agent completed in ${AGENT_DURATION}s"

  check_interrupt  # Check after agent completes

  echo ""
  log_info "Running quality checks..."
  echo ""

  # Step 1: Build verification
  BUILD_START=$(date +%s)

  if [[ "$SHOULD_CLEAN" == true ]]; then
    log_info "Running clean build (iteration $i / $CLEAN_INTERVAL)..."
    BUILD_CMD="xcodebuild clean build"
  else
    log_info "Running incremental build..."
    BUILD_CMD="xcodebuild build"
  fi

  if $BUILD_CMD \
    $BUILD_FLAG \
    -scheme "$SCHEME_NAME" \
    -destination "$TEST_DESTINATION" \
    -quiet \
    2>&1 | tee "$BUILD_ERROR_LOG"; then

    BUILD_END=$(date +%s)
    BUILD_DURATION=$((BUILD_END - BUILD_START))
    log_info "✓ Build succeeded (${BUILD_DURATION}s)"

    # Remove build failed flag if it exists
    if [[ -f "$BUILD_FAILED_FLAG" ]]; then
      log_info "Removing build failed flag (build now passing)"
      rm "$BUILD_FAILED_FLAG"
    fi
  else
    BUILD_END=$(date +%s)
    BUILD_DURATION=$((BUILD_END - BUILD_START))
    log_error "✗ Build failed (${BUILD_DURATION}s). Creating build failed flag."

    # Create the build failed flag
    echo "Build failed at iteration $i on $(date)" > "$BUILD_FAILED_FLAG"

    log_error "Build errors have been logged to: $BUILD_ERROR_LOG"
    log_error "Next iteration will prioritize fixing these compilation errors."

    # Commit current state so agent can see what failed
    if [[ -n "$(git status --porcelain)" ]]; then
      git add -A
      git commit -m "Ralph iOS: iteration $i - build failed (errors logged)" || true
    fi

    # Calculate iteration time and continue
    ITERATION_END=$(date +%s)
    ITERATION_DURATION=$((ITERATION_END - ITERATION_START))
    echo ""
    log_info "=== Iteration $i Complete (build failed) - ${ITERATION_DURATION}s ==="
    echo "  Model used: $ITERATION_MODEL"
    echo "  Next iteration will focus on fixing compilation errors"
    echo ""
    echo "---"
    echo ""
    continue
  fi

  check_interrupt  # Check before tests

  # Step 2: Run tests (only if build succeeded)
  # Skip if agent likely already ran them
  if [[ "$BUILD_IS_FAILING" == true ]]; then
    # If we just fixed a build failure, run tests to verify
    TEST_START=$(date +%s)
    log_info "Running tests to verify build fix..."
    if xcodebuild test \
      $BUILD_FLAG \
      -scheme "$SCHEME_NAME" \
      -destination "$TEST_DESTINATION" \
      -quiet; then
      TEST_END=$(date +%s)
      TEST_DURATION=$((TEST_END - TEST_START))
      log_info "✓ All tests passed (${TEST_DURATION}s)"
    else
      TEST_END=$(date +%s)
      TEST_DURATION=$((TEST_END - TEST_START))
      log_warn "✗ Some tests failed (${TEST_DURATION}s). Review test output above."
    fi
  else
    log_info "Skipping test run (agent should have run tests already)"
  fi

  check_interrupt  # Check before linting

  # Step 3: Run SwiftLint (if installed)
  if command -v swiftlint &> /dev/null; then
    log_info "Running SwiftLint..."
    if swiftlint lint --quiet; then
      log_info "✓ SwiftLint passed"
    else
      log_warn "✗ SwiftLint found issues. Attempting auto-fix..."
      swiftlint lint --fix --quiet || true
    fi
  else
    log_debug "SwiftLint not installed. Install with: brew install swiftlint"
  fi

  # Step 4: Run SwiftFormat (if installed)
  if command -v swiftformat &> /dev/null; then
    log_info "Running SwiftFormat..."
    swiftformat . --swiftversion 5.9 --quiet
    log_info "✓ SwiftFormat completed"
  else
    log_debug "SwiftFormat not installed. Install with: brew install swiftformat"
  fi

  check_interrupt  # Check before commit

  # Step 5: Commit changes (if agent didn't already)
  if [[ -n "$(git status --porcelain)" ]]; then
    log_info "Committing changes..."
    git add -A
    git commit -m "Ralph iOS: automated task completion (iteration $i)" || true
    log_info "✓ Changes committed"
  else
    log_info "No changes to commit (agent may have already committed)"
  fi

  # Calculate iteration time
  ITERATION_END=$(date +%s)
  ITERATION_DURATION=$((ITERATION_END - ITERATION_START))

  # Print progress
  echo ""
  log_info "=========================================="
  log_info "Iteration $i Complete - ${ITERATION_DURATION}s total"
  log_info "=========================================="

  REMAINING=$(grep -c "^- \[ \]" "$TASKS_FILE" || echo "0")
  COMPLETED=$(grep -c "^- \[x\]" "$TASKS_FILE" || echo "0")
  echo "  Model used: $ITERATION_MODEL"
  echo "  Completed tasks: $COMPLETED"
  echo "  Remaining tasks: $REMAINING"
  if [[ $((COMPLETED + REMAINING)) -gt 0 ]]; then
    PROGRESS=$(( (COMPLETED * 100) / (COMPLETED + REMAINING) ))
    echo "  Progress: ${PROGRESS}%"
  fi
  echo ""
  log_debug "Timing breakdown:"
  log_debug "  - Agent: ${AGENT_DURATION}s"
  log_debug "  - Build: ${BUILD_DURATION}s"
  if [[ -n "${TEST_DURATION:-}" ]]; then
    log_debug "  - Tests: ${TEST_DURATION}s"
  fi
  echo ""
  echo "---"
  echo ""
done

log_warn "Reached maximum iterations ($MAX_ITERATIONS). Exiting."
exit 0
