#!/usr/bin/env bats
# keycutter create with the Mac's Secure Enclave as the authenticator (KC-118).
# Everything is mocked: sc_auth, ssh-keygen, uname, ioreg, ykman. How to use
# it: docs/secure-enclave.md.

load test_helper

setup() {
    setup_test_environment
    mock_keycutter_environment
    init_mock_log

    export KEYCUTTER_ORIGIN="testhost"
    export KEYCUTTER_SETTINGS="$KEYCUTTER_CONFIG_DIR/settings"
    export KEYCUTTER_SK_PROVIDER_APPLE="$BATS_TMPDIR/fake-ssh-keychain.dylib"
    touch "$KEYCUTTER_SK_PROVIDER_APPLE"
    unset KEYCUTTER_AUTHENTICATOR

    export SE_STATE="$BATS_TMPDIR/ctk-identities"   # one label per line
    export SE_CLAMSHELL="$BATS_TMPDIR/clamshell"     # Yes | No
    export SE_USB="$BATS_TMPDIR/usb"                 # ioreg -p IOUSB output
    export SE_LOCKED="$BATS_TMPDIR/locked"           # Yes | No
    : > "$SE_STATE"; echo No > "$SE_CLAMSHELL"; : > "$SE_USB"; echo No > "$SE_LOCKED"
    rm -f "$BATS_TMPDIR/sc_auth_create_fails"

    create_mock_command "uname" 0 "Darwin"
    create_mock_command "ykman" 1 ""
    mock_sc_auth
    mock_ssh_keygen_se
    mock_ioreg
}

teardown() {
    cleanup_test_environment
}

mock_sc_auth() {
    cat > "$BATS_TMPDIR/mock_bin/sc_auth" <<'SH'
#!/bin/bash
echo "MOCK_CALL: sc_auth $@" >> "$BATS_TMPDIR/mock_calls.log"
case "$1" in
  list-ctk-identities)
    echo "Key Type Public Key Hash Prot Label Common Name Email Address Valid To Valid"
    while read -r l; do
      [[ -n $l ]] && echo "p-256-ne SHA256:FAKE-$l none $l $l  6/10/2027, 4:32 am YES"
    done < "$SE_STATE"
    ;;
  create-ctk-identity)
    if [[ -e "$BATS_TMPDIR/sc_auth_create_fails" ]]; then
      echo 'Error: Error Domain=com.apple.LocalAuthentication Code=-4 "Touch ID is not available in closed clamshell mode."'
      exit 0   # the real sc_auth exits 0 on this failure (measured 2026-10-06)
    fi
    while (($#)); do [[ $1 == -l ]] && label="$2"; shift; done
    echo "$label" >> "$SE_STATE"
    ;;
esac
exit 0
SH
    chmod +x "$BATS_TMPDIR/mock_bin/sc_auth"
}

mock_ssh_keygen_se() {
    cat > "$BATS_TMPDIR/mock_bin/ssh-keygen" <<'SH'
#!/bin/bash
echo "MOCK_CALL: ssh-keygen $@" >> "$BATS_TMPDIR/mock_calls.log"
case " $* " in
  *" -K "*)   # download EVERY resident identity into the cwd, like the real one
    echo "MOCK_ENV: SSH_ASKPASS=${SSH_ASKPASS-} SSH_ASKPASS_REQUIRE=${SSH_ASKPASS_REQUIRE-}" >> "$BATS_TMPDIR/mock_calls.log"
    while read -r l; do
      [[ -n $l ]] || continue
      printf 'FAKE-HANDLE %s\n' "$l" > "id_ecdsa_sk_rk_$l"
      printf 'sk-ecdsa-sha2-nistp256@openssh.com AAAAFAKE-%s ssh:\n' "$l" > "id_ecdsa_sk_rk_$l.pub"
    done < "$SE_STATE"
    ;;
  *" -lf "*)
    f="${@: -1}"; b="$(awk '{print $2}' "$f")"
    echo "256 SHA256:${b#AAAA} ssh: (ECDSA-SK)"
    ;;
  *" -c "*) ;;
  *" -t "*)   # the YubiKey / software path
    while (($#)); do [[ $1 == -f ]] && f="$2"; shift; done
    echo "fake private key" > "$f"; echo "ssh-ed25519 AAAAFAKE comment" > "$f.pub"
    ;;
esac
exit 0
SH
    chmod +x "$BATS_TMPDIR/mock_bin/ssh-keygen"
}

mock_ioreg() {
    cat > "$BATS_TMPDIR/mock_bin/ioreg" <<'SH'
#!/bin/bash
echo "MOCK_CALL: ioreg $@" >> "$BATS_TMPDIR/mock_calls.log"
case " $* " in
  *AppleClamshellState*) echo "    \"AppleClamshellState\" = $(cat "$SE_CLAMSHELL")" ;;
  *" -n Root "*) echo "    \"IOConsoleLocked\" = $(cat "$SE_LOCKED")" ;;
  *IOUSB*) cat "$SE_USB" ;;
