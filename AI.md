# CLAUDE.md

This file provides guidance to AI Coding Assistants (e.g. claude.ai/code) when working with code in this repository.

## Commands

### Testing
```bash
# Run all tests
make test

# Run tests with verbose output
make test-verbose

# Run a specific test file
./test/run_tests.sh test_keycutter.bats

# Run specific test with BATS directly
bats test/test_keycutter.bats -f 'help'
```

### Code Quality
```bash
# Run shellcheck on all shell scripts
make shellcheck
```

### Installation
```bash
# Install keycutter
make install
# or
./install.sh
```

### Development Workflow
```bash
# Clean up test artifacts
make clean

# Update keycutter (for users)
keycutter update

# Test local changes without git pull
keycutter update config

# Update specific components
keycutter update git          # Pull from git
keycutter update config       # Update SSH config
keycutter update requirements # Check requirements
keycutter update touch-detector # Update touch detector
```

## Architecture

Keycutter is a Bash-based SSH key management tool focused on FIDO2/YubiKey support and multi-account SSH access.

### Core Components

1. **Main Script** (`bin/keycutter`): Entry point that sources libraries and handles command routing
2. **Libraries** (`lib/`): Modular functions split by concern
   - `functions`: Core functionality loader
   - `github`: GitHub-specific operations
   - `ssh`: SSH key and config management
   - `utils`: Common utilities
   - `yubikey`: YubiKey-specific operations

3. **SSH Configuration Structure** (`ssh_config/keycutter/`):
   - `agents/`: SSH agent forwarding rules for security boundaries
   - `hosts/`: Host-specific configurations using keytag convention
   - `keys/`: SSH keys following the keytag naming pattern
   - `scripts/`: Helper scripts for SSH operations (ssh-ssm, ssh-agent-ensure)

### Key Concepts

**SSH Keytags**: A naming convention that enables multi-account SSH without manual config. Keys are named as `service_username` (e.g., `github.com_alex`), allowing automatic routing.

**Selective Agent Forwarding**: Security feature that controls which keys are available to which hosts, preventing key misuse across security boundaries.

**FIDO SSH Keys**: Hardware-backed keys requiring physical presence, providing enhanced security through YubiKeys or similar devices.

### Testing Infrastructure

Tests use BATS (Bash Automated Testing System) with comprehensive coverage of:
- Core keycutter commands
- SSH configuration impact analysis
- Installation processes
- Touch detector functionality

Test isolation is achieved through:
- Temporary HOME directories
- Mocked external commands
- Test mode flag (`KEYCUTTER_TEST_MODE`) to bypass stdin reattachment

### Environment Variables

Key environment variables used throughout:
- `KEYCUTTER_CONFIG`: Main config file location (default: `~/.ssh/keycutter/keycutter.conf`)
- `KEYCUTTER_CONFIG_DIR`: Config directory (default: `~/.ssh/keycutter/`)
- `KEYCUTTER_SSH_KEY_DIR`: Key storage directory (default: `~/.ssh/keycutter/keys/`)
- `KEYCUTTER_ORIGIN`: Origin hostname for key management
- `KEYCUTTER_TEST_MODE`: Enable test mode behaviors
