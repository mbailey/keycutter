#!/usr/bin/env bats

load test_helper

# Test setup
setup() {
    setup_test_environment
    mock_keycutter_environment
    init_mock_log

    # Remove git mock - we need real git for these tests
    rm -f "$BATS_TMPDIR/mock_bin/git"

    # Create a test git repository
    export TEST_GIT_REPO="$TEST_HOME/test-repo"
    mkdir -p "$TEST_GIT_REPO"
    cd "$TEST_GIT_REPO"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create a mock SSH key for testing
    export TEST_KEY_DIR="$KEYCUTTER_SSH_KEY_DIR"
    mkdir -p "$TEST_KEY_DIR"
    echo "ssh-ed25519-sk AAAAC3... test@host" > "$TEST_KEY_DIR/github.com_testuser@testhost.pub"
}

# Test cleanup
teardown() {
    cleanup_test_environment
}

# Test git-remote-url-effective function

@test "git-remote-url-effective returns origin URL" {
    cd "$TEST_GIT_REPO"
    git remote add origin "https://github.com/user/repo.git"

    run bash -c "cd '$TEST_GIT_REPO' && source $KEYCUTTER_ROOT/lib/git && git-remote-url-effective"
    [ "$status" -eq 0 ]
    [[ "$output" == "https://github.com/user/repo.git" ]]
}

@test "git-remote-url-effective fails without git repo" {
    local non_git_dir="$TEST_HOME/non-git"
    mkdir -p "$non_git_dir"

    run bash -c "cd '$non_git_dir' && source $KEYCUTTER_ROOT/lib/git && git-remote-url-effective"
    # git ls-remote exits 128 when not in a git repo, but because we redirect to /dev/null
    # and bash returns the exit status of the last command, we get 128
    [ "$status" -ne 0 ]
}

# Test git-remote-ssh-host function

@test "git-remote-ssh-host extracts host from SCP-style URL" {
    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-remote-ssh-host 'git@github.com_user:owner/repo.git'"
    [ "$status" -eq 0 ]
    [[ "$output" == "github.com_user" ]]
}

@test "git-remote-ssh-host extracts host from ssh:// URL" {
    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-remote-ssh-host 'ssh://git@github.com_user/owner/repo.git'"
    [ "$status" -eq 0 ]
    [[ "$output" == "github.com_user" ]]
}

@test "git-remote-ssh-host fails on HTTPS URL" {
    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-remote-ssh-host 'https://github.com/user/repo.git'"
    [ "$status" -eq 1 ]
}

@test "git-remote-ssh-host fails on invalid URL" {
    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-remote-ssh-host 'not-a-url'"
    [ "$status" -eq 1 ]
}

# Test ssh-key-for-host function

@test "ssh-key-for-host finds existing key" {
    # Mock ssh -G to return our test key pattern
    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@%L"
    create_mock_command "hostname" 0 "testhost"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && ssh-key-for-host 'github.com_testuser'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "github.com_testuser@testhost.pub" ]]
}

@test "ssh-key-for-host fails when no key exists" {
    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@%L"
    create_mock_command "hostname" 0 "testhost"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && ssh-key-for-host 'nonexistent_host'"
    [ "$status" -eq 1 ]
}

@test "ssh-key-for-host expands KEYCUTTER_ORIGIN" {
    export KEYCUTTER_ORIGIN="origin-host"
    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@\${KEYCUTTER_ORIGIN}"
    echo "ssh-ed25519-sk AAAAC3... test@origin" > "$TEST_KEY_DIR/github.com_testuser@origin-host.pub"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && ssh-key-for-host 'github.com_testuser'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "github.com_testuser@origin-host.pub" ]]
}

# Test git-signing-detect-key function

@test "git-signing-detect-key detects key for SSH remote" {
    cd "$TEST_GIT_REPO"
    git remote add origin "git@github.com_testuser:owner/repo.git"

    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@%L"
    create_mock_command "hostname" 0 "testhost"

    run bash -c "source $KEYCUTTER_ROOT/lib/functions && git-signing-detect-key 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "github.com_testuser@testhost.pub" ]]
}

@test "git-signing-detect-key fails for HTTPS remote" {
    cd "$TEST_GIT_REPO"
    git remote add origin "https://github.com/user/repo.git"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-signing-detect-key 2>/dev/null"
    [ "$status" -eq 1 ]
}

@test "git-signing-detect-key fails without remote" {
    cd "$TEST_GIT_REPO"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-signing-detect-key 2>/dev/null"
    [ "$status" -eq 1 ]
}

# Test git-signing-enable function

