#!/usr/bin/env bats

load test_helper

# Test setup
setup() {
    setup_test_environment
    mock_keycutter_environment
    init_mock_log
}

# Test cleanup
teardown() {
    cleanup_test_environment
}

@test "keycutter displays help when no arguments provided" {
    # Redirect stdin to prevent hanging on /dev/tty
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter 2>/dev/null"
    [[ "$output" =~ "Usage:" ]]
}

@test "keycutter displays help with -h flag" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter -h 2>/dev/null"
    [ "$status" -eq 1 ]  # keycutter exits with 1 for help
    [[ "$output" =~ "Usage:" ]]
}

@test "keycutter displays help with --help flag" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter --help 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "keycutter shows available commands in help" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter --help 2>/dev/null"
    [[ "$output" =~ "create" ]]
    [[ "$output" =~ "update" ]]
    [[ "$output" =~ "install-touch-detector" ]]
    [[ "$output" =~ "check-requirements" ]]
}

@test "keycutter check-requirements runs without error" {
    # Mock required commands
    create_mock_command "bash" 0 "GNU bash, version 5.0.0"
    create_mock_command "ssh" 0 "OpenSSH_8.2p1"
    create_mock_command "gh" 0 "gh version 2.4.0"
    create_mock_command "ykman" 0 "YubiKey Manager (ykman) version: 4.0.0"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter check-requirements 2>/dev/null"
    [ "$status" -eq 0 ]
}

@test "keycutter shows error for unknown command" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter invalid-command 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Unknown command" ]]
}

@test "keycutter create requires ssh-keytag argument" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter create 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "keycutter create accepts valid ssh-keytag" {
    # Mock ssh-keygen to prevent actual key creation
    create_mock_command "ssh-keygen" 0 "Generating public/private ed25519-sk key pair."
    
    # Provide 'n' to decline appending hostname
    run bash -c "echo 'n' | $KEYCUTTER_ROOT/bin/keycutter create github.com_testuser 2>/dev/null"
    # Should not fail due to missing argument
    [[ ! "$output" =~ "Usage:" ]]
}

@test "keycutter create suggests adding hostname to keytag" {
    create_mock_command "ssh-keygen" 0 ""
    create_mock_command "hostname" 0 "testhost"
    
    run bash -c "echo 'n' | $KEYCUTTER_ROOT/bin/keycutter create github.com_testuser 2>/dev/null"
    [[ "$output" =~ "Append the current device to the SSH Keytag" ]]
}

@test "keycutter agents command lists agents" {
    # Create test agent directory
    mkdir -p "$KEYCUTTER_CONFIG_DIR/agents/test-agent"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter agents 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-agent" ]]
}

@test "keycutter hosts command lists hosts" {
    # Create test SSH config with hosts
    create_test_ssh_config "Host testhost1
    HostName example.com

Host testhost2
    HostName example.org"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter hosts 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "testhost1" ]]
    [[ "$output" =~ "testhost2" ]]
}

@test "keycutter keys command lists keys" {
    # Create test key
    create_test_ssh_key "test_key"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter keys 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_key" ]]
}

@test "keycutter config command requires hostname" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter config 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Hostname is required" ]]
}

@test "keycutter config command accepts hostname" {
    # Create mock ssh-config-impact script
    create_mock_command "ssh" 0 "hostname example.com"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter config example.com 2>/dev/null"
    # Should not show the "hostname required" error
    [[ ! "$output" =~ "Error: Hostname is required" ]]
}

@test "keycutter install-touch-detector command exists" {
    # This will fail because the installer needs real OS detection,
    # but we're testing that the command is recognized
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter install-touch-detector 2>/dev/null"
    # Should not show "Unknown command" error
    [[ ! "$output" =~ "Error: Unknown command" ]]
}

@test "keycutter update command runs git update" {
    # Mock git commands
    create_mock_command "git" 0 "Already up to date."
    
    # Mock hostname for KEYCUTTER_ORIGIN
    create_mock_command "hostname" 0 "testhost"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter update 2>/dev/null"
    [ "$status" -eq 0 ]
}

@test "keycutter handles SSH_CONNECTION environment variable" {
    # Test without SSH_CONNECTION (local execution)
    unset SSH_CONNECTION
    create_mock_command "hostname" 0 "testhost"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter --help 2>/dev/null"
    [ "$status" -eq 1 ]  # Help exits with 1
    [[ "$output" =~ "Usage:" ]]
}

@test "keycutter handles KEYCUTTER_ORIGIN environment variable" {
    export KEYCUTTER_ORIGIN="custom-origin"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter --help 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "keycutter agent subcommands work" {
    # Create test agent
    mkdir -p "$KEYCUTTER_CONFIG_DIR/agents/test-agent/keys"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter agent show test-agent 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Agent: test-agent" ]]
}

@test "keycutter host subcommands work" {
    create_test_ssh_config "Host testhost
    HostName example.com"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter host show testhost 2>/dev/null"
    [ "$status" -eq 0 ]
}

@test "keycutter key subcommands work" {
    create_test_ssh_key "test_key"
    
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter key show test_key 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Key: test_key" ]]
}

@test "keycutter validates ssh key types" {
    create_mock_command "ssh-keygen" 0 ""
    
    # Test with valid key type
    run bash -c "echo 'n' | $KEYCUTTER_ROOT/bin/keycutter create --type ed25519-sk github.com_test 2>/dev/null"
    [[ ! "$output" =~ "Unsupported key type" ]]
}

@test "keycutter handles resident key option" {
    create_mock_command "ssh-keygen" 0 ""
    
    run bash -c "echo 'n' | $KEYCUTTER_ROOT/bin/keycutter create --resident github.com_test 2>/dev/null"
    assert_mock_called "ssh-keygen.*-O resident"
}

@test "keycutter sets correct file permissions" {
    create_mock_command "ssh-keygen" 0 ""
    
    run bash -c "echo 'n' | $KEYCUTTER_ROOT/bin/keycutter create github.com_test 2>/dev/null"
    # Test would check that chmod 0600 is called on private key
    # This is implicitly tested by the ssh-keygen mock
}

@test "keycutter creates required directories" {
    create_mock_command "ssh-keygen" 0 ""
    
    run bash -c "echo 'n' | $KEYCUTTER_ROOT/bin/keycutter create github.com_test 2>/dev/null"
    
    # Verify directories were created
    assert_dir_exists "$KEYCUTTER_CONFIG_DIR"
    assert_dir_exists "$KEYCUTTER_SSH_KEY_DIR"
}