esac
exit 0
SH
    chmod +x "$BATS_TMPDIR/mock_bin/ioreg"
}

kc() { bash -c "printf '${1:-}' | $KEYCUTTER_ROOT/bin/keycutter ${*:2} 2>&1"; }

@test "mac, no yubikey: defaults to the secure enclave, says so, and does NOT stick" {
    run kc '' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No YubiKey found" ]]
    [[ "$output" =~ "--authenticator yubikey" ]]
    [ ! -e "$KEYCUTTER_SETTINGS" ]   # the auto-choice is never persisted (review F3)
    assert_mock_called "sc_auth create-ctk-identity -l example.com_alice@testhost -k p-256-ne -t bio"
    assert_file_exists "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost"
    assert_file_exists "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost.pub"
    assert_file_exists "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost.secure-enclave"
    grep -q ' example.com_alice@testhost$' "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost.pub"
    ! grep -q 'MOCK_CALL: ssh-keygen -t' "$BATS_TMPDIR/mock_calls.log"
}

@test "handle download answers the provider's PIN prompt without a tty" {
    run kc '' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    grep -qxF "MOCK_ENV: SSH_ASKPASS=/usr/bin/true SSH_ASKPASS_REQUIRE=force" "$BATS_TMPDIR/mock_calls.log"
}

@test "settings file is 0600 and never sourced-looking" {
    echo "YubiKey 5C Nano" > "$SE_USB"   # only an explicit answer writes the file
    run kc 's' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Saved KEYCUTTER_AUTHENTICATOR=secure-enclave" ]]
    perm="$(/usr/bin/stat -f %Lp "$KEYCUTTER_SETTINGS" 2>/dev/null || stat -c %a "$KEYCUTTER_SETTINGS")"
    [ "$perm" = "600" ]
    head -1 "$KEYCUTTER_SETTINGS" | grep -q '^# keycutter settings'
}

@test "--no-touch mints with protection none" {
    run kc '' create example.com_alice@testhost --no-touch
    [ "$status" -eq 0 ]
    assert_mock_called "sc_auth create-ctk-identity -l example.com_alice@testhost -k p-256-ne -t none"
}

@test "lid closed + touch id: refuses before minting, names --no-touch" {
    echo Yes > "$SE_CLAMSHELL"
    run kc '' create example.com_alice@testhost
    [ "$status" -ne 0 ]
    [[ "$output" =~ "lid is closed" ]]
    [[ "$output" =~ "--no-touch" ]]
    ! grep -q 'sc_auth create-ctk-identity' "$BATS_TMPDIR/mock_calls.log"
    [ ! -e "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost" ]
}

@test "screen locked: refuses before minting, even with --no-touch" {
    echo Yes > "$SE_LOCKED"
    run kc '' create example.com_alice@testhost --no-touch
    [ "$status" -ne 0 ]
    [[ "$output" =~ "screen is locked" ]]
    ! grep -q 'sc_auth create-ctk-identity' "$BATS_TMPDIR/mock_calls.log"
}

@test "lid closed + --no-touch: proceeds" {
    echo Yes > "$SE_CLAMSHELL"
    run kc '' create example.com_alice@testhost --no-touch
    [ "$status" -eq 0 ]
    assert_file_exists "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost.secure-enclave"
}

