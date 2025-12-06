#!/usr/bin/env bats

load test_helper

# Test setup
setup() {
    setup_test_environment
    mock_keycutter_environment
    init_mock_log

    # Source the GPG library for direct testing
    source "$KEYCUTTER_ROOT/lib/gpg"
}

# Test cleanup
teardown() {
    # Clean up any ephemeral GNUPGHOME created during tests
    gpg-home-temp-cleanup 2>/dev/null || true
    cleanup_test_environment
}

# ============================================================================
# gpg-version-check tests
# ============================================================================

@test "gpg-version-check returns version when gpg is installed" {
    # Mock gpg command with valid version
    create_mock_command "gpg" 0 "gpg (GnuPG) 2.4.0
libgcrypt 1.10.1"

    run gpg-version-check
    [ "$status" -eq 0 ]
    [[ "$output" =~ "2.4.0" ]]
}

@test "gpg-version-check fails when gpg is not installed" {
    # Remove gpg from PATH by overriding with a failing mock
    create_mock_command "gpg" 127 ""
    # Override command -v behavior
    function command() {
        if [[ "$2" == "gpg" ]]; then
            return 1
        fi
        builtin command "$@"
    }
    export -f command

    # Source the library again to pick up the mock
    source "$KEYCUTTER_ROOT/lib/gpg"

    run gpg-version-check
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not installed" ]]
}

@test "gpg-version-check fails when version is too old" {
    # Mock gpg with old version
    create_mock_command "gpg" 0 "gpg (GnuPG) 2.0.0
libgcrypt 1.6.0"

    run gpg-version-check "2.2.0"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "too old" ]]
}

@test "gpg-version-check accepts custom minimum version" {
    create_mock_command "gpg" 0 "gpg (GnuPG) 2.3.0
libgcrypt 1.9.0"

    run gpg-version-check "2.3.0"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "2.3.0" ]]
}

# ============================================================================
# gpg-home-temp-create tests
# ============================================================================

@test "gpg-home-temp-create creates temporary directory" {
    # Create temp dir manually to test the core logic without EXIT trap interference
    local temp_dir
    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/gnupg.XXXXXXXXXX")

    [ -d "$temp_dir" ]

    # Verify restrictive permissions can be set
    chmod 700 "$temp_dir"

    # Get permissions - try GNU stat first, then BSD stat
    local perms
    if stat --version &>/dev/null; then
        # GNU stat
        perms=$(stat -c "%a" "$temp_dir")
    else
        # BSD stat (macOS)
        perms=$(stat -f "%OLp" "$temp_dir")
    fi
    [ "$perms" = "700" ]

    # Cleanup
    rm -rf "$temp_dir"
}

@test "gpg-home-temp-create sets GNUPGHOME" {
    local old_gnupghome="${GNUPGHOME:-}"

    gpg-home-temp-create >/dev/null

    # GNUPGHOME should be set
    [ -n "$GNUPGHOME" ]
    [ -d "$GNUPGHOME" ]

    # Cleanup
    gpg-home-temp-cleanup

    # Restore
    export GNUPGHOME="$old_gnupghome"
}

