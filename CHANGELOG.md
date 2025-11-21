# Changelog

All notable changes to Keycutter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### **Git Commit Signing with SSH Keys** (KC-12)

Hardware-backed commit signatures using the same SSH keys you use for git operations. Automatic key detection from git remotes makes signed commits effortless.

**Core Features:**
- **Automatic SSH Key Detection** - Inspects git remote URLs and automatically selects the correct SSH key
- **Simple Commands** - `git-signing enable`, `disable`, and `status` for easy management
- **FIDO2/YubiKey Support** - Hardware-backed signatures requiring physical presence
- **Multi-Account Friendly** - Works seamlessly with keycutter's keytag system
- **Global or Per-Repo** - Enable signing globally or for specific repositories

**Commands:**
- `keycutter git-signing enable [key_file]` - Enable commit signing (auto-detects key from remote)
- `keycutter git-signing enable --global` - Enable for all repositories
- `keycutter git-signing disable [--global]` - Disable commit signing
- `keycutter git-signing status` - Show current signing configuration
- Support for token expansion: `%i` for SSH_AUTH_SOCK identity

**Implementation:**
- Helper functions for git remote URL parsing and SSH key detection
- 25 comprehensive BATS tests covering all functions and edge cases
- Complete bash shell completion for all commands and flags
- Comprehensive help system with examples
- Production-ready with 109 total tests passing

**Use Cases:**
- Multi-account development with automatic key selection per repository
- Enhanced security for critical repositories using hardware-backed signatures
- Compliance and audit trails with cryptographically verified commits
- Non-repudiation proof for commits (YubiKey touch proves physical presence)

#### **SSH Known Hosts Management**

Commands for easier handling of host key changes:
- `ssh-known-hosts delete-line <line_number>` - Delete a specific line from known_hosts
- `ssh-known-hosts remove <hostname>` - Remove all entries for a host
- `ssh-known-hosts fix <hostname>` - Interactively fix entries for a host
- `ssh-known-hosts backup` - Create a backup of known_hosts
- `ssh-known-hosts list-backups` - List available backups
- `ssh-known-hosts restore <backup_file>` - Restore from a backup

Smart host key verification handling in `push-keys` command:
- Automatically detects host key verification failures
- Offers to remove old keys and retry the operation
- Provides helpful guidance when SSH host keys have changed

#### **Dependency Management Improvements**
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