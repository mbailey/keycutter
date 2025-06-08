# Keycutter Tests

This directory contains BATS (Bash Automated Testing System) tests for the keycutter project.

## Requirements

- [BATS](https://github.com/bats-core/bats-core) testing framework

### Install BATS

**Package manager:**
```bash
# Ubuntu/Debian
sudo apt install bats

# Fedora
sudo dnf install bats

# macOS
brew install bats-core
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### All tests
```bash
./test/run_tests.sh
```

### Specific test file
```bash
./test/run_tests.sh test_keycutter.bats
bats test/test_keycutter.bats
```

### Individual test
```bash
bats test/test_keycutter.bats -f "keycutter displays help"
```

## Test Files

- **`test_keycutter.bats`** - Tests for main keycutter CLI
- **`test_install_touch_detector.bats`** - Tests for touch detector installer
- **`test_ssh_config_impact.bats`** - Tests for SSH config analysis
- **`test_install.bats`** - Tests for main installation script
- **`test_helper.bash`** - Shared helper functions and test utilities

## Test Structure

Each test file follows this pattern:
```bash
#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_environment
}

teardown() {
    cleanup_test_environment
}

@test "descriptive test name" {
    run command_to_test
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected_output" ]]
}
```

## Helper Functions

The `test_helper.bash` provides:
- `setup_test_environment()` - Creates isolated test environment
- `cleanup_test_environment()` - Cleans up test files
- `create_mock_command()` - Creates mock commands for testing
- `assert_mock_called()` - Verifies mock commands were called
- `assert_contains()` - Checks if output contains text
- `assert_file_exists()` - Verifies file existence

## Test Environment

Tests run in isolated environments:
- `$TEST_HOME` - Isolated home directory
- `$BATS_TMPDIR` - Temporary directory for test artifacts
- Mock commands replace real system commands
- No actual system modifications occur

## Writing Tests

### Good practices:
- Test both success and failure cases
- Use descriptive test names
- Mock external dependencies
- Clean up test artifacts
- Test argument validation
- Verify error messages

### Example:
```bash
@test "command shows error when missing required argument" {
    run bin/my-command
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Missing required argument" ]]
}

@test "command processes valid input correctly" {
    run bin/my-command --input "valid-value"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Success" ]]
}
```