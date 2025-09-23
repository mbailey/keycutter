#!/usr/bin/env bats

# Test suite for keycutter ssh-known-hosts functionality

setup() {
  # Create temporary test environment
  export TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export KNOWN_HOSTS_FILE="$TEST_HOME/.ssh/known_hosts"
  export KNOWN_HOSTS_BACKUP_DIR="$TEST_HOME/.ssh/known_hosts_backups"
  export KEYCUTTER_TEST_MODE=1

  # Create .ssh directory
  mkdir -p "$HOME/.ssh"

  # Source keycutter
  export KEYCUTTER_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$KEYCUTTER_ROOT/lib/functions"
  source "$KEYCUTTER_ROOT/lib/ssh-known-hosts"

  # Create a sample known_hosts file
  cat > "$KNOWN_HOSTS_FILE" <<'EOF'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi35aw3OhQ7ogikDzs7qoFLMV/Uxe+7TQerS30Vk21tAeRmvbxDtQBQ2PmEwZI4JVojPNX8qvvK+V7KLJOqqnRP3v5kKcGm4dH5y9v00vqDWd+OZmcNJ8yosJKvJXqv9e7K9PqZanIcQ1jWUh/4NmJTB6ABXJmBbF3wefoPXdjzoaziV63iXotKSUR1NlYmz3TKiS83CqKL+UUtiNylHuBTuXdMjRXyZEvAB4xr5TuKSTKW5Gw6
example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFakeKeyForTesting1234567890abcdefghijklmnopqr
[192.168.1.1]:2222 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQFakeKeyForTestingWithPortNumber1234567890
EOF
}

teardown() {
  # Clean up test environment
  [[ -d "$TEST_HOME" ]] && rm -rf "$TEST_HOME"
}

# Test backup creation
@test "ssh-known-hosts backup creates backup file" {
  run ssh-known-hosts-backup
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Backed up known_hosts to:" ]]

  # Check backup file exists
  backup_files=("$KNOWN_HOSTS_BACKUP_DIR"/known_hosts.*)
  [ -f "${backup_files[0]}" ]
}

# Test listing backups
@test "ssh-known-hosts list-backups shows available backups" {
  # Create a backup first
  ssh-known-hosts-backup

  run ssh-known-hosts-list-backups
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Recent known_hosts backups:" ]]
  [[ "$output" =~ "known_hosts." ]]
  [[ "$output" =~ "6 lines" ]]  # Our test file has 6 lines
}

# Test delete-line with valid line number
@test "ssh-known-hosts delete-line removes specific line" {
  # Count original lines
  original_lines=$(wc -l < "$KNOWN_HOSTS_FILE")

  run ssh-known-hosts-delete-line 3
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Successfully deleted line 3 from known_hosts" ]]

  # Verify line was deleted
  new_lines=$(wc -l < "$KNOWN_HOSTS_FILE")
  [ "$new_lines" -eq $((original_lines - 1)) ]

  # Verify gitlab.com ssh-ed25519 line is gone
  run grep "^gitlab.com ssh-ed25519" "$KNOWN_HOSTS_FILE"
  [ "$status" -eq 1 ]
}

# Test delete-line with invalid line number
@test "ssh-known-hosts delete-line rejects invalid line number" {
  run ssh-known-hosts-delete-line 999
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Line 999 does not exist" ]]
}

# Test delete-line with no arguments
@test "ssh-known-hosts delete-line requires line number" {
  run ssh-known-hosts-delete-line
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Line number required" ]]
}

# Test delete-line with non-numeric argument
@test "ssh-known-hosts delete-line rejects non-numeric argument" {
  run ssh-known-hosts-delete-line abc
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Invalid line number: abc" ]]
}

# Test remove host functionality
@test "ssh-known-hosts remove finds and removes host entries" {
  skip "Interactive test - requires user input"
}

# Test remove non-existent host
@test "ssh-known-hosts remove handles non-existent host" {
  run ssh-known-hosts-remove nonexistent.com
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No entries found for host: nonexistent.com" ]]
}

# Test remove with port number
@test "ssh-known-hosts remove finds entries with port numbers" {
  skip "Interactive test - requires user input"
}

# Test restore functionality
@test "ssh-known-hosts restore restores from backup" {
  # Create initial backup
  run ssh-known-hosts-backup
  [ "$status" -eq 0 ]
  backup_file=$(echo "$output" | tail -1)

  # Count original lines
  original_lines=$(wc -l < "$KNOWN_HOSTS_FILE")

  # Wait a second to ensure different timestamp
  sleep 1

  # Modify known_hosts
  echo "test.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest" >> "$KNOWN_HOSTS_FILE"
  modified_lines=$(wc -l < "$KNOWN_HOSTS_FILE")
  [ "$modified_lines" -gt "$original_lines" ]

  # Verify test.com line was added
  run grep "^test.com" "$KNOWN_HOSTS_FILE"
  [ "$status" -eq 0 ]

  # Restore from backup
  run ssh-known-hosts-restore "$(basename "$backup_file")"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Successfully restored known_hosts from:" ]]

  # Verify restoration worked - should have original number of lines
  restored_lines=$(wc -l < "$KNOWN_HOSTS_FILE")
  [ "$restored_lines" -eq "$original_lines" ]

  # Verify test.com line is gone
  run grep "^test.com" "$KNOWN_HOSTS_FILE"
  [ "$status" -eq 1 ]
}

# Test keycutter integration
@test "keycutter ssh-known-hosts command is available" {
  run "$KEYCUTTER_ROOT/bin/keycutter" ssh-known-hosts
  [ "$status" -eq 1 ]  # Should fail with help message
  [[ "$output" =~ "Available subcommands:" ]]
  [[ "$output" =~ "delete-line" ]]
  [[ "$output" =~ "remove" ]]
  [[ "$output" =~ "backup" ]]
}