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
  # Clean up temp file
  rm -f "$STREAM_TMPFILE" 2>/dev/null || true
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
TESTS_FAILED_FLAG="tests_failed"
BUILD_ERROR_LOG="/tmp/ralph_build_errors.log"
TEST_OUTPUT="test_output.txt"
MODEL="sonnet"

# jq filters for streaming output
STREAM_TEXT='select(.type == "assistant").message.content[]? | select(.type == "text").text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'
FINAL_RESULT='select(.type == "result").result // empty'

# Temp file for capturing stream output
STREAM_TMPFILE="/tmp/ralph_stream_$$"

# Configuration
XCODE_PROJECT="TennerGrid.xcodeproj"  # Change to your project name
XCODE_WORKSPACE=""  # Set to "TennerGrid.xcworkspace" if using CocoaPods/SPM
TEST_DESTINATION="platform=iOS Simulator,name=iPhone 17"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to run claude with streaming output
run_claude_streaming() {
  local prompt="$1"
  local tmpfile="$STREAM_TMPFILE"

  # Clean up any existing temp file
  rm -f "$tmpfile"

  echo "$prompt" | claude \
    --print \
    --verbose \
    --output-format stream-json \
    --model "$MODEL" \
    --permission-mode acceptEdits \
  | grep --line-buffered '^{' \
  | tee "$tmpfile" \
  | jq --unbuffered -rj "$STREAM_TEXT"

  # Return the result for checking
  if [[ -f "$tmpfile" ]]; then
    jq -r "$FINAL_RESULT" "$tmpfile" 2>/dev/null || true
  fi
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

for i in $(seq 1 "$MAX_ITERATIONS"); do
  check_interrupt  # Check if we should exit before starting iteration

  log_info "Starting iteration $i of $MAX_ITERATIONS"

  # Exit if we've created the completion flag
  if [[ -f "$COMPLETE_FLAG" ]]; then
    log_info "All tasks completed (found $COMPLETE_FLAG). Exiting."
    rm -f "$STREAM_TMPFILE" 2>/dev/null || true
    exit 0
  fi

  # Check if build is currently failing
  BUILD_IS_FAILING=false
  if [[ -f "$BUILD_FAILED_FLAG" ]]; then
    BUILD_IS_FAILING=true
    log_error "🚨 Build failure detected from previous iteration!"
    log_error "Priority: Fix compilation errors before continuing with tasks"
  fi

  # Check if tests are currently failing
  TESTS_ARE_FAILING=false
  if [[ -f "$TESTS_FAILED_FLAG" ]]; then
    TESTS_ARE_FAILING=true
    log_warn "⚠️ Test failures detected from previous iteration!"
    log_warn "Priority: Fix failing tests before continuing with new tasks"
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
4. Test that the build succeeds
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

  elif [[ "$TESTS_ARE_FAILING" == true ]]; then
    # Tests are failing - tell agent to fix them
    AGENT_PROMPT=$(cat <<PROMPT
⚠️ **PRIORITY: TESTS ARE CURRENTLY FAILING** ⚠️

Some tests failed in the previous iteration. You should fix the failing tests before working on new tasks.

Test output is available at: $TEST_OUTPUT

Your task for this iteration:
1. Review the test failures in $TEST_OUTPUT
2. Identify which tests are failing and why
3. Fix the failing tests (either fix the test or fix the code being tested)
4. Run tests locally to verify they pass
5. Commit your fixes with message: "Fix failing tests"

Current tasks file ($TASKS_FILE):
\`\`\`markdown
$(cat "$TASKS_FILE")
\`\`\`

Project context:
- Scheme: $SCHEME_NAME
- Test command: xcodebuild test $BUILD_FLAG -scheme "$SCHEME_NAME" -destination "$TEST_DESTINATION"

Common test failure causes:
- Assertion failures: Check expected vs actual values
- Async test timeouts: Ensure expectations are fulfilled
- Setup/teardown issues: Check test fixtures
- Mock/stub mismatches: Verify mock configurations

Once all tests pass, the tests_failed flag will be automatically removed and normal task work will resume.
PROMPT
)

  else
    # Build is working, tests are passing - proceed with normal tasks
    log_info "Reading tasks from $TASKS_FILE..."

    # Check if there are any uncompleted tasks (lines starting with "- [ ]")
    UNCOMPLETED_COUNT=$(grep -c "^- \[ \]" "$TASKS_FILE" || true)

    if [[ $UNCOMPLETED_COUNT -eq 0 ]]; then
      log_info "No uncompleted tasks found. Creating completion flag."
      touch "$COMPLETE_FLAG"
      rm -f "$STREAM_TMPFILE" 2>/dev/null || true
      exit 0
    fi

    log_info "Found $UNCOMPLETED_COUNT uncompleted task(s)."

    AGENT_PROMPT=$(cat <<PROMPT
You are working through a task list for an iOS/Swift project, one incomplete sub section of tasks at a time.

Current tasks file ($TASKS_FILE):
\`\`\`markdown
$(cat "$TASKS_FILE")
\`\`\`

Your instructions:
1. Read the tasks file above carefully.
2. Select EXACTLY section of a phase with uncompleted tasks (marked with "- [ ]") to work on.
   - Choose the first uncompleted sub section of tasks (for example 4.5 etc) in the list, OR
   - Choose the most important/blocking task if priority is indicated
3. Complete that ONE task fully and thoroughly.
4. For feature tasks: Write the implementation following SwiftUI/Swift best practices
5. For test tasks: Write comprehensive XCTest unit tests with good coverage
6. Build the project and fix any compilation errors
8. Run SwiftLint and fix any warnings/errors
9. Run SwiftFormat to ensure consistent code style
10. Commit your changes with a descriptive message mentioning which task you completed.
11. After completing the task, mark it as done by changing "- [ ]" to "- [x]" in $TASKS_FILE.
12. Report which task you completed and summarize what you did.

Important:
- Work on ONLY ONE task this iteration.
- Do NOT create the completion flag - the script handles that automatically.
- If a task is unclear or blocked, mark it with "- [?]" and explain why in the commit message.
- Follow iOS/Swift best practices: MVVM architecture, SwiftUI, Combine, async/await
- Write clean, testable code with proper separation of concerns
- Use guard statements for early returns
- Prefer structs over classes when possible
- Use proper error handling (Result, throws, try/catch)

Project context:
- Scheme: $SCHEME_NAME
- Linting: swiftlint
- Formatting: swiftformat

Focus on quality over speed. Make sure each task is truly complete before marking it done.
PROMPT
)
  fi

  check_interrupt  # Check before calling agent

  # Call the agent with streaming output
  log_info "Calling Claude Code agent... Model $MODEL (streaming)..."
  echo ""
  run_claude_streaming "$AGENT_PROMPT"
  echo ""

  check_interrupt  # Check after agent completes

  echo ""
  log_info "Agent completed. Running quality checks..."
  echo ""

  # Step 1: Build the project
  log_info "Building project..."
  if xcodebuild build \
    $BUILD_FLAG \
    -scheme "$SCHEME_NAME" \
    -destination "$TEST_DESTINATION" \
    2>&1 | tee "$BUILD_ERROR_LOG"; then
    log_info "✓ Build succeeded"
    # Remove build failed flag if it exists
    if [[ -f "$BUILD_FAILED_FLAG" ]]; then
      log_info "Removing build failed flag (build now passing)"
      rm "$BUILD_FAILED_FLAG"
    fi
  else
    log_error "✗ Build failed. Creating build failed flag."
    # Create the build failed flag
    echo "Build failed at iteration $i on $(date)" > "$BUILD_FAILED_FLAG"
    log_error "Build errors have been logged to: $BUILD_ERROR_LOG"
    log_error "Next iteration will prioritize fixing these compilation errors."

    # Commit current state so agent can see what failed
    if [[ -n "$(git status --porcelain)" ]]; then
      git add -A
      git commit -m "Ralph iOS: iteration $i - build failed (errors logged)" || true
    fi

    # Continue to next iteration to fix the build
    echo ""
    log_info "=== Iteration $i Complete (build failed) ==="
    echo "  Next iteration will focus on fixing compilation errors"
    echo ""
    echo "---"
    echo ""
    continue
  fi

  check_interrupt  # Check before tests

  # Step 2: Run tests (only if build succeeded)
  log_info "Running tests..."
  TESTS_PASSED=true
  if xcodebuild test \
    $BUILD_FLAG \
    -scheme "$SCHEME_NAME" \
    -destination "$TEST_DESTINATION" \
    -quiet 2>&1 | tee "$TEST_OUTPUT"; then
    log_info "✓ All tests passed"
    # Remove tests failed flag if it exists
    if [[ -f "$TESTS_FAILED_FLAG" ]]; then
      log_info "Removing tests failed flag (all tests now passing)"
      rm "$TESTS_FAILED_FLAG"
    fi
  else
    log_warn "✗ Some tests failed."
    TESTS_PASSED=false
    echo "Tests failed at iteration $i on $(date)" > "$TESTS_FAILED_FLAG"
  fi

  check_interrupt  # Check before test review

  # Step 2.5: Review test output with Claude (separate call)
  if [[ "$TESTS_PASSED" == false ]]; then
    log_info "Calling Claude to review test failures..."

    TEST_REVIEW_PROMPT=$(cat <<PROMPT
Review the following test output and provide a brief analysis:

Test output ($TEST_OUTPUT):
\`\`\`
$(tail -200 "$TEST_OUTPUT")
\`\`\`

Please provide:
1. A summary of which tests failed
2. The likely root cause of each failure
3. Suggested fixes (be specific about which files/methods to change)

Keep your response concise and actionable. This analysis will be used in the next iteration to fix the failures.
PROMPT
)

    # Run Claude to review test output (using streaming for analysis)
    log_info "Test failure analysis:"
    echo ""
    run_claude_streaming "$TEST_REVIEW_PROMPT" | tee /tmp/test_analysis.txt
    echo ""

    log_warn "Test failures detected. Next iteration will prioritize fixing them."

    # Commit current state
    if [[ -n "$(git status --porcelain)" ]]; then
      git add -A
      git commit -m "Ralph iOS: iteration $i - tests failing (analysis logged)" || true
    fi

    echo ""
    log_info "=== Iteration $i Complete (tests failed) ==="
    echo "  Next iteration will focus on fixing test failures"
    echo ""
    echo "---"
    echo ""
    continue
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
    log_warn "SwiftLint not installed. Skipping. Install with: brew install swiftlint"
  fi

  # Step 4: Run SwiftFormat (if installed)
  if command -v swiftformat &> /dev/null; then
    log_info "Running SwiftFormat..."
    swiftformat . --swiftversion 5.9 --quiet
    log_info "✓ SwiftFormat completed"
  else
    log_warn "SwiftFormat not installed. Skipping. Install with: brew install swiftformat"
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

  # Print progress
  echo ""
  log_info "=== Iteration $i Complete ==="
  REMAINING=$(grep -c "^- \[ \]" "$TASKS_FILE" || echo "0")
  COMPLETED=$(grep -c "^- \[x\]" "$TASKS_FILE" || echo "0")
  echo "  Completed tasks: $COMPLETED"
  echo "  Remaining tasks: $REMAINING"
  if [[ $((COMPLETED + REMAINING)) -gt 0 ]]; then
    echo "  Progress: $(( (COMPLETED * 100) / (COMPLETED + REMAINING) ))%"
  fi
  echo ""
  echo "---"
  echo ""
done

# Clean up temp file
rm -f "$STREAM_TMPFILE" 2>/dev/null || true

log_warn "Reached maximum iterations ($MAX_ITERATIONS). Exiting."
exit 0
