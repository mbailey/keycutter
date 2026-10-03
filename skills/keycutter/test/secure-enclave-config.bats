#!/usr/bin/env bats

# The origin names the authenticator (whole machine, not per key):
# `keycutter install` on a Mac with Apple's provider whose origin equals
# its host name uncomments `SecurityKeyProvider /usr/lib/ssh-keychain.dylib`
# under `Host *`. Any other origin, or not a Mac, leaves it a comment.
# uname is stubbed; --dest is a scratch dir; ssh -G connects to nothing.

INSTALL="$BATS_TEST_DIRNAME/../scripts/keycutter-install"
CONF="$BATS_TEST_DIRNAME/../templates/keycutter/keycutter.conf"
LINE='SecurityKeyProvider /usr/lib/ssh-keychain.dylib'

setup() {
  TEST_DIR=$(mktemp -d)
  STUB_BIN="$TEST_DIR/bin"; mkdir -p "$STUB_BIN"
  export KEYCUTTER_SK_PROVIDER_APPLE="$TEST_DIR/ssh-keychain.dylib"
  : > "$KEYCUTTER_SK_PROVIDER_APPLE"
  unset KEYCUTTER_ORIGIN
}

teardown() { rm -rf "$TEST_DIR"; }

uname_is() { printf '#!/usr/bin/env bash\necho %s\n' "$1" > "$STUB_BIN/uname"; chmod +x "$STUB_BIN/uname"; }
install_to() { PATH="$STUB_BIN:$PATH" run "$INSTALL" --force --dest "$TEST_DIR/kc" </dev/null; }
provider() { ssh -F "$TEST_DIR/kc/keycutter.conf" -G github.com_alice | awk 'tolower($1)=="securitykeyprovider" {print $2}'; }

@test "template: the provider line ships commented, and there is no Match exec" {
  grep -q "^  # ${LINE}\$" "$CONF"
  ! grep -q "^  ${LINE}" "$CONF"
  ! grep -qi '^Match' "$CONF"
}

@test "Mac, origin = host name: installed config has the line under Host *, ssh uses Apple's provider" {
  uname_is Darwin
  install_to
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Secure Enclave" ]]
  grep -q "^  ${LINE}\$" "$TEST_DIR/kc/keycutter.conf"
  [ "$(provider)" = "/usr/lib/ssh-keychain.dylib" ]
}

@test "Mac, origin = <host>-yk: no line, ssh keeps the default provider" {
  uname_is Darwin
  KEYCUTTER_ORIGIN="$(hostname -s)-yk" install_to
  [ "$status" -eq 0 ]
  cmp -s "$CONF" "$TEST_DIR/kc/keycutter.conf"
  [ "$(provider)" = "internal" ]
}

@test "not a Mac: no line" {
  uname_is Linux
  install_to
  [ "$status" -eq 0 ]
  cmp -s "$CONF" "$TEST_DIR/kc/keycutter.conf"
}

@test "Mac without Apple's provider: no line" {
  uname_is Darwin
  rm -f "$KEYCUTTER_SK_PROVIDER_APPLE"
  install_to
  [ "$status" -eq 0 ]
  cmp -s "$CONF" "$TEST_DIR/kc/keycutter.conf"
}

@test "re-install on the same Mac is in sync (the rendered file is what the plan compares)" {
  uname_is Darwin
  install_to
  install_to
  [ "$status" -eq 0 ]
  [[ "$output" =~ "in sync" ]]
}

@test "no terminal: install falls back to dry-run and asks for the user's terminal, not --force" {
  uname_is Darwin
  PATH="$STUB_BIN:$PATH" run "$INSTALL" --dest "$TEST_DIR/kc" </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" =~ "their own terminal" ]]
  [[ ! "$output" =~ "rerun with --force" ]]
  [ ! -e "$TEST_DIR/kc" ]
}

# --- install safety (review, 2026-10-08) -------------------------

stat_mode() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"; }

@test "install makes the tree 0700, whatever the umask" {
  uname_is Linux
  umask 022
  install_to
  [ "$status" -eq 0 ]
  [ "$(stat_mode "$TEST_DIR/kc")" = "700" ]
}

@test "install keeps a backup before overwriting a changed file, outside any Include glob" {
  uname_is Linux
  install_to
  echo "# my edit" >> "$TEST_DIR/kc/hosts/work.conf"
  install_to
  [ "$status" -eq 0 ]
  ls "$TEST_DIR"/kc/hosts/work.conf.keycutter-bak.* >/dev/null
  grep -q '# my edit' "$TEST_DIR"/kc/hosts/work.conf.keycutter-bak.*
  ! grep -q '# my edit' "$TEST_DIR/kc/hosts/work.conf"
  ! ls "$TEST_DIR"/kc/hosts/*.conf | grep -q keycutter-bak
}
