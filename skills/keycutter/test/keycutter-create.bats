#!/usr/bin/env bats

# Test suite for keycutter-create.
#
# ssh-keygen is stubbed for every test except the "real hardware" path,
# which isn't testable in CI (needs a physical FIDO2 authenticator). The
# stub lets us assert on argv and simulate both the success and the "no
# FIDO2 support" failure paths without touching real key material or
# hardware.

setup() {
  SCRIPT_DIR="$BATS_TEST_DIRNAME/../scripts"
  CREATE="$SCRIPT_DIR/keycutter-create"

  TEST_DIR=$(mktemp -d)
  DEST="$TEST_DIR/dest"
  STUB_BIN="$TEST_DIR/bin"
  mkdir -p "$STUB_BIN"

  # Default stub: records argv, "creates" the key + pub files, exits 0.
  cat > "$STUB_BIN/ssh-keygen" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${SSH_KEYGEN_STUB_ARGS_FILE:-/dev/null}"
if [[ -n "${SSH_KEYGEN_STUB_FAIL:-}" ]]; then
  echo "stub: simulated FIDO2 failure" >&2
  exit 1
fi
# Parse -f <path> out of argv to know where to "write" the key.
args=("$@")
for ((i=0; i<${#args[@]}; i++)); do
  if [[ "${args[i]}" == "-f" ]]; then
    keypath="${args[i+1]}"
    echo "fake-private-key" > "$keypath"
    echo "fake-public-key"  > "${keypath}.pub"
  fi
done
exit 0
STUB
  chmod +x "$STUB_BIN/ssh-keygen"

  export PATH="$STUB_BIN:$PATH"
  export SSH_KEYGEN_STUB_ARGS_FILE="$TEST_DIR/keygen-args"
  export KEYCUTTER_ORIGIN="testhost"
  # Tests run with stdin from /dev/null; the real tool refuses that
  # (it needs a human at a terminal). One test below drops this.
  export KEYCUTTER_ALLOW_NO_TTY=1
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "script exists and is executable" {
  [ -f "$CREATE" ]
  [ -x "$CREATE" ]
}

@test "shellcheck-clean" {
  command -v shellcheck >/dev/null || skip "shellcheck not installed"
  run shellcheck "$CREATE"
  [ "$status" -eq 0 ]
}

@test "-h prints usage and exits 0" {
  run "$CREATE" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "keycutter-create" ]]
}

@test "refuses empty keytag" {
  run "$CREATE" "" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "empty" ]]
}

@test "refuses missing keytag argument" {
  run "$CREATE" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "keytag is required" ]]
}

@test "refuses a keytag containing '/'" {
  run "$CREATE" "a/b" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "must not contain '/'" ]]
}

@test "refuses a path-traversal keytag" {
  run "$CREATE" "../../etc/passwd" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "must not contain '/'" ]]
}

@test "refuses a leading-dash keytag (via --)" {
  run "$CREATE" -- "-foo" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "must not start with '-'" ]]
}

@test "refuses characters outside the allowed charset" {
  run "$CREATE" 'foo$(bar)' --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "invalid characters" ]]
}

# Traversal-guard belt-and-suspenders: '..' is inside the charset (dots are legal),
# and with '/' banned it can't traverse -- but reject it anyway so junk
# names like 'x..y' never reach keys/.
@test "refuses a keytag containing '..'" {
  run "$CREATE" "a..b" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "must not contain '..'" ]]
}

# Review finding B-4: the charset admits multiple '@', but the FINAL
# keytag (post device-suffix append) is service_user@machine -- at most
# one '@'. 'a@b@c' already has an '@', so with_device_suffix leaves it
# unchanged and the post-append validate_keytag ... final call rejects it.
@test "refuses a final keytag with more than one '@'" {
  run "$CREATE" "a@b@c" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "at most one '@'" ]]
  [ ! -e "$DEST" ]
}

@test "refuses a final keytag with an empty left side of '@'" {
  run "$CREATE" "@host" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "non-empty on both sides" ]]
  [ ! -e "$DEST" ]
}

@test "refuses a final keytag with an empty right side of '@'" {
  run "$CREATE" "name@" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "non-empty on both sides" ]]
  [ ! -e "$DEST" ]
}

