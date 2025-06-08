# Makefile for keycutter

.PHONY: test test-verbose test-help install clean shellcheck help

# Default target
help:
	@echo "Available targets:"
	@echo "  test          - Run all BATS tests"
	@echo "  test-verbose  - Run tests with verbose output"
	@echo "  test-help     - Show test-specific help"
	@echo "  shellcheck    - Run shellcheck on all shell scripts"
	@echo "  install       - Install keycutter"
	@echo "  clean         - Clean up test artifacts"
	@echo "  help          - Show this help message"

# Run all tests
test:
	@./test/run_tests.sh

# Run tests with verbose output
test-verbose:
	@./test/run_tests.sh --verbose

# Show test help
test-help:
	@echo "Test commands:"
	@echo "  make test                    - Run all tests"
	@echo "  make test-verbose            - Run tests with verbose output"
	@echo "  ./test/run_tests.sh <file>   - Run specific test file"
	@echo "  bats test/<file>.bats        - Run specific test with BATS directly"
	@echo ""
	@echo "Example:"
	@echo "  ./test/run_tests.sh test_keycutter.bats"
	@echo "  bats test/test_keycutter.bats -f 'help'"

# Run shellcheck on all shell scripts
shellcheck:
	@echo "Running shellcheck on all shell scripts..."
	@find . -name "*.sh" -o -name "keycutter" -o -path "*/lib/*" -type f | \
		grep -v test/ | \
		xargs shellcheck -f gcc || echo "Some shellcheck issues found"

# Install keycutter
install:
	@./install.sh

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	@rm -rf test/tmp/ 2>/dev/null || true
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@echo "Clean complete"