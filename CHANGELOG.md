# Changelog

## [Unreleased]

### Added
- SSH known_hosts management commands for easier handling of host key changes
  - `ssh-known-hosts delete-line <line_number>` - Delete a specific line from known_hosts
  - `ssh-known-hosts remove <hostname>` - Remove all entries for a host
  - `ssh-known-hosts fix <hostname>` - Interactively fix entries for a host
  - `ssh-known-hosts backup` - Create a backup of known_hosts
  - `ssh-known-hosts list-backups` - List available backups
  - `ssh-known-hosts restore <backup_file>` - Restore from a backup
- Smart host key verification handling in `push-keys` command
  - Automatically detects host key verification failures
  - Offers to remove old keys and retry the operation
  - Provides helpful guidance when SSH host keys have changed
- Automatic saving of generated SSH public keys to `.pub` files when extracted from private keys
- Automatic GitHub CLI installation prompt on macOS when missing
- Interactive dependency installation during requirements check
- Color-coded dependency status display with version information
- Symbols for colorblind accessibility in requirements check
- "Install all" option for batch dependency installation
- Automatic Bash installation via Homebrew on macOS

### Changed
- Enhanced requirements check to show all dependencies with their status
- Improved GitHub authentication to be ephemeral for security (auto-logout after key upload)

### Security
- GitHub CLI authentication is now ephemeral - automatically logs out after key upload to prevent persistent authentication

## Previous releases
(Previous changelog entries would go here)