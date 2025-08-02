# Keycutter Development Guide

This guide explains how to develop and test Keycutter features locally.

## Development Workflow

### Testing Local Changes

When developing Keycutter features, you often need to test configuration changes without pulling from git. The update subcommands make this easy:

#### 1. Update Config from Local Files

```bash
# From your feature branch or worktree
keycutter update config
```

This updates your SSH config files from the current directory without performing a git pull.

#### 2. Update Individual Components

```bash
# Update only SSH config
keycutter update config

# Check requirements only
keycutter update requirements

# Update touch detector only
keycutter update touch-detector
```

#### 3. Using Environment Variables

You can override the Keycutter installation directory:

```bash
# Test from a different directory
KEYCUTTER_ROOT=/path/to/your/worktree keycutter update config

# Or export it for the session
export KEYCUTTER_ROOT=/path/to/your/worktree
keycutter update config
```

### Working with Git Worktrees

Git worktrees are ideal for developing Keycutter features:

```bash
# Create a new worktree for your feature
git worktree add ../keycutter-my-feature -b feat/my-feature

# Navigate to the worktree
cd ../keycutter-my-feature

# Make your changes
vim bin/keycutter

# Test your changes locally
./bin/keycutter update config

# Or install from the worktree
KEYCUTTER_ROOT=$(pwd) ./install.sh
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test file
./test/run_tests.sh test_keycutter.bats

# Run with verbose output
make test-verbose

# Run specific test
bats test/test_keycutter.bats -f 'update'
```

### Code Quality

Before committing, ensure your code passes quality checks:

```bash
# Run shellcheck
make shellcheck

# Clean test artifacts
make clean
```

## Update Command Details

The `keycutter update` command has been modularized into subcommands:

### `keycutter update`
Runs the full update sequence:
1. Pull from git (only on master branch)
2. Check requirements
3. Update SSH config
4. Update touch detector

### `keycutter update git`
- Pulls latest changes from the git repository
- Only works on the master branch
- Skips update if on a feature branch

### `keycutter update config`
- Updates SSH config files from the current installation
- Preserves existing host files
- Shows diffs and prompts for overwrites
- Perfect for testing local changes

### `keycutter update requirements`
- Checks system requirements
- Verifies all dependencies are installed

### `keycutter update touch-detector`
- Updates the YubiKey touch notification tool
- Only prompts if FIDO keys are detected

## Common Development Scenarios

### Testing a New SSH Config Template

1. Edit the template in `ssh_config/keycutter/`
2. Run `keycutter update config` to install it
3. Verify with `keycutter config <hostname>`

### Adding a New Service Provider

1. Create the service module in `lib/`
2. Add SSH config in `ssh_config/keycutter/hosts/`
3. Update keytag detection in `bin/keycutter`
4. Test with `keycutter create service.com_username`
5. Update documentation

### Debugging SSH Connections

```bash
# See what config would be used
keycutter config github.com_alex

# Test the connection with verbose output
ssh -vvv github.com_alex

# Check which keys would be offered
keycutter authorized-keys github.com_alex
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and shellcheck
5. Update documentation
6. Submit a pull request

Remember to:
- Follow existing code style
- Add tests for new features
- Update help text when adding commands
- Document any new environment variables