@test "sc_auth failing silently (exit 0, no identity) is caught by the listing" {
    touch "$BATS_TMPDIR/sc_auth_create_fails"
    run kc '' create example.com_alice@testhost
    [ "$status" -ne 0 ]
    [[ "$output" =~ "did not create identity" ]]
    [ ! -e "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost" ]
}

@test "KEYCUTTER_AUTHENTICATOR=yubikey env keeps today's ssh-keygen path, writes nothing" {
    KEYCUTTER_AUTHENTICATOR=yubikey run kc '' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    assert_mock_called "ssh-keygen -t ed25519-sk -f $KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost"
    ! grep -q 'sc_auth' "$BATS_TMPDIR/mock_calls.log"
    [ ! -e "$KEYCUTTER_SETTINGS" ]
    [ ! -e "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost.secure-enclave" ]
}

@test "--authenticator mac is an alias for secure-enclave and beats the sticky file" {
    mkdir -p "$(dirname "$KEYCUTTER_SETTINGS")"; echo 'KEYCUTTER_AUTHENTICATOR=yubikey' > "$KEYCUTTER_SETTINGS"
    run kc '' create example.com_alice@testhost --authenticator mac
    [ "$status" -eq 0 ]
    assert_mock_called "sc_auth create-ctk-identity -l example.com_alice@testhost"
}

@test "sticky file secure-enclave: no prompt, no detection, enclave used" {
    mkdir -p "$(dirname "$KEYCUTTER_SETTINGS")"; echo 'KEYCUTTER_AUTHENTICATOR=secure-enclave' > "$KEYCUTTER_SETTINGS"
    echo "YubiKey 5C Nano" > "$SE_USB"   # a key IS plugged in; the sticky choice still wins
    run kc '' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "plugged in" ]]
    assert_mock_called "sc_auth create-ctk-identity -l example.com_alice@testhost"
}

@test "mac with a yubikey plugged in: asks once; 's' picks the enclave and sticks" {
    echo "YubiKey 5C Nano" > "$SE_USB"
    run kc 's' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    [[ "$output" =~ "A YubiKey is plugged in" ]]
    grep -q '^KEYCUTTER_AUTHENTICATOR=secure-enclave$' "$KEYCUTTER_SETTINGS"
    assert_mock_called "sc_auth create-ctk-identity -l example.com_alice@testhost"
}

@test "mac with a yubikey plugged in: 'y' keeps the yubikey and sticks" {
    echo "YubiKey 5C Nano" > "$SE_USB"
    run kc 'y' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    grep -q '^KEYCUTTER_AUTHENTICATOR=yubikey$' "$KEYCUTTER_SETTINGS"
    assert_mock_called "ssh-keygen -t ed25519-sk"
    ! grep -q 'sc_auth create' "$BATS_TMPDIR/mock_calls.log"
}

@test "existing key file: refuses, mints nothing" {
    create_test_ssh_key "example.com_alice@testhost"
    run kc '' create example.com_alice@testhost --authenticator secure-enclave
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Refusing to overwrite" ]]
    ! grep -q 'sc_auth create-ctk-identity' "$BATS_TMPDIR/mock_calls.log"
}

@test "existing enclave identity with the same label: refuses to mint a twin" {
    echo "example.com_alice@testhost" > "$SE_STATE"
    run kc '' create example.com_alice@testhost --authenticator secure-enclave
    [ "$status" -ne 0 ]
    [[ "$output" =~ "already exists" ]]
    ! grep -q 'sc_auth create-ctk-identity' "$BATS_TMPDIR/mock_calls.log"
}

@test "several resident identities downloaded: ours is picked by fingerprint (FB21992630)" {
    echo "older-key@testhost" > "$SE_STATE"
    run kc '' create example.com_alice@testhost --authenticator secure-enclave
    [ "$status" -eq 0 ]
    grep -q 'FAKE-HANDLE example.com_alice@testhost' "$KEYCUTTER_SSH_KEY_DIR/example.com_alice@testhost"
    [ ! -e "$KEYCUTTER_SSH_KEY_DIR/older-key@testhost" ]
}