@test "git-signing-enable configures git for signing" {
    cd "$TEST_GIT_REPO"
    git remote add origin "git@github.com_testuser:owner/repo.git"

    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@%L"
    create_mock_command "hostname" 0 "testhost"

    run bash -c "cd '$TEST_GIT_REPO' && source $KEYCUTTER_ROOT/lib/functions && echo 'y' | git-signing-enable 2>/dev/null"
    [ "$status" -eq 0 ]

    # Check git config was set
    gpg_format=$(cd "$TEST_GIT_REPO" && git config --get gpg.format)
    signing_key=$(cd "$TEST_GIT_REPO" && git config --get user.signingkey)
    commit_gpgsign=$(cd "$TEST_GIT_REPO" && git config --get commit.gpgsign)

    [[ "$gpg_format" == "ssh" ]]
    [[ "$signing_key" =~ "github.com_testuser@testhost.pub" ]]
    [[ "$commit_gpgsign" == "true" ]]
}

@test "git-signing-enable respects --global flag" {
    cd "$TEST_GIT_REPO"
    git remote add origin "git@github.com_testuser:owner/repo.git"

    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@%L"
    create_mock_command "hostname" 0 "testhost"

    run bash -c "cd '$TEST_GIT_REPO' && source $KEYCUTTER_ROOT/lib/functions && echo 'y' | git-signing-enable --global 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "global scope" ]]
}

@test "git-signing-enable accepts explicit key path" {
    cd "$TEST_GIT_REPO"

    explicit_key="$TEST_KEY_DIR/explicit-key.pub"
    echo "ssh-ed25519-sk AAAAC3... explicit" > "$explicit_key"

    run bash -c "cd '$TEST_GIT_REPO' && source $KEYCUTTER_ROOT/lib/functions && git-signing-enable '$explicit_key' 2>/dev/null"
    [ "$status" -eq 0 ]

    signing_key=$(cd "$TEST_GIT_REPO" && git config --get user.signingkey)
    [[ "$signing_key" == "$explicit_key" ]]
}

@test "git-signing-enable fails when user declines" {
    cd "$TEST_GIT_REPO"
    git remote add origin "git@github.com_testuser:owner/repo.git"

    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@%L"
    create_mock_command "hostname" 0 "testhost"

    run bash -c "cd '$TEST_GIT_REPO' && source $KEYCUTTER_ROOT/lib/functions && echo 'n' | git-signing-enable 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "cancelled" ]]
}

# Test git-signing-disable function

@test "git-signing-disable unsets commit.gpgsign" {
    cd "$TEST_GIT_REPO"
    git config commit.gpgsign true

    run bash -c "cd '$TEST_GIT_REPO' && source $KEYCUTTER_ROOT/lib/functions && git-signing-disable 2>/dev/null"
    [ "$status" -eq 0 ]

    run bash -c "cd '$TEST_GIT_REPO' && git config --get commit.gpgsign"
    [ "$status" -eq 1 ]  # Config key should not exist
}

@test "git-signing-disable works when nothing configured" {
    cd "$TEST_GIT_REPO"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-signing-disable 2>/dev/null"
    [ "$status" -eq 0 ]
}

# Test git-signing-status function

@test "git-signing-status shows not configured" {
    cd "$TEST_GIT_REPO"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-signing-status 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "not set" ]]
}

@test "git-signing-status shows configuration when enabled" {
    cd "$TEST_GIT_REPO"
    git config gpg.format ssh
    git config user.signingkey "$TEST_KEY_DIR/github.com_testuser@testhost.pub"
    git config commit.gpgsign true

    create_mock_command "ssh-keygen" 0 "256 SHA256:test github.com_testuser@testhost (ED25519-SK)"

    run bash -c "cd '$TEST_GIT_REPO' && source $KEYCUTTER_ROOT/lib/functions && git-signing-status 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "GPG format" ]]
    [[ "$output" =~ "ssh" ]]
    [[ "$output" =~ "Signing key" ]]
    [[ "$output" =~ "github.com_testuser@testhost.pub" ]]
}

# Test keycutter git-signing command

@test "keycutter git-signing shows help without subcommand" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter git-signing 2>/dev/null"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "enable" ]]
    [[ "$output" =~ "disable" ]]
    [[ "$output" =~ "status" ]]
}

@test "keycutter git-signing enable works" {
    cd "$TEST_GIT_REPO"
    git remote add origin "git@github.com_testuser:owner/repo.git"

    create_mock_command "ssh" 0 "identityfile ~/.ssh/keycutter/keys/%n@%L"
    create_mock_command "hostname" 0 "testhost"

    run bash -c "cd '$TEST_GIT_REPO' && echo 'y' | $KEYCUTTER_ROOT/bin/keycutter git-signing enable 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "enabled" ]]
}

