#!/usr/bin/env bash
# Test runner for keycutter BATS tests

set -euo pipefail

# Get the directory containing this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Check if BATS is available
if ! command -v bats &>/dev/null; then
    log "$RED" "Error: BATS (Bash Automated Testing System) is not installed."
    log "$YELLOW" "Install BATS with one of:"
    log "$BLUE" "  # Via package manager:"
    log "$BLUE" "  sudo apt install bats"
    log "$BLUE" "  sudo dnf install bats"
    log "$BLUE" "  brew install bats-core"
    log "$BLUE" ""
    log "$BLUE" "  # Or from source:"
    log "$BLUE" "  git clone https://github.com/bats-core/bats-core.git"
    log "$BLUE" "  cd bats-core"
    log "$BLUE" "  sudo ./install.sh /usr/local"
    exit 1
fi

# Change to project root
cd "$PROJECT_ROOT"

log "$BLUE" "Running keycutter BATS tests..."
log "$BLUE" "Project root: $PROJECT_ROOT"
log "$BLUE" "Test directory: $TEST_DIR"
echo

# Set test environment
export KEYCUTTER_ROOT="$PROJECT_ROOT"

# Parse arguments
VERBOSE=false
TEST_FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            log "$BLUE" "Usage: $0 [--verbose] [test_file...]"
            log "$BLUE" ""
            log "$BLUE" "Options:"
            log "$BLUE" "  --verbose, -v    Run tests with verbose output"
            log "$BLUE" "  --help, -h       Show this help message"
            log "$BLUE" ""
            log "$BLUE" "Examples:"
            log "$BLUE" "  $0                           # Run all tests"
            log "$BLUE" "  $0 --verbose                 # Run all tests verbosely"
            log "$BLUE" "  $0 test_keycutter.bats       # Run specific test"
            log "$BLUE" "  $0 -v test_keycutter.bats    # Run specific test verbosely"
            exit 0
            ;;
        *)
            TEST_FILES+=("$1")
            shift
            ;;
    esac
done

# Set BATS options
BATS_OPTS=""
if $VERBOSE; then
    BATS_OPTS="--verbose-run"
    log "$YELLOW" "Running in verbose mode..."
fi

# Run specific test file if provided, otherwise run all tests
if [[ ${#TEST_FILES[@]} -gt 0 ]]; then
    for test_file in "${TEST_FILES[@]}"; do
        if [[ -f "$TEST_DIR/$test_file" ]]; then
            log "$YELLOW" "Running $test_file..."
            bats $BATS_OPTS "$TEST_DIR/$test_file"
        elif [[ -f "$test_file" ]]; then
            log "$YELLOW" "Running $test_file..."
            bats $BATS_OPTS "$test_file"
        else
            log "$RED" "Test file not found: $test_file"
            exit 1
        fi
    done
else
    log "$YELLOW" "Running all tests..."
    bats $BATS_OPTS "$TEST_DIR"/*.bats
fi

log "$GREEN" "Tests completed!"