@test "does not create any files when validation fails" {
  run "$CREATE" "bad/tag" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [ ! -e "$DEST" ]
}

@test "accepts a valid keytag with an explicit device suffix" {
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [ -f "$DEST/keys/github.com_alice@work" ]
  [ -f "$DEST/keys/github.com_alice@work.pub" ]
}

# /dev/tty may or may not be readable inside a test harness (depends on
# whether the runner has a controlling terminal) -- so this only asserts
# the outcome that must hold either way: the host name gets appended
# when no explicit device was given, whichever branch handles it. The
# origin (KEYCUTTER_ORIGIN=testhost in setup) names the authenticator,
# never the device: keys/%n@%L only ever matches the host name.
#
# Decline-append coverage, without faking a tty: the decline branch
# returns the keytag with zero '@', and the final-phase validate_keytag
# explicitly ALLOWS zero '@' (it rejects only multi-'@' and empty-sided
# '@') precisely so declining stays a supported choice — the script warns
# instead of dying. This test proves the pre-append guard accepts bare
# keytags; the zero-'@' final case is guaranteed by that explicit
# allowance (see validate_keytag's final-phase comment), so no
# expect/socat tty simulation is needed.
@test "appends the host name (not the origin) as device suffix non-interactively" {
  run "$CREATE" "github.com_alice" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [ -f "$DEST/keys/github.com_alice@$(hostname -s)" ]
  [ ! -e "$DEST/keys/github.com_alice@testhost" ]
}

stat_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

@test "creates dest and keys/ with 0700 permissions" {
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [ "$(stat_mode "$DEST")" = "700" ]
  [ "$(stat_mode "$DEST/keys")" = "700" ]
}

@test "refuses to overwrite an existing key" {
  mkdir -p "$DEST/keys"
  echo existing > "$DEST/keys/github.com_alice@work"
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "already exists" ]]
}

@test "generates with -t ed25519-sk and no software-key fallback" {
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  grep -q -- '-t ed25519-sk' "$SSH_KEYGEN_STUB_ARGS_FILE"
}

@test "--resident passes -O resident to ssh-keygen" {
  run "$CREATE" "github.com_alice@work" --resident --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  grep -q -- '-O resident' "$SSH_KEYGEN_STUB_ARGS_FILE"
}

@test "omits -O resident without --resident" {
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  ! grep -q -- '-O resident' "$SSH_KEYGEN_STUB_ARGS_FILE"
}

@test "on FIDO2 failure: exits non-zero, no software fallback, prints diagnosis" {
  export SSH_KEYGEN_STUB_FAIL=1
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "FIDO2" ]]
  [[ "$output" =~ "No software-key fallback" ]] || [[ "$output" =~ "software-key fallback" ]]
  [ ! -e "$DEST/keys/github.com_alice@work" ]
}

@test "prints, but does not run, the gh and ssh follow-ups" {
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gh ssh-key add --type authentication" ]]
  [[ "$output" =~ "gh ssh-key add --type signing" ]]
  [[ "$output" =~ "ssh -T github.com_alice" ]]
  [[ "$output" =~ "SAML" ]]
}

@test "mutates no ssh config (fork c: create is a pure ssh-keygen wrapper)" {
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  # Nothing under $DEST except keys/ -- no conf files touched or written.
  [ "$(find "$DEST" -maxdepth 1 -mindepth 1)" = "$DEST/keys" ]
  [ ! -f "$DEST/keycutter.conf" ]
  [ ! -f "$DEST/hosts/keys.conf" ]
}

# --- Secure Enclave path (--authenticator secure-enclave) -----------------
# No finger, no Enclave: uname, ioreg, sc_auth and ssh-keygen are all
# stubs. sc_auth records what it was asked to mint and lists it back;
# ssh-keygen -K "downloads" a handle into the cwd. Real sc_auth is never run.