@test "keycutter git-signing disable works" {
    cd "$TEST_GIT_REPO"
    git config commit.gpgsign true

    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter git-signing disable 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "disabled" ]]
}

@test "keycutter git-signing status works" {
    cd "$TEST_GIT_REPO"

    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter git-signing status 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Git commit signing status" ]]
}

@test "keycutter git-signing shows error for unknown subcommand" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter git-signing invalid 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown git-signing subcommand" ]]
}

# ============================================================================
# Test ssh-keys-create-symlinks function (key link)
# ============================================================================

@test "ssh-keys-create-symlinks creates symlinks for machine-specific keys" {
    export KEYCUTTER_ORIGIN="testhost"

    # Create machine-specific keys
    echo "ssh-ed25519-sk AAAAC3... test@testhost" > "$TEST_KEY_DIR/github.com_alex@testhost.pub"
    echo "fake-private-key" > "$TEST_KEY_DIR/github.com_alex@testhost"

    run bash -c "source $KEYCUTTER_ROOT/lib/ssh && ssh-keys-create-symlinks 2>/dev/null"
    [ "$status" -eq 0 ]

    # Verify symlinks were created
    [[ -L "$TEST_KEY_DIR/github.com_alex" ]]
    [[ -L "$TEST_KEY_DIR/github.com_alex.pub" ]]

    # Verify symlinks point to correct files
    [[ "$(readlink "$TEST_KEY_DIR/github.com_alex")" == "github.com_alex@testhost" ]]
    [[ "$(readlink "$TEST_KEY_DIR/github.com_alex.pub")" == "github.com_alex@testhost.pub" ]]
}

@test "ssh-keys-create-symlinks skips keys without machine suffix" {
    export KEYCUTTER_ORIGIN="testhost"

    # Create a key without @hostname suffix
    echo "ssh-ed25519 AAAAC3... test" > "$TEST_KEY_DIR/generic_key.pub"
    echo "fake-private-key" > "$TEST_KEY_DIR/generic_key"

    run bash -c "source $KEYCUTTER_ROOT/lib/ssh && ssh-keys-create-symlinks 2>/dev/null"
    [ "$status" -eq 0 ]

    # Should not create any new symlinks (only the original files exist)
    [[ ! -L "$TEST_KEY_DIR/generic_key" ]]
}

@test "ssh-keys-create-symlinks dry-run shows what would happen" {
    export KEYCUTTER_ORIGIN="testhost"

    # Create machine-specific keys
    echo "ssh-ed25519-sk AAAAC3... test@testhost" > "$TEST_KEY_DIR/github.com_user@testhost.pub"
    echo "fake-private-key" > "$TEST_KEY_DIR/github.com_user@testhost"

    run bash -c "source $KEYCUTTER_ROOT/lib/ssh && ssh-keys-create-symlinks --dry-run 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "dry-run" ]] || [[ "$output" =~ "Dry run" ]]

    # Symlinks should NOT be created in dry-run
    [[ ! -L "$TEST_KEY_DIR/github.com_user" ]]
}

@test "ssh-keys-create-symlinks updates existing symlinks if target changed" {
    export KEYCUTTER_ORIGIN="newhost"

    # Create an old symlink pointing to old host
    echo "ssh-ed25519-sk AAAAC3... test@newhost" > "$TEST_KEY_DIR/github.com_alex@newhost.pub"
    echo "fake-private-key" > "$TEST_KEY_DIR/github.com_alex@newhost"
    ln -sf "github.com_alex@oldhost" "$TEST_KEY_DIR/github.com_alex"
    ln -sf "github.com_alex@oldhost.pub" "$TEST_KEY_DIR/github.com_alex.pub"

    run bash -c "source $KEYCUTTER_ROOT/lib/ssh && ssh-keys-create-symlinks 2>/dev/null"
    [ "$status" -eq 0 ]

    # Symlinks should be updated
    [[ "$(readlink "$TEST_KEY_DIR/github.com_alex")" == "github.com_alex@newhost" ]]
}

@test "keycutter key link command works" {
    export KEYCUTTER_ORIGIN="testhost"

    # Create machine-specific keys
    echo "ssh-ed25519-sk AAAAC3... test@testhost" > "$TEST_KEY_DIR/github.com_testuser@testhost.pub"
    echo "fake-private-key" > "$TEST_KEY_DIR/github.com_testuser@testhost"

    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter key link 2>/dev/null"
    [ "$status" -eq 0 ]

    # Verify symlinks were created
    [[ -L "$TEST_KEY_DIR/github.com_testuser" ]]
}

