# Changelog

## [Unreleased]

### Added
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