enclave_stubs() {
  export KEYCUTTER_SK_PROVIDER_APPLE="$TEST_DIR/ssh-keychain.dylib"
  : > "$KEYCUTTER_SK_PROVIDER_APPLE"
  export SC_AUTH_STATE="$TEST_DIR/sc_auth-state"
  export SC_AUTH_LOG="$TEST_DIR/sc_auth-log"

  printf '#!/usr/bin/env bash\necho Darwin\n' > "$STUB_BIN/uname"
  # ykman: no YubiKey, whatever is plugged into the machine running the tests.
  printf '#!/usr/bin/env bash\nexit 1\n' > "$STUB_BIN/ykman"
  # ioreg: unlocked, lid open, no YubiKey, unless told otherwise.
  cat > "$STUB_BIN/ioreg" <<'STUB'
#!/usr/bin/env bash
[[ -n "${IOREG_LOCKED:-}" && "$*" == *Root* ]] && echo '"IOConsoleLocked" = Yes'
exit 0
STUB
  cat > "$STUB_BIN/sc_auth" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SC_AUTH_LOG"
case "$1" in
  create-ctk-identity)
    [[ -n "${SC_AUTH_FAIL:-}" ]] && { echo "stub: refused" >&2; exit 0; }
    while [[ $# -gt 0 ]]; do [[ $1 == -l ]] && echo "$2" >> "$SC_AUTH_STATE"; shift; done ;;
  list-ctk-identities)
    echo "Key Type    Public Key Hash    Prot    Label    Common Name"
    [[ -f $SC_AUTH_STATE ]] && while read -r l; do echo "p-256 SHA256:FAKEFP bio $l $l"; done < "$SC_AUTH_STATE" ;;
esac
exit 0
STUB
  cat > "$STUB_BIN/ssh-keygen" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${SSH_KEYGEN_STUB_ARGS_FILE:-/dev/null}"
case " $* " in
  *" -K "*) echo handle > id_ecdsa_sk_rk_x
            echo "sk-ecdsa-sha2-nistp256@openssh.com AAAAFAKE ssh:" > id_ecdsa_sk_rk_x.pub ;;
  *" -lf "*) echo "256 SHA256:FAKEFP ssh: (ECDSA-SK)" ;;
esac
exit 0
STUB
  chmod +x "$STUB_BIN"/uname "$STUB_BIN"/ykman "$STUB_BIN"/ioreg "$STUB_BIN"/sc_auth "$STUB_BIN"/ssh-keygen
}

@test "enclave: --dry-run prints the exact sc_auth and ssh-keygen commands, runs and writes nothing" {
  enclave_stubs
  run "$CREATE" "github.com_alice@laptop" --authenticator secure-enclave --dry-run --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sc_auth create-ctk-identity -l github.com_alice@laptop -k p-256-ne -t bio -N github.com_alice@laptop" ]]
  [[ "$output" =~ "ssh-keygen -K -w $KEYCUTTER_SK_PROVIDER_APPLE" ]]
  [[ "$output" =~ "SecurityKeyProvider /usr/lib/ssh-keychain.dylib" ]]
  [ ! -e "$SC_AUTH_LOG" ]
  [ ! -e "$SSH_KEYGEN_STUB_ARGS_FILE" ]
  [ ! -e "$DEST" ]
}

@test "enclave: --dry-run works on a machine that cannot run it, and says so" {
  export KEYCUTTER_SK_PROVIDER_APPLE="$TEST_DIR/absent.dylib"
  run "$CREATE" "github.com_alice@laptop" --authenticator enclave --dry-run --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sc_auth create-ctk-identity" ]]
  [[ "$output" =~ "cannot run it" ]]
  [ ! -e "$DEST" ]
}

@test "enclave: mints, downloads the matching handle, writes key and .pub, no config" {
  enclave_stubs
  run "$CREATE" "github.com_alice@laptop" --authenticator secure-enclave --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  grep -q -- '-l github.com_alice@laptop -k p-256-ne -t bio' "$SC_AUTH_LOG"
  grep -q -- "-K -w $KEYCUTTER_SK_PROVIDER_APPLE" "$SSH_KEYGEN_STUB_ARGS_FILE"
  ! grep -q -- '-t ed25519-sk' "$SSH_KEYGEN_STUB_ARGS_FILE"
  [ -f "$DEST/keys/github.com_alice@laptop" ]
  [ ! -e "$DEST/keys/github.com_alice@laptop.secure-enclave" ]
  [ "$(find "$DEST" -maxdepth 1 -mindepth 1)" = "$DEST/keys" ]
  [ "$(cat "$DEST/keys/github.com_alice@laptop.pub")" = "sk-ecdsa-sha2-nistp256@openssh.com AAAAFAKE github.com_alice@laptop" ]
  [ "$(stat_mode "$DEST/keys/github.com_alice@laptop")" = "600" ]
}