# ============================================================================
# Test git-identity-create and git-identity-list functions
# ============================================================================

@test "git-identity-create creates config file" {
    local git_dir="$KEYCUTTER_CONFIG_DIR/git"

    # Create the key that identity will reference
    echo "ssh-ed25519-sk AAAAC3... test" > "$TEST_KEY_DIR/github.com_alex.pub"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-identity-create github.com_alex --name 'Alex Smith' --email 'alex@example.com' 2>/dev/null"
    [ "$status" -eq 0 ]

    # Verify config file was created
    [[ -f "$git_dir/github.com_alex.conf" ]]

    # Verify contents
    grep -q "name = Alex Smith" "$git_dir/github.com_alex.conf"
    grep -q "email = alex@example.com" "$git_dir/github.com_alex.conf"
    grep -q "gpgsign = true" "$git_dir/github.com_alex.conf"
}

@test "git-identity-create strips @hostname from keytag" {
    local git_dir="$KEYCUTTER_CONFIG_DIR/git"

    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-identity-create github.com_alex@laptop --name 'Alex' --email 'alex@example.com' 2>/dev/null"
    [ "$status" -eq 0 ]

    # Config file should use service_identity without @hostname
    [[ -f "$git_dir/github.com_alex.conf" ]]
}

@test "git-identity-list shows created identities" {
    local git_dir="$KEYCUTTER_CONFIG_DIR/git"
    mkdir -p "$git_dir"

    # Create test config files
    cat > "$git_dir/github.com_alex.conf" << 'EOF'
[user]
    name = Alex Smith
    email = alex@example.com
EOF

    run bash -c "source $KEYCUTTER_ROOT/lib/git && git-identity-list 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "github.com_alex" ]]
    [[ "$output" =~ "alex@example.com" ]]
}

@test "keycutter git-identity create command works" {
    echo "ssh-ed25519-sk AAAAC3... test" > "$TEST_KEY_DIR/github.com_testuser.pub"

    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter git-identity create github.com_testuser --name 'Test User' --email 'test@example.com' 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ -f "$KEYCUTTER_CONFIG_DIR/git/github.com_testuser.conf" ]]
}

@test "keycutter git-identity list command works" {
    local git_dir="$KEYCUTTER_CONFIG_DIR/git"
    mkdir -p "$git_dir"
    echo -e "[user]\n    email = test@example.com" > "$git_dir/github.com_test.conf"

    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter git-identity list 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "github.com_test" ]]
}

# ============================================================================
# Test git-config-setup function
# ============================================================================

@test "git-config-setup creates master config" {
    local git_dir="$KEYCUTTER_CONFIG_DIR/git"
    mkdir -p "$git_dir"

    # Create a test identity config
    cat > "$git_dir/github.com_alex.conf" << 'EOF'
[user]
    name = Alex Smith
    email = alex@example.com
EOF

    # Run git-config-setup with minimal input (skip gitdir prompt, decline adding to gitconfig)
    run bash -c "source $KEYCUTTER_ROOT/lib/git && echo -e '\nn' | git-config-setup 2>/dev/null"
    [ "$status" -eq 0 ]

    # Master config should be created
    [[ -f "$git_dir/config" ]]
}

@test "keycutter git-config setup command works" {
    run bash -c "echo -e '\nn' | $KEYCUTTER_ROOT/bin/keycutter git-config setup 2>/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Keycutter Git Config Setup" ]] || [[ "$output" =~ "Generated" ]]
}

# ============================================================================
# Test keycutter setup command
# ============================================================================

@test "keycutter setup shows help without subcommand" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter setup 2>&1"
    # Setup might work with default action or show usage
    # Just verify it doesn't fail with unknown command error
    [[ ! "$output" =~ "Unknown command" ]]
}

@test "keycutter setup runs key link" {
    export KEYCUTTER_ORIGIN="testhost"

    # Create machine-specific keys
    echo "ssh-ed25519-sk AAAAC3... test@testhost" > "$TEST_KEY_DIR/github.com_testuser@testhost.pub"
    echo "fake-private-key" > "$TEST_KEY_DIR/github.com_testuser@testhost"

    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter setup 2>/dev/null"
    [ "$status" -eq 0 ]

    # Verify symlinks were created
    [[ -L "$TEST_KEY_DIR/github.com_testuser" ]]
}
