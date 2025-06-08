#!/usr/bin/env bats

load test_helper

# Test setup
setup() {
    setup_test_environment
    init_mock_log
    
    # Make the installer executable and available
    export INSTALLER_SCRIPT="$KEYCUTTER_ROOT/libexec/keycutter/install-touch-detector"
    chmod +x "$INSTALLER_SCRIPT"
}

# Test cleanup
teardown() {
    cleanup_test_environment
}

@test "touch detector installer detects Linux OS" {
    mock_os_environment "linux"
    
    run bash -c "echo 'n' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "Detected:" ]]
    [[ "$output" =~ "Linux" ]]
}

@test "touch detector installer detects macOS" {
    mock_os_environment "macos"
    
    run bash -c "echo 'n' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "Detected:" ]]
    [[ "$output" =~ "macOS" ]]
}

@test "touch detector installer shows OS-specific pretty name on Linux" {
    mock_os_environment "linux"
    echo 'PRETTY_NAME="Fedora Linux 42 (Workstation Edition)"' > /etc/os-release
    
    run bash -c "echo 'n' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "Fedora Linux 42" ]]
}

@test "touch detector installer prompts for Linux installation" {
    mock_os_environment "linux"
    
    run bash -c "echo 'n' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "Install yubikey-touch-detector via Go build?" ]]
}

@test "touch detector installer prompts for macOS installation" {
    mock_os_environment "macos"
    
    run bash -c "echo 'n' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "Install yknotify for YubiKey touch notifications?" ]]
}

@test "touch detector installer cancels on 'n' response" {
    mock_os_environment "linux"
    
    run bash -c "echo 'n' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "Installation cancelled" ]]
}

@test "touch detector installer detects existing installation" {
    mock_os_environment "linux"
    create_mock_command "yubikey-touch-detector" 0 ""
    
    run bash -c "echo | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "already installed" ]]
}

@test "touch detector installer handles Arch Linux package manager" {
    mock_os_environment "linux"
    create_mock_command "pacman" 0 "yubikey-touch-detector"
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "from Arch repository" ]]
}

@test "touch detector installer installs dependencies for Fedora" {
    mock_os_environment "linux"
    create_mock_command "dnf" 0 ""
    create_mock_command "go" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    assert_mock_called "dnf install -y gpgme-devel golang"
}

@test "touch detector installer installs dependencies for Ubuntu" {
    mock_os_environment "linux"
    create_mock_command "apt-get" 0 ""
    create_mock_command "go" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    assert_mock_called "apt-get update -qq"
    assert_mock_called "apt-get install -y libgpgme-dev golang"
}

@test "touch detector installer uses Go to build yubikey-touch-detector" {
    mock_os_environment "linux"
    create_mock_command "go" 0 ""
    create_mock_command "dnf" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    # Create fake go binary
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yubikey-touch-detector"
    chmod +x "$TEST_HOME/go/bin/yubikey-touch-detector"
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    assert_mock_called "go install github.com/maximbaz/yubikey-touch-detector@latest"
}

@test "touch detector installer installs binary to XDG user directory" {
    mock_os_environment "linux"
    create_mock_command "go" 0 ""
    create_mock_command "dnf" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    # Create fake go binary
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yubikey-touch-detector"
    chmod +x "$TEST_HOME/go/bin/yubikey-touch-detector"
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    
    # Should install to ~/.local/bin
    [[ "$output" =~ "/.local/bin/yubikey-touch-detector" ]]
}