@test "enclave: KEYCUTTER_AUTHENTICATOR=mac selects it too" {
  enclave_stubs
  KEYCUTTER_AUTHENTICATOR=mac run "$CREATE" "github.com_alice@laptop" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  grep -q create-ctk-identity "$SC_AUTH_LOG"
}

@test "the origin names the authenticator: a Mac whose origin is its host name defaults to the Enclave" {
  enclave_stubs
  KEYCUTTER_ORIGIN="$(hostname -s)" run "$CREATE" "github.com_alice" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Secure Enclave" ]]
  grep -q create-ctk-identity "$SC_AUTH_LOG"
  ! grep -q -- '-t ed25519-sk' "$SSH_KEYGEN_STUB_ARGS_FILE"
}

@test "the origin names the authenticator: any other origin on a Mac defaults to the YubiKey" {
  enclave_stubs
  # (the Enclave ssh-keygen stub writes no key for -f, so only argv is checked)
  KEYCUTTER_ORIGIN="$(hostname -s)-yk" run "$CREATE" "github.com_alice" --dest "$DEST" </dev/null
  grep -q -- '-t ed25519-sk' "$SSH_KEYGEN_STUB_ARGS_FILE"
  [ ! -e "$SC_AUTH_LOG" ]
}

@test "no terminal: a real create refuses and tells an agent to hand it over" {
  unset KEYCUTTER_ALLOW_NO_TTY
  run "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "your own terminal" ]]
  [ ! -e "$DEST" ]
}

@test "no terminal: --dry-run still works" {
  unset KEYCUTTER_ALLOW_NO_TTY
  run "$CREATE" "github.com_alice@work" --dry-run --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
}

@test "no YubiKey on an Enclave-capable Mac: the failure points at the Enclave, not brew" {
  enclave_stubs
  printf '#!/usr/bin/env bash\necho stub fail >&2; exit 1\n' > "$STUB_BIN/ssh-keygen"
  run "$CREATE" "github.com_alice@laptop" --authenticator yubikey --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--authenticator secure-enclave" ]]
  [[ ! "$output" =~ "brew install" ]]
}

@test "enclave: sc_auth exit 0 but no identity -> fails, writes no key" {
  enclave_stubs
  SC_AUTH_FAIL=1 run "$CREATE" "github.com_alice@laptop" --authenticator secure-enclave --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "did not create identity" ]]
  [ ! -e "$DEST/keys/github.com_alice@laptop" ]
}

@test "enclave: refuses with the screen locked, before minting" {
  enclave_stubs
  IOREG_LOCKED=1 run "$CREATE" "github.com_alice@laptop" --authenticator secure-enclave --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "screen is locked" ]]
  [ ! -e "$SC_AUTH_LOG" ] || ! grep -q create-ctk-identity "$SC_AUTH_LOG"
}

@test "enclave: refuses to mint a twin of an existing Enclave label" {
  enclave_stubs
  echo "github.com_alice@laptop" > "$SC_AUTH_STATE"
  run "$CREATE" "github.com_alice@laptop" --authenticator secure-enclave --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "already exists" ]]
  ! grep -q create-ctk-identity "$SC_AUTH_LOG"
}

@test "enclave: refuses off a Mac (no dylib), without --dry-run" {
  export KEYCUTTER_SK_PROVIDER_APPLE="$TEST_DIR/absent.dylib"
  run "$CREATE" "github.com_alice@laptop" --authenticator secure-enclave --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "need macOS" ]]
}

@test "enclave: --resident is refused (YubiKey-only)" {
  run "$CREATE" "github.com_alice@laptop" --authenticator secure-enclave --resident --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "YubiKey-only" ]]
}

@test "unknown --authenticator is refused" {
  run "$CREATE" "github.com_alice@laptop" --authenticator floppy --dest "$DEST" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" =~ "unknown authenticator" ]]
}

@test "stock macOS bash 3.2: yubikey path without --resident does not trip set -u" {
  [ -x /bin/bash ] || skip "no /bin/bash"
  run /bin/bash "$CREATE" "github.com_alice@work" --dest "$DEST" </dev/null
  [ "$status" -eq 0 ]
  [ -f "$DEST/keys/github.com_alice@work" ]
}
