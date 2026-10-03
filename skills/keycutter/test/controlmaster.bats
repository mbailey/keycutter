#!/usr/bin/env bats

# Test suite for the shipped ControlMaster template (multi-account
# socket-collision fix).
#
# Two machine-checkable properties:
#   (i)  Inertness — the shipped controlmaster.conf has ZERO active
#        (non-comment) directive lines. It ships fully commented, matching
#        upstream, so a fresh install turns nothing on until the user opts in.
#   (ii) Distinct sockets when enabled — when the opt-in block is uncommented,
#        two github.com_* aliases (which keycutter collapses to a single
#        `HostName github.com`) resolve to DIFFERENT ControlPath sockets. This
#        is the %n-not-%h fix: with %h both identities would share one master
#        socket, letting one GitHub account ride another's authenticated
#        session.

CONF="$BATS_TEST_DIRNAME/../templates/keycutter/controlmaster/controlmaster.conf"

setup() {
  TEST_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "shipped controlmaster.conf exists" {
  [ -f "$CONF" ]
}

@test "shipped controlmaster.conf has zero active (non-comment) directive lines" {
  # Anything that is not blank and does not start with '#' is an active
  # directive. The shipped file must have none — it is inert until opt-in.
  active=$(grep -vE '^[[:space:]]*(#|$)' "$CONF" || true)
  [ -z "$active" ]
}

@test "opt-in block uses %n (not %h) in ControlPath" {
  grep -q 'ControlPath .*%r@%n:%p' "$CONF"
  ! grep -q 'ControlPath .*%r@%h:%p' "$CONF"
}

# Uncomment the marked opt-in block into a runnable fixture, and prepend the
# HostName-collapse stanza that keycutter.conf ships (github.com* -> HostName
# github.com). Without that collapse the fixture could not discriminate %n
# from %h, because the two aliases already differ in %h (reviewer finding N1).
@test "when enabled, two github.com aliases get DISTINCT control sockets" {
  command -v ssh >/dev/null || skip "ssh not installed"

  fixture="$TEST_DIR/ssh_config"
  {
    # keycutter's load-bearing collapse: every github.com_* alias -> github.com
    echo "Host github.com github.com_*"
    echo "  HostName github.com"
    # the opt-in ControlMaster block, uncommented from the shipped conf
    awk '
      /^# >>> keycutter controlmaster/ { f=1; next }
      /^# <<< keycutter controlmaster/ { f=0; next }
      f { sub(/^# ?/, ""); print }
    ' "$CONF"
  } > "$fixture"

  # Sanity: the uncommented fixture must actually carry a ControlPath directive.
  grep -q 'ControlPath' "$fixture"

  cp_a=$(ssh -F "$fixture" -G github.com_alpha 2>/dev/null | awk '/^controlpath /{print $2}')
  cp_b=$(ssh -F "$fixture" -G github.com_bravo 2>/dev/null | awk '/^controlpath /{print $2}')

  [ -n "$cp_a" ]
  [ -n "$cp_b" ]
  [ "$cp_a" != "$cp_b" ]
}