@test "touch detector installer sets up systemd service on Linux" {
    mock_os_environment "linux"
    create_mock_command "go" 0 ""
    create_mock_command "dnf" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    # Create fake go binary and systemd files
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yubikey-touch-detector"
    chmod +x "$TEST_HOME/go/bin/yubikey-touch-detector"
    
    # Mock git clone by creating the files directly
    mkdir -p "$BATS_TMPDIR/yubikey-touch-detector"
    cat > "$BATS_TMPDIR/yubikey-touch-detector/yubikey-touch-detector.service" << 'EOF'
[Unit]
Description=Detects when your YubiKey is waiting for a touch

[Service]
ExecStart=/usr/bin/yubikey-touch-detector

[Install]
WantedBy=default.target
EOF
    
    cat > "$BATS_TMPDIR/yubikey-touch-detector/yubikey-touch-detector.socket" << 'EOF'
[Unit]
Description=YubiKey touch detector socket

[Socket]
ListenStream=/run/user/%i/yubikey-touch-detector.socket

[Install]
WantedBy=sockets.target
EOF
    
    # Override git clone to use our test files
    create_mock_command "git" 0 ""
    
    run bash -c "echo -e 'y\n1' | BATS_TMPDIR='$BATS_TMPDIR' $INSTALLER_SCRIPT 2>/dev/null"
    
    assert_mock_called "systemctl --user daemon-reload"
}

@test "touch detector installer handles systemd service options" {
    mock_os_environment "linux"
    create_mock_command "go" 0 ""
    create_mock_command "dnf" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    # Create test environment
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yubikey-touch-detector"
    chmod +x "$TEST_HOME/go/bin/yubikey-touch-detector"
    
    # Test "always running" option
    run bash -c "echo -e 'y\n1' | $INSTALLER_SCRIPT 2>/dev/null"
    assert_mock_called "systemctl --user enable --now yubikey-touch-detector.service"
}

@test "touch detector installer installs yknotify on macOS" {
    mock_os_environment "macos"
    create_mock_command "go" 0 ""
    create_mock_command "brew" 0 ""
    create_mock_command "launchctl" 0 ""
    
    # Create fake go binary
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yknotify"
    chmod +x "$TEST_HOME/go/bin/yknotify"
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    assert_mock_called "go install github.com/noperator/yknotify@latest"
}

@test "touch detector installer sets up LaunchAgent on macOS" {
    mock_os_environment "macos"
    create_mock_command "go" 0 ""
    create_mock_command "brew" 0 ""
    create_mock_command "launchctl" 0 ""
    create_mock_command "command" 0 ""
    
    # Create fake go binary
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yknotify"
    chmod +x "$TEST_HOME/go/bin/yknotify"
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    
    # Should create LaunchAgent directory and files
    assert_dir_exists "$TEST_HOME/Library/LaunchAgents"
    assert_mock_called "launchctl load.*com.user.yknotify.plist"
}

@test "touch detector installer handles missing dependencies gracefully" {
    mock_os_environment "linux"
    # Don't create go or pkg-config commands
    
    run bash -c "echo 'y' | $INSTALLER_SCRIPT 2>/dev/null"
    [[ "$output" =~ "Error:" ]] || [[ "$output" =~ "not installed" ]]
}

@test "touch detector installer rejects unsupported OS" {
    export OSTYPE="unknown-os"
    
    run bash -c "echo | $INSTALLER_SCRIPT 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unsupported operating system" ]]
}

@test "touch detector installer updates systemd service path" {
    mock_os_environment "linux"
    create_mock_command "go" 0 ""
    create_mock_command "dnf" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    # Create fake binary and test files
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yubikey-touch-detector"
    chmod +x "$TEST_HOME/go/bin/yubikey-touch-detector"
    
    run bash -c "echo -e 'y\n3' | $INSTALLER_SCRIPT 2>/dev/null"
    
    # Should mention the correct binary path
    [[ "$output" =~ "/.local/bin/yubikey-touch-detector" ]]
}

@test "touch detector installer creates config directory structure" {
    mock_os_environment "linux"
    create_mock_command "go" 0 ""
    create_mock_command "dnf" 0 ""
    create_mock_command "pkg-config" 0 ""
    create_mock_command "git" 0 ""
    create_mock_command "systemctl" 0 ""
    
    mkdir -p "$TEST_HOME/go/bin"
    echo "fake binary" > "$TEST_HOME/go/bin/yubikey-touch-detector"
    chmod +x "$TEST_HOME/go/bin/yubikey-touch-detector"
    
    run bash -c "echo -e 'y\n3' | $INSTALLER_SCRIPT 2>/dev/null"
    
    # Should create systemd user directory
    assert_dir_exists "$TEST_HOME/.config/systemd/user"
}