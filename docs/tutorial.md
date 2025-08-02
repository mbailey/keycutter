# Tutorial

This document walks you through some common workflows using Keycutter to manage SSH keys.

The output is omitted for readability.

## SSH Keys for multiple GitHub accounts

FIDO SSH keys make this possible (you can't do it using Yubikey GPG backed SSH).

Set KEYCUTTER_ORIGIN to specify which Yubikey the keys are for:

```bash
export KEYCUTTER_ORIGIN=yubikey1
```

Create an SSH key for GitHub user alex on dev1:

```bash
keycutter create github.com_alex
ssh -T github.com_alex
git clone git@github.com_alex:mbailey/keycutter.git
```

Create SSH key for github user alexwork:

```bash
keycutter create github.com_alexwork
ssh -T github.com_alexwork
git clone git@github.com_alexwork:mbailey/keycutter.git
```

## Create the same keys on another Yubikey

FIDO SSH keys never leave the device you need to create new keys
on each device. Keycutter's "SSH Keytag" pattern means you don't need
to alter your SSH config at all when connecting with another Yubikey.

```bash
export KEYCUTTER_ORIGIN=yubikey2
```

Then repeat the steps above for both GitHub accounts.

### Create SSH key for personal hosts

Set the origin and create the key:

```bash
export KEYCUTTER_ORIGIN=yubikey1
keycutter create personal
```

Create an entry in the keycutter/hosts file for your homeserver, then push the public key:

```bash
keycutter push-keys homeserver
```

This will attempt key authentication first, then fall back to password if needed.

Finally, connect to the host:

```bash
ssh homeserver
```

### Enable ssh agent forwarding to github from homeserver

```bash
keycutter agent add-host github homeserver
keycutter agent add-key github github.com_alex

ssh homeserver
ssh -T github.com_alex
```

## Pushing Keys to Remote Hosts

When you need to set up SSH access to a new host:

### First-time setup (no existing SSH access)

```bash
# Create a key for the specific host
keycutter create remote.example.com_alex

# Push the key to the host (will prompt for password)
keycutter push-keys remote.example.com

# Now you can SSH to the host
ssh remote.example.com
```

### Adding keys to a host with existing SSH access

```bash
# Create a new key
keycutter create prod-server_alex

# Push keys (will use existing SSH authentication)
keycutter push-keys prod-server

# Connect using the new key
ssh prod-server
```

### Checking which keys will be pushed

Before pushing keys, you can see which keys would be offered to a host:

```bash
# See which keys would be authorized
keycutter authorized-keys remote.example.com

# Then push them
keycutter push-keys remote.example.com
```

The `push-keys` command intelligently handles authentication by:

1. First attempting to use existing SSH key authentication
2. Falling back to password authentication if needed
3. Automatically handling keycutter's RemoteCommand configuration

## Updating Keycutter

Keycutter provides flexible update options to suit different workflows:

### Full Update

Update everything - git repository, requirements, SSH config, and touch detector:

```bash
keycutter update
```

This performs a complete update sequence and is the recommended approach for most users.

### Selective Updates

For development or specific maintenance tasks, you can update individual components:

```bash
# Pull latest changes from git (master branch only)
keycutter update git

# Update SSH config files from current installation
keycutter update config

# Check and update system requirements
keycutter update requirements

# Update YubiKey touch notification tool
keycutter update touch-detector
```

### Development Workflow

When developing or testing local changes:

```bash
# From your feature branch or worktree
keycutter update config  # Updates config without git pull

# Or use environment variable
KEYCUTTER_ROOT=/path/to/worktree keycutter update config
```

This is particularly useful when:
- Testing configuration changes before committing
- Working on feature branches
- Developing in git worktrees

For more details on development workflows, see the [Development Guide](development.md)
