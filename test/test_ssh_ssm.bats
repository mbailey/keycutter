#!/usr/bin/env bats

# Security regression tests for ssh_config/keycutter/scripts/ssh-ssm (KC-50).
# Covers KC-47 finding B1 (remote-user %r command injection) and B7
# (pubkey-comment single-quote breakout) at the AWS-RunShellScript sink.

load test_helper

setup() {
  setup_test_environment
  SSH_SSM="$KEYCUTTER_ROOT/ssh_config/keycutter/scripts/ssh-ssm"
  # aws is the only external command ssh-ssm runs; mock it so we can assert
  # whether (and with what) it was invoked. "running" satisfies the
  # describe-instances state check and stands in for the returned command-id.
  create_mock_command "aws" 0 "running"
  init_mock_log
}

teardown() {
  cleanup_test_environment
}

@test "ssh-ssm rejects a hostile remote-user before any aws call (B1)" {
  run bash "$SSH_SSM" i-0123456789abcdef 'ec2-user; touch /tmp/PWNED #'
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid ssh user"* ]]
  # The whole point of B1: nothing attacker-influenced may reach AWS, so aws
  # must not have been invoked at all.
  run grep -q "MOCK_CALL: aws" "$BATS_TMPDIR/mock_calls.log"
  [ "$status" -ne 0 ]
}

@test "ssh-ssm still rejects a malformed instance-id before any aws call" {
  run bash "$SSH_SSM" not-an-instance-id ec2-user
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid instance-id"* ]]
  run grep -q "MOCK_CALL: aws" "$BATS_TMPDIR/mock_calls.log"
  [ "$status" -ne 0 ]
}

@test "ssh-ssm base64-wraps the public key so a hostile comment can't reach the payload (B7)" {
  # A pubkey whose comment tries to break out of the old single-quoted sink.
  printf '%s\n' "ssh-rsa AAAAFAKEKEYDATA evil'; touch /tmp/PWNED #" \
    > "$BATS_TMPDIR/evil.pub"
  run env KEYCUTTER_SSH_SSM_PUB_KEY="$BATS_TMPDIR/evil.pub" \
    bash "$SSH_SSM" i-0123456789abcdef ec2-user
  [ "$status" -eq 0 ]
  # send-command must have fired, or this test proves nothing.
  run grep -q "MOCK_CALL: aws ssm send-command" "$BATS_TMPDIR/mock_calls.log"
  [ "$status" -eq 0 ]
  # ...and the injected command must never appear verbatim in what aws received
  # (it is transported only as inert base64).
  run grep -F "touch /tmp/PWNED" "$BATS_TMPDIR/mock_calls.log"
  [ "$status" -ne 0 ]
}
