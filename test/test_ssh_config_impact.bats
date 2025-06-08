#!/usr/bin/env bats

load test_helper

# Test setup
setup() {
    setup_test_environment
    mock_keycutter_environment
    
    # Make the script executable and available
    export SSH_CONFIG_SCRIPT="$KEYCUTTER_ROOT/libexec/keycutter/ssh-config-impact"
    chmod +x "$SSH_CONFIG_SCRIPT"
    
    # Mock ssh command for testing
    create_mock_command "ssh" 0 "hostname example.com
user testuser
port 22
identityfile $TEST_HOME/.ssh/keycutter/keys/test_key"
}

# Test cleanup
teardown() {
    cleanup_test_environment
}

@test "ssh-config-impact requires hostname argument" {
    run "$SSH_CONFIG_SCRIPT"
    [ "$status" -ne 0 ]
}

@test "ssh-config-impact accepts hostname argument" {
    run "$SSH_CONFIG_SCRIPT" "example.com"
    [ "$status" -eq 0 ]
}

@test "ssh-config-impact calls ssh -G with hostname" {
    run "$SSH_CONFIG_SCRIPT" "example.com"
    assert_mock_called "ssh -G example.com"
}

@test "ssh-config-impact handles hostname with special characters" {
    run "$SSH_CONFIG_SCRIPT" "test-host.example.com"
    [ "$status" -eq 0 ]
    assert_mock_called "ssh -G test-host.example.com"
}

@test "ssh-config-impact shows relevant configuration" {
    run "$SSH_CONFIG_SCRIPT" "example.com"
    [ "$status" -eq 0 ]
    # Should show formatted output from ssh -G
}

@test "ssh-config-impact handles missing hostname gracefully" {
    run "$SSH_CONFIG_SCRIPT" ""
    [ "$status" -ne 0 ]
}

@test "ssh-config-impact works with IPv4 addresses" {
    run "$SSH_CONFIG_SCRIPT" "192.168.1.100"
    [ "$status" -eq 0 ]
    assert_mock_called "ssh -G 192.168.1.100"
}

@test "ssh-config-impact works with IPv6 addresses" {
    run "$SSH_CONFIG_SCRIPT" "2001:db8::1"
    [ "$status" -eq 0 ]
    assert_mock_called "ssh -G 2001:db8::1"
}

@test "ssh-config-impact handles ssh command failure" {
    create_mock_command "ssh" 1 "ssh: Could not resolve hostname"
    
    run "$SSH_CONFIG_SCRIPT" "nonexistent.example.com"
    [ "$status" -eq 1 ]
}

@test "ssh-config-impact processes multiple configuration lines" {
    # Mock ssh to return multiple config lines
    create_mock_command "ssh" 0 "hostname example.com
user testuser
port 2222
identityfile /path/to/key
forwardagent yes"
    
    run "$SSH_CONFIG_SCRIPT" "example.com"
    [ "$status" -eq 0 ]
    # Output should contain the ssh -G results
}