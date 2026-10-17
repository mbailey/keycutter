#!/usr/bin/env bats

# Tests for Touch ID (macOS Secure Enclave) keys: keycutter create --type touchid
#
# sc_auth and ssh-keygen are mocked, so no Secure Enclave identities or keys are created.

load test_helper

setup() {
    setup_test_environment
    mock_keycutter_environment
    init_mock_log

    export KEYCUTTER_ORIGIN="testhost"
    export KEYCUTTER_TOUCHID_PROVIDER="$BATS_TMPDIR/ssh-keychain.dylib"
    touch "$KEYCUTTER_TOUCHID_PROVIDER"
    rm -f "$BATS_TMPDIR/ctk_state"

    mock_sc_auth
    mock_ssh_keygen_touchid
}

teardown() {
    cleanup_test_environment
    rm -f "$BATS_TMPDIR/ctk_state" "$KEYCUTTER_TOUCHID_PROVIDER"
}

# Stateful sc_auth: create-ctk-identity adds a row that list-ctk-identities prints.
mock_sc_auth() {
    cat >"$BATS_TMPDIR/mock_bin/sc_auth" <<EOF
#!/bin/bash
echo "MOCK_CALL: sc_auth \$*" >> "$BATS_TMPDIR/mock_calls.log"
state="$BATS_TMPDIR/ctk_state"
case "\$1" in
list-ctk-identities)
    echo "Key Type Public Key Hash                           Prot Label"
    [[ -f "\$state" ]] && cat "\$state"
    ;;
create-ctk-identity)
    shift
    while getopts "l:k:t:" opt; do [[ \$opt == l ]] && label="\$OPTARG"; done
    echo "p-256-ne 0123456789ABCDEF0123456789ABCDEF01234567 bio \$label" >> "\$state"
    ;;
esac
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/sc_auth"
}

# ssh-keygen -K writes a key handle into the current directory, like the real one.
mock_ssh_keygen_touchid() {
    cat >"$BATS_TMPDIR/mock_bin/ssh-keygen" <<EOF
#!/bin/bash
echo "MOCK_CALL: ssh-keygen \$* KEYCHAIN_CERTIFICATES=\${KEYCHAIN_CERTIFICATES:-}" >> "$BATS_TMPDIR/mock_calls.log"
for arg in "\$@"; do
    if [[ \$arg == "-K" ]]; then
        echo "handle" > id_ecdsa_sk_rk
        echo "sk-ecdsa-sha2-nistp256@openssh.com AAAAtestkey ssh:" > id_ecdsa_sk_rk.pub
    fi
done
exit 0
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/ssh-keygen"
}

create_touchid() {
    run bash -c "echo 'n' | $KEYCUTTER_ROOT/bin/keycutter create --type touchid $* 2>&1"
}

@test "help lists touchid key type" {
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter --help 2>/dev/null"
    [[ "$output" =~ "touchid" ]]
}

@test "touchid rejects --resident" {
    create_touchid --resident example.com_test@testhost
    [ "$status" -eq 1 ]
    [[ "$output" =~ "--resident does not apply" ]]
    ! assert_mock_called "sc_auth create-ctk-identity"
}

@test "touchid fails cleanly when provider is missing" {
    export KEYCUTTER_TOUCHID_PROVIDER="$BATS_TMPDIR/does-not-exist.dylib"
    create_touchid example.com_test@testhost
    [ "$status" -eq 1 ]
    ! assert_mock_called "sc_auth create-ctk-identity"
}

@test "touchid creates Secure Enclave identity and key handle" {
    [[ "$OSTYPE" == darwin* ]] || skip "macOS only"

    create_touchid example.com_test@testhost
    [ "$status" -eq 0 ]

    assert_mock_called "sc_auth create-ctk-identity -l example.com_test@testhost -k p-256-ne -t bio"
    assert_mock_called "ssh-keygen -K -w $KEYCUTTER_TOUCHID_PROVIDER -N  KEYCHAIN_CERTIFICATES=0123456789ABCDEF0123456789ABCDEF01234567"

    local key="$KEYCUTTER_SSH_KEY_DIR/example.com_test@testhost"
    assert_file_exists "$key"
    assert_file_exists "$key.pub"
    [[ "$(cat "$key.pub")" == "sk-ecdsa-sha2-nistp256@openssh.com AAAAtestkey example.com_test@testhost" ]]
    [[ "$(cat "$KEYCUTTER_SSH_KEY_DIR/.touchid/example.com_test@testhost")" == "0123456789ABCDEF0123456789ABCDEF01234567" ]]
}

@test "touchid refuses to reuse an existing identity label" {
    [[ "$OSTYPE" == darwin* ]] || skip "macOS only"

    echo "p-256-ne 0123456789ABCDEF0123456789ABCDEF01234567 bio example.com_test@testhost" >"$BATS_TMPDIR/ctk_state"
    create_touchid example.com_test@testhost
    [ "$status" -ne 0 ]
    [[ "$output" =~ "already exists" ]]
    ! assert_mock_called "sc_auth create-ctk-identity"
}

@test "touch ID keys are not listed as separate keys" {
    [[ "$OSTYPE" == darwin* ]] || skip "macOS only"

    create_touchid example.com_test@testhost
    run bash -c "echo | $KEYCUTTER_ROOT/bin/keycutter keys 2>&1"
    [[ "$output" =~ "example.com_test@testhost" ]]
    [[ ! "$output" =~ ".touchid" ]]
}
