# Makefile for keycutter

.PHONY: test test-verbose test-help install clean shellcheck help release

# Default target
help:
	@echo "Available targets:"
	@echo "  test          - Run all BATS tests"
	@echo "  test-verbose  - Run tests with verbose output"
	@echo "  test-help     - Show test-specific help"
	@echo "  shellcheck    - Run shellcheck on all shell scripts"
	@echo "  install       - Install keycutter"
	@echo "  clean         - Clean up test artifacts"
	@echo "  release       - Create a new release (tags, pushes, creates GitHub release)"
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

# Release - Create a new release and tag
release:
	@echo "Creating a new keycutter release..."
	@echo ""
	@echo "Checking git status..."
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "Error: Working directory is not clean. Please commit or stash changes."; \
		git status; \
		exit 1; \
	fi
	@echo "✅ Working directory is clean"
	@echo ""
	@latest_tag=$$(git tag -l --sort=-version:refname | head -1); \
	if [ -z "$$latest_tag" ]; then \
		echo "No previous tags found. This will be the first release."; \
		suggested_version="v1.0.0"; \
	else \
		echo "Latest tag: $$latest_tag"; \
		suggested_version=$$(echo $$latest_tag | sed 's/^v//' | awk -F. '{print "v" $$1 "." $$2 "." $$3+1}'); \
	fi; \
	echo "Suggested version: $$suggested_version"; \
	echo ""; \
	read -p "Enter new version (e.g., v1.0.0): " version; \
	if [ -z "$$version" ]; then \
		echo "Error: Version cannot be empty"; \
		exit 1; \
	fi; \
	if ! echo "$$version" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "Error: Version must be in format v1.2.3"; \
		exit 1; \
	fi; \
	if git tag -l | grep -q "^$$version$$"; then \
		echo "Error: Tag $$version already exists"; \
		exit 1; \
	fi; \
	echo "Updating CHANGELOG.md..."; \
	date=$$(date +%Y-%m-%d); \
	sed -i.bak "s/## \[Unreleased\]/## [Unreleased]\n\n## [$$version] - $$date/" CHANGELOG.md && \
	rm CHANGELOG.md.bak; \
	git add CHANGELOG.md && \
	git commit -m "chore: release $$version" && \
	git tag -a "$$version" -m "Release $$version" && \
	echo "" && \
	echo "✅ Version tagged!" && \
	echo "" && \
	echo "Pushing to GitHub..." && \
	git push origin && \
	git push origin "$$version" && \
	echo "" && \
	echo "🚀 Release created!" && \
	echo "" && \
	echo "Next steps:" && \
	echo "1. Go to: https://github.com/mbailey/keycutter/releases" && \
	echo "2. Edit the $$version release" && \
	echo "3. Copy the changelog section for this version" && \
	echo "4. Publish the release"