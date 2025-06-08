#!/usr/bin/env bats

load test_helper

# Test setup
setup() {
    setup_test_environment
    init_mock_log
    
    export INSTALL_SCRIPT="$KEYCUTTER_ROOT/install.sh"
    
    # Mock git and other commands
    create_mock_command "git" 0 "Cloning into 'keycutter'..."
    create_mock_command "keycutter" 0 ""
}

# Test cleanup
teardown() {
    cleanup_test_environment
}

@test "install script sets up installation directory" {
    # Mock that directory doesn't exist
    export INSTALL_DIR="$TEST_HOME/.local/share/keycutter"
    
    run bash "$INSTALL_SCRIPT"
    
    # Should attempt to clone repository
    assert_mock_called "git clone.*keycutter"
}

@test "install script updates existing repository" {
    # Create fake existing repository
    export INSTALL_DIR="$TEST_HOME/.local/share/keycutter"
    mkdir -p "$INSTALL_DIR/.git"
    echo "https://github.com/mbailey/keycutter.git" > "$INSTALL_DIR/.git/remote_url_mock"
    
    # Mock git remote get-url
    create_mock_command "git" 0 "https://github.com/mbailey/keycutter.git"
    
    run bash "$INSTALL_SCRIPT"
    
    # Should attempt to pull updates
    assert_mock_called "git.*pull"
}

@test "install script creates binary symlink" {
    export INSTALL_DIR="$TEST_HOME/.local/share/keycutter"
    export BIN_DIR="$TEST_HOME/.local/bin"
    
    # Create fake installation
    mkdir -p "$INSTALL_DIR/bin"
    echo "#!/bin/bash" > "$INSTALL_DIR/bin/keycutter"
    chmod +x "$INSTALL_DIR/bin/keycutter"
    
    run bash "$INSTALL_SCRIPT"
    
    # Should create bin directory
    assert_dir_exists "$BIN_DIR"
}

@test "install script sets up bash completion" {
    export INSTALL_DIR="$TEST_HOME/.local/share/keycutter"
    
    # Create completion directories
    mkdir -p "$TEST_HOME/.local/share/bash-completion/completions"
    mkdir -p "$INSTALL_DIR/shell/completions"
    echo "# completion script" > "$INSTALL_DIR/shell/completions/keycutter.bash"
    
    run bash "$INSTALL_SCRIPT"
    
    # Should reference completion installation
    [[ "$output" =~ "completion" ]] || [[ "$output" =~ "Bash completion" ]]
}

@test "install script warns about PATH when needed" {
    export INSTALL_DIR="$TEST_HOME/.local/share/keycutter"
    export BIN_DIR="$TEST_HOME/.local/bin"
    export PATH="/usr/bin:/bin"  # Don't include BIN_DIR
    
    run bash "$INSTALL_SCRIPT"
    
    [[ "$output" =~ "Warning.*PATH" ]] || [[ "$output" =~ "not in your PATH" ]]
}

@test "install script runs keycutter update when in PATH" {
    export INSTALL_DIR="$TEST_HOME/.local/share/keycutter"
    export BIN_DIR="$TEST_HOME/.local/bin"
    export PATH="$BIN_DIR:$PATH"
    
    # Create fake keycutter binary in PATH
    mkdir -p "$BIN_DIR"
    echo "#!/bin/bash" > "$BIN_DIR/keycutter"
    chmod +x "$BIN_DIR/keycutter"
    
    run bash "$INSTALL_SCRIPT"
    
    assert_mock_called "keycutter update"
}

@test "install script handles repository URL mismatch" {
    export INSTALL_DIR="$TEST_HOME/.local/share/keycutter"
    mkdir -p "$INSTALL_DIR/.git"
    
    # Mock git to return different URL
    create_mock_command "git" 0 "https://github.com/different/repo.git"
    
    run bash "$INSTALL_SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "different git repository" ]]
}

@test "install script uses XDG environment variables" {
    export XDG_DATA_HOME="$TEST_HOME/.local/share/custom"
    export XDG_BIN_HOME="$TEST_HOME/.local/bin/custom"
    
    run bash "$INSTALL_SCRIPT"
    
    # Should use custom XDG paths
    [[ "$output" =~ "$XDG_DATA_HOME" ]] || [[ "$output" =~ "custom" ]]
}