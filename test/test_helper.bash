#!/usr/bin/env bash
# BATS test helper functions for keycutter

# Set up test environment
setup_test_environment() {
    export TEST_HOME="$BATS_TMPDIR/keycutter_test_home"
    export HOME="$TEST_HOME"
    export KEYCUTTER_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export KEYCUTTER_CONFIG="$TEST_HOME/.ssh/keycutter/keycutter.conf"
    export KEYCUTTER_CONFIG_DIR="$TEST_HOME/.ssh/keycutter"
    export KEYCUTTER_SSH_KEY_DIR="$TEST_HOME/.ssh/keycutter/keys"
    
    # Enable test mode to prevent stdin reattachment
    export KEYCUTTER_TEST_MODE=1
    
    # Prevent actual git operations during tests
    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_SYSTEM=/dev/null
    
    # Create test directories
    mkdir -p "$TEST_HOME/.ssh/keycutter/"{keys,agents,hosts,scripts,sockets}
    mkdir -p "$TEST_HOME/.local/bin"
    mkdir -p "$TEST_HOME/.config/systemd/user"
    mkdir -p "$TEST_HOME/go/bin"
    
    # Create minimal mock bin directory for essential commands
    mkdir -p "$BATS_TMPDIR/mock_bin"
    export PATH="$BATS_TMPDIR/mock_bin:$PATH"
    
    # Only mock the most essential commands to prevent system modifications
    create_mock_command "sudo" 0 ""
    create_mock_command "systemctl" 0 ""
    create_mock_command "launchctl" 0 ""
}

# Clean up test environment
cleanup_test_environment() {
    rm -rf "$TEST_HOME" 2>/dev/null || true
    rm -rf "$BATS_TMPDIR/mock_bin" 2>/dev/null || true
}

# Create a mock command that logs its invocation
create_mock_command() {
    local cmd_name="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"
    
    cat > "$BATS_TMPDIR/mock_bin/$cmd_name" << EOF
#!/bin/bash
echo "MOCK_CALL: $cmd_name \$@" >> "$BATS_TMPDIR/mock_calls.log"
if [[ -n "$output" ]]; then
    echo "$output"
fi
exit $exit_code
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/$cmd_name"
}

# Check if a mock command was called with specific arguments
assert_mock_called() {
    local expected_call="$1"
    [[ -f "$BATS_TMPDIR/mock_calls.log" ]] || return 1
    grep -q "MOCK_CALL: $expected_call" "$BATS_TMPDIR/mock_calls.log"
}

# Assert that output contains a specific string
assert_contains() {
    local expected="$1"
    local actual="$2"
    [[ "$actual" == *"$expected"* ]]
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

# Create a test SSH key for testing
create_test_ssh_key() {
    local key_name="$1"
    local key_path="$KEYCUTTER_SSH_KEY_DIR/$key_name"
    
    mkdir -p "$(dirname "$key_path")"
    
    # Create fake SSH key files
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$key_path"
    echo "fake-private-key-content" >> "$key_path"
    echo "-----END OPENSSH PRIVATE KEY-----" >> "$key_path"
    
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAKEKEY $key_name" > "$key_path.pub"
    
    chmod 600 "$key_path"
    chmod 644 "$key_path.pub"
}

# Create a test SSH config
create_test_ssh_config() {
    local config_content="$1"
    
    mkdir -p "$TEST_HOME/.ssh"
    echo "$config_content" > "$TEST_HOME/.ssh/config"
}

# Skip test if command is not available
skip_if_missing() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        skip "$cmd is not available"
    fi
}

# Mock the keycutter environment
mock_keycutter_environment() {
    # Create basic keycutter structure
    mkdir -p "$KEYCUTTER_CONFIG_DIR"/{keys,agents,hosts,scripts,sockets}
    
    # Create a basic config file
    cat > "$KEYCUTTER_CONFIG" << 'EOF'
# Keycutter SSH Configuration
Include keycutter/hosts/*
Include keycutter/agents/*/config
EOF
    
    # Mock some common commands
    create_mock_command "ssh-keygen" 0 "Generating public/private ed25519 key pair."
    create_mock_command "systemctl" 0 ""
    create_mock_command "launchctl" 0 ""
    create_mock_command "gh" 0 ""
    create_mock_command "git" 0 ""
}

# Initialize mock calls log
init_mock_log() {
    echo > "$BATS_TMPDIR/mock_calls.log"
}

# Set up a fake OS environment for testing
mock_os_environment() {
    local os_type="$1"
    local pretty_name="${2:-}"
    
    case "$os_type" in
        "linux")
            export OSTYPE="linux-gnu"
            # Create a test os-release file in the test tmp directory
            mkdir -p "$BATS_TMPDIR/etc"
            if [[ -n "$pretty_name" ]]; then
                echo "PRETTY_NAME=\"$pretty_name\"" > "$BATS_TMPDIR/etc/os-release"
            else
                echo 'PRETTY_NAME="Test Linux Distribution"' > "$BATS_TMPDIR/etc/os-release"
            fi
            # Mock commands to prevent detection of existing installations
            create_mock_command "command" 1 ""  # command -v returns not found
            create_mock_command "systemctl" 1 ""  # systemctl returns not active
            create_mock_command "dnf" 0 ""
            ;;
        "macos")
            export OSTYPE="darwin22"
            create_mock_command "sw_vers" 0 "14.2.1"
            create_mock_command "brew" 0 ""
            # Mock commands to prevent detection of existing installations
            create_mock_command "command" 1 ""  # command -v returns not found
            create_mock_command "launchctl" 1 ""  # launchctl list returns empty
            ;;
    esac
}

# Verify that no real system modifications occurred
assert_no_system_modifications() {
    # Check that we didn't modify real system files
    [[ ! -f "/usr/local/bin/yubikey-touch-detector" ]]
    [[ ! -f "$HOME/.ssh/config" ]] || [[ "$HOME" == "$TEST_HOME" ]]
}