@test "software key types never consult the authenticator" {
    echo "YubiKey 5C Nano" > "$SE_USB"
    run kc '' create example.com_alice@testhost --type ed25519
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "plugged in" ]]
    [ ! -e "$KEYCUTTER_SETTINGS" ]
    assert_mock_called "ssh-keygen -t ed25519 -f"
}

@test "not a mac: yubikey path, nothing written, no sc_auth" {
    create_mock_command "uname" 0 "Linux"
    run kc '' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    assert_mock_called "ssh-keygen -t ed25519-sk"
    [ ! -e "$KEYCUTTER_SETTINGS" ]
    ! grep -q 'sc_auth' "$BATS_TMPDIR/mock_calls.log"
}

@test "unknown authenticator value is refused" {
    run kc '' create example.com_alice@testhost --authenticator floppy
    [ "$status" -ne 0 ]
    [[ "$output" =~ "unknown authenticator" ]]
}

@test "keycutter.conf carries the secure-enclave provider match" {
    grep -q 'secure-enclave ]]' "$KEYCUTTER_ROOT/ssh_config/keycutter/keycutter.conf"
    grep -q 'SecurityKeyProvider /usr/lib/ssh-keychain.dylib' "$KEYCUTTER_ROOT/ssh_config/keycutter/keycutter.conf"
}

# --- GitHub keys: the ssh.github.com:443 alias ------------------------------
# `create` offers to symlink github.com_X to ssh.github.com_X (GitHub over port
# 443). keycutter.conf picks Apple's provider by `<keytag>.secure-enclave`, and
# the alias is its own keytag, so the marker has to follow the symlink or ssh
# signs the Enclave handle with the default (YubiKey) provider and fails.
# Review finding 2, 2026-10-18. stdin: 'n' (no GitHub upload), 'y' (symlink).

@test "github key: the ssh.github.com symlink gets its own secure-enclave marker" {
    run kc 'n\ny' create github.com_alice@testhost
    [ "$status" -eq 0 ]
    [ -L "$KEYCUTTER_SSH_KEY_DIR/ssh.github.com_alice@testhost" ]
    assert_file_exists "$KEYCUTTER_SSH_KEY_DIR/github.com_alice@testhost.secure-enclave"
    assert_file_exists "$KEYCUTTER_SSH_KEY_DIR/ssh.github.com_alice@testhost.secure-enclave"
}

@test "github key: a yubikey key's symlink gets no marker" {
    KEYCUTTER_AUTHENTICATOR=yubikey run kc 'n\ny' create github.com_alice@testhost
    [ "$status" -eq 0 ]
    [ -L "$KEYCUTTER_SSH_KEY_DIR/ssh.github.com_alice@testhost" ]
    [ ! -e "$KEYCUTTER_SSH_KEY_DIR/ssh.github.com_alice@testhost.secure-enclave" ]
}

@test "keycutter.conf: ssh -G gives ssh.github.com_X the Apple provider too (real ssh, real Match)" {
    command -v ssh >/dev/null || skip "no ssh"
    run kc 'n\ny' create github.com_alice@testhost
    [ "$status" -eq 0 ]
    # HOME is the test home, so the real Match exec blocks see the test keys/.
    local conf="$KEYCUTTER_ROOT/ssh_config/keycutter/keycutter.conf"
    run env HOME="$TEST_HOME" KEYCUTTER_ORIGIN=testhost ssh -G -F "$conf" github.com_alice
    [[ "$output" =~ securitykeyprovider\ /usr/lib/ssh-keychain.dylib ]]
    run env HOME="$TEST_HOME" KEYCUTTER_ORIGIN=testhost ssh -G -F "$conf" ssh.github.com_alice
    [[ "$output" =~ securitykeyprovider\ /usr/lib/ssh-keychain.dylib ]]
}

@test "keycutter keys does not list the .secure-enclave marker as a key" {
    run kc '' create example.com_alice@testhost
    [ "$status" -eq 0 ]
    run kc '' keys
    [[ "$output" =~ "example.com_alice@testhost" ]]
    [[ ! "$output" =~ "secure-enclave" ]]
}