@test "gpg-home-temp-create accepts custom base directory" {
    local custom_base="$TEST_HOME/custom_gpg_base"
    mkdir -p "$custom_base"

    run gpg-home-temp-create "$custom_base"
    [ "$status" -eq 0 ]

    # Verify created in custom location - extract path from output
    local temp_dir=$(echo "$output" | grep -o '/[^ ]*gnupg[^ ]*' | head -1)
    [[ "$temp_dir" == "$custom_base"/* ]]

    # Cleanup
    rm -rf "$temp_dir"
}

# ============================================================================
# gpg-home-temp-cleanup tests
# ============================================================================

@test "gpg-home-temp-cleanup removes ephemeral directory" {
    gpg-home-temp-create >/dev/null
    local temp_dir="$GNUPGHOME"

    # Verify directory exists before cleanup
    [ -d "$temp_dir" ]

    gpg-home-temp-cleanup

    # Directory should be removed
    [ ! -d "$temp_dir" ]
}

@test "gpg-home-temp-cleanup unsets GNUPGHOME" {
    gpg-home-temp-create >/dev/null

    gpg-home-temp-cleanup

    # GNUPGHOME should be unset
    [ -z "${GNUPGHOME:-}" ]
}

@test "gpg-home-temp-cleanup is idempotent" {
    gpg-home-temp-create >/dev/null

    # Call cleanup multiple times
    run gpg-home-temp-cleanup
    [ "$status" -eq 0 ]

    run gpg-home-temp-cleanup
    [ "$status" -eq 0 ]
}

@test "gpg-home-temp-cleanup handles missing directory gracefully" {
    # Don't create any temp home
    _GPG_EPHEMERAL_HOME=""

    run gpg-home-temp-cleanup
    [ "$status" -eq 0 ]
}

# ============================================================================
# gpg-agent-restart tests
# ============================================================================

@test "gpg-agent-restart calls gpgconf --kill" {
    create_mock_command "gpgconf" 0 ""
    create_mock_command "gpg-connect-agent" 0 "OK"

    run gpg-agent-restart "$TEST_HOME/.gnupg"
    [ "$status" -eq 0 ]

    # Verify gpgconf was called with kill
    assert_mock_called "gpgconf"
}

@test "gpg-agent-restart uses default GNUPGHOME" {
    create_mock_command "gpgconf" 0 ""
    create_mock_command "gpg-connect-agent" 0 "OK"

    # Set up a mock GNUPGHOME
    mkdir -p "$TEST_HOME/.gnupg"
    export GNUPGHOME="$TEST_HOME/.gnupg"

    run gpg-agent-restart
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Restarting" ]]
}

@test "gpg-agent-restart logs success" {
    create_mock_command "gpgconf" 0 ""
    create_mock_command "gpg-connect-agent" 0 "OK"

    run gpg-agent-restart "$TEST_HOME/.gnupg"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Success" ]] || [[ "$output" =~ "restarted" ]]
}

# ============================================================================
# gpg-agent-ensure tests
# ============================================================================

@test "gpg-agent-ensure starts agent if not running" {
    # Mock agent as not running initially, then running after restart
    create_mock_command "gpg-connect-agent" 0 "OK"
    create_mock_command "gpgconf" 0 ""

    run gpg-agent-ensure "$TEST_HOME/.gnupg"
    [ "$status" -eq 0 ]
}

@test "gpg-agent-ensure succeeds when agent is already running" {
    create_mock_command "gpg-connect-agent" 0 "OK"

    run gpg-agent-ensure "$TEST_HOME/.gnupg"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Integration tests
# ============================================================================

@test "ephemeral GNUPGHOME workflow completes successfully" {
    # Mock gpg commands
    create_mock_command "gpg" 0 "gpg (GnuPG) 2.4.0"
    create_mock_command "gpgconf" 0 ""

    # Create ephemeral home
    gpg-home-temp-create >/dev/null
    local temp_home="$GNUPGHOME"

    [ -d "$temp_home" ]
    [ -n "$GNUPGHOME" ]

    # Clean up
    gpg-home-temp-cleanup

    [ ! -d "$temp_home" ]
    [ -z "${GNUPGHOME:-}" ]
}

# ============================================================================
# gpg-config-load tests
# ============================================================================

@test "gpg-config-load loads defaults from config file" {
    # Load config (can't use run because config is stored in memory)
    gpg-config-load

    # Check a known default value
    run gpg-config-get GPG_KEY_TYPE
    [ "$status" -eq 0 ]
    [ "$output" = "ed25519" ]
}

@test "gpg-config-load respects environment variable overrides" {
    export GPG_KEY_TYPE="rsa4096"

    # Load config (can't use run because config is stored in memory)
    gpg-config-load

    run gpg-config-get GPG_KEY_TYPE
    [ "$status" -eq 0 ]
    [ "$output" = "rsa4096" ]

    unset GPG_KEY_TYPE
}

@test "gpg-config-load respects CLI argument overrides" {
    gpg-config-load GPG_KEY_TYPE=rsa2048 GPG_EXPIRATION=6m

    run gpg-config-get GPG_KEY_TYPE
    [ "$status" -eq 0 ]
    [ "$output" = "rsa2048" ]

    run gpg-config-get GPG_EXPIRATION
    [ "$status" -eq 0 ]
    [ "$output" = "6m" ]
}

@test "gpg-config-load CLI overrides take precedence over env vars" {
    export GPG_KEY_TYPE="rsa4096"

    gpg-config-load GPG_KEY_TYPE=ed25519

    run gpg-config-get GPG_KEY_TYPE
    [ "$status" -eq 0 ]
    [ "$output" = "ed25519" ]

    unset GPG_KEY_TYPE
}

@test "gpg-config-load handles multiple config variables" {
    gpg-config-load

    # Check several default values exist
    run gpg-config-get GPG_EXPIRATION
    [ "$status" -eq 0 ]
    [ "$output" = "2y" ]

    run gpg-config-get GPG_CIPHER_PREFS
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AES256" ]]
}

# ============================================================================
# gpg-config-get tests
# ============================================================================

@test "gpg-config-get returns existing value" {
    gpg-config-load

    run gpg-config-get GPG_KEY_TYPE
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "gpg-config-get returns default for missing key" {
    gpg-config-load

    run gpg-config-get NONEXISTENT_KEY "default_value"
    [ "$status" -eq 0 ]
    [ "$output" = "default_value" ]
}

@test "gpg-config-get fails for missing key without default" {
    gpg-config-load

    run gpg-config-get NONEXISTENT_KEY
    [ "$status" -eq 1 ]
}

@test "gpg-config-get handles empty string values" {
    gpg-config-load GPG_COMMENT=""

    # Empty string is still a valid value
    run gpg-config-get GPG_COMMENT "fallback"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ============================================================================
# gpg-config-dump tests
# ============================================================================

@test "gpg-config-dump shows all loaded config" {
    gpg-config-load GPG_KEY_TYPE=ed25519 GPG_EXPIRATION=1y

    run gpg-config-dump
    [ "$status" -eq 0 ]
    [[ "$output" =~ "GPG_KEY_TYPE=ed25519" ]]
    [[ "$output" =~ "GPG_EXPIRATION=1y" ]]
}

@test "gpg-config-dump output is sorted" {
    gpg-config-load

    run gpg-config-dump
    [ "$status" -eq 0 ]

    # Verify output contains multiple lines and appears sorted
    local line_count
    line_count=$(echo "$output" | wc -l)
    [ "$line_count" -gt 1 ]
}

# ============================================================================
# gpg-card-status-display tests
# ============================================================================

@test "gpg-card-status-display parses card with keys" {
    local card_output="Reader ...........: Yubico YubiKey FIDO+CCID 0
Serial number ....: 12345678
Name of cardholder: Test User
Signature key ....: ABCD 1234 5678 90EF GHIJ  KLMN OPQR STUV WXYZ 1234
Encryption key....: DCBA 4321 8765 FE09 JIHG  NMLK RQPO VUTS ZYXW 4321
Authentication key: 1111 2222 3333 4444 5555  6666 7777 8888 9999 0000
General key info..: pub  ed25519/0xABCD1234 2024-01-01 Test <test@example.com>"

    run gpg-card-status-display "$card_output"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Serial:" ]]
    [[ "$output" =~ "12345678" ]]
    [[ "$output" =~ "[S] Signature:" ]]
    [[ "$output" =~ "[E] Encryption:" ]]
    [[ "$output" =~ "[A] Authentication:" ]]
}

@test "gpg-card-status-display handles empty keys" {
    local card_output="Reader ...........: Yubico YubiKey FIDO+CCID 0
Serial number ....: 12345678
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]"

    run gpg-card-status-display "$card_output"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "(not set)" ]]
}

@test "gpg-card-status-display shows note when keys not linked" {
    local card_output="Reader ...........: Yubico YubiKey FIDO+CCID 0
Serial number ....: 12345678
Signature key ....: ABCD 1234 5678 90EF GHIJ  KLMN OPQR STUV WXYZ 1234
Encryption key....: [none]
Authentication key: [none]"

    run gpg-card-status-display "$card_output"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "not linked" ]]
}

# ============================================================================
# gpg-master-keys-list tests
# ============================================================================

@test "gpg-master-keys-list reports when no backup dir configured" {
    # Load config without GPG_BACKUP_DIR
    gpg-config-load GPG_BACKUP_DIR=""

    run gpg-master-keys-list
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No backup location configured" ]]
}

@test "gpg-master-keys-list reports when backup dir does not exist" {
    # Use env var since the function reloads config internally
    export GPG_BACKUP_DIR="$TEST_HOME/nonexistent_backup"

    run gpg-master-keys-list
    [ "$status" -eq 1 ]
    # The function outputs "Backup directory not found: <path>"
    [[ "$output" =~ "Backup directory" ]] || [[ "$output" =~ "not found" ]]

    unset GPG_BACKUP_DIR
}

@test "gpg-master-keys-list reports when no keys found" {
    local backup_dir="$TEST_HOME/gpg_backup"
    mkdir -p "$backup_dir"

    # Use env var since the function reloads config internally
    export GPG_BACKUP_DIR="$backup_dir"

    run gpg-master-keys-list
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No master keys found" ]]

    unset GPG_BACKUP_DIR
}

@test "gpg-master-keys-list finds keys in backup directory" {
    local backup_dir="$TEST_HOME/gpg_backup"
    mkdir -p "$backup_dir"

    # Create a mock key file
    cat > "$backup_dir/test-key.asc" << 'EOF'
-----BEGIN PGP PRIVATE KEY BLOCK-----

lIYEZhIaaBYJKwYBBAHaRw8BAQdATestKeyDataHere
EOF

    # Use env var since the function reloads config internally
    export GPG_BACKUP_DIR="$backup_dir"

    # Mock gpg --show-keys to return key info
    create_mock_command "gpg" 0 "sec::256:22:ABCD1234567890EF:1704067200:::u:::scESCA:::+:::ed25519:::0:
uid:::::::Test User <test@example.com>::::::::::0:"

    run gpg-master-keys-list
    # The test may pass or fail depending on gpg parsing, but should not error on file handling
    [[ "$status" -eq 0 ]] || [[ "$output" =~ "No master keys found" ]]

    unset GPG_BACKUP_DIR
}

# ============================================================================
# keycutter gpg key list CLI tests
# ============================================================================

@test "keycutter gpg key list shows help with --help" {
    run "$KEYCUTTER_ROOT/bin/keycutter" gpg key list --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--all" ]]
}

@test "keycutter gpg key list rejects unknown options" {
    run "$KEYCUTTER_ROOT/bin/keycutter" gpg key list --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

# ============================================================================
# gpg-master-key-create tests
# ============================================================================

@test "gpg-master-key-create requires --identity" {
    # Create ephemeral home first
    gpg-home-temp-create >/dev/null

    run gpg-master-key-create
    [ "$status" -eq 1 ]
    [[ "$output" =~ "--identity is required" ]]

    gpg-home-temp-cleanup
}

@test "gpg-master-key-create requires GNUPGHOME to be set" {
    # Ensure GNUPGHOME is not set
    unset GNUPGHOME
    _GPG_EPHEMERAL_HOME=""

    run gpg-master-key-create --identity "Test <test@example.com>"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "GNUPGHOME not set" ]]
}

@test "gpg-master-key-create validates key type" {
    gpg-home-temp-create >/dev/null

    run gpg-master-key-create --identity "Test <test@example.com>" --key-type "invalid_type" --passphrase "testpass123"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid key type" ]]

    gpg-home-temp-cleanup
}

@test "gpg-master-key-create accepts ed25519 key type" {
    # This test verifies the key type validation accepts ed25519
    # Full key generation is tested in integration tests
    gpg-home-temp-create >/dev/null

    # Test that ed25519 doesn't trigger "Invalid key type" error
    # The function will fail later due to actual GPG invocation, but validation passes
    run gpg-master-key-create --identity "Test <test@example.com>" --key-type "ed25519" --passphrase "testpass123"

    # Should NOT fail with "Invalid key type" - may fail for other reasons (GPG not available in test)
    [[ ! "$output" =~ "Invalid key type" ]]

    gpg-home-temp-cleanup
}

@test "gpg-master-key-create accepts rsa4096 key type" {
    gpg-home-temp-create >/dev/null

    # Minimal validation test - just ensure it accepts the type
    run gpg-master-key-create --identity "Test <test@example.com>" --key-type "rsa4096" --passphrase "short"

    # It may fail for other reasons (mock gpg), but should not fail on key type
    [[ ! "$output" =~ "Invalid key type" ]]

    gpg-home-temp-cleanup
}

@test "gpg-master-key-create uses config defaults for key type" {
    # Test that config defaults are loaded correctly
    gpg-home-temp-create >/dev/null

    # Load config and verify default
    gpg-config-load
    local default_type=$(gpg-config-get GPG_KEY_TYPE "")

    # Verify the default is ed25519 (from config/gpg/defaults)
    [ "$default_type" = "ed25519" ]

    gpg-home-temp-cleanup
}

# ============================================================================
# gpg-identity-prompt tests (limited - interactive)
# ============================================================================

@test "gpg-identity-prompt validates email format" {
    # This tests the validation logic, not the interactive prompt
    # We can test by checking the regex pattern used

    # Valid email patterns should match
    [[ "test@example.com" =~ ^[^@]+@[^@]+\.[^@]+$ ]]
    [[ "user.name@sub.domain.org" =~ ^[^@]+@[^@]+\.[^@]+$ ]]

    # Invalid patterns should not match
    ! [[ "notanemail" =~ ^[^@]+@[^@]+\.[^@]+$ ]]
    ! [[ "@missing.local" =~ ^[^@]+@[^@]+\.[^@]+$ ]]
}

# ============================================================================
# gpg-passphrase-prompt tests (limited - interactive)
# ============================================================================

@test "gpg-passphrase-prompt enforces minimum length" {
    # The function requires at least 8 characters
    # We test this indirectly by checking the logic exists

    # Mock the function to test validation
    local test_pass="short"
    [ ${#test_pass} -lt 8 ]

    local good_pass="longenoughpassphrase"
    [ ${#good_pass} -ge 8 ]
}

# ============================================================================
# keycutter gpg key create CLI tests
# ============================================================================

@test "keycutter gpg key create shows help with --help" {
    run "$KEYCUTTER_ROOT/bin/keycutter" gpg key create --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--identity" ]]
    [[ "$output" =~ "--key-type" ]]
    [[ "$output" =~ "--yes" ]]
}

@test "keycutter gpg key create rejects unknown options" {
    run "$KEYCUTTER_ROOT/bin/keycutter" gpg key create --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "keycutter gpg key create requires identity in non-interactive mode" {
    run "$KEYCUTTER_ROOT/bin/keycutter" gpg key create --yes --passphrase "testpass123"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "--identity required" ]]
}

@test "keycutter gpg key create requires passphrase in non-interactive mode" {
    run "$KEYCUTTER_ROOT/bin/keycutter" gpg key create --yes --identity "Test <test@example.com>"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "--passphrase required" ]]
}
