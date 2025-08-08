# Keycutter Core Functionality - User Perspective

## Overview

Keycutter is a command-line tool that simplifies SSH key management for users who need to:
- Use hardware security keys (FIDO2/YubiKey) for SSH authentication
- Access multiple accounts on the same service (e.g., personal and work GitHub accounts)
- Maintain security boundaries between different environments
- Avoid manual SSH configuration editing

## Core Concepts

### SSH Keytags
The foundation of keycutter is the "SSH Keytag" - a naming convention that eliminates manual SSH configuration:

**Format:** `<service>_<username>@<device>`

Examples:
- `github.com_alex@yubikey1` - GitHub user 'alex' on YubiKey #1
- `github.com_work@laptop` - Work GitHub account on laptop
- `homelab_admin@yubikey2` - Admin access to home servers

### Zero-Config Multi-Account SSH
With keytags, you can SSH to services using multiple accounts without any Host configuration:

```bash
# Clone repos from different GitHub accounts
git clone git@github.com_personal:myproject/repo.git
git clone git@github.com_work:company/repo.git

# SSH to the same accounts
ssh -T github.com_personal
ssh -T github.com_work
```

## Primary User Commands

### 1. Create SSH Keys
```bash
keycutter create <keytag>
```

Creates a FIDO2 SSH key on your hardware security device:
- Prompts for YubiKey touch/PIN during creation
- Automatically adds the key to supported services (GitHub, SourceHut)
- Stores keys in organized directory structure
- Options:
  - `--resident` - Creates resident key (stored on YubiKey)
  - `--type <type>` - Key type (default: ed25519-sk)

Example workflow:
```bash
# Set which YubiKey you're using
export KEYCUTTER_ORIGIN=yubikey1

# Create key for personal GitHub
keycutter create github.com_alex
# -> Creates key, prompts to upload to GitHub
# -> Sets up automatic routing for github.com_alex

# Create key for work GitHub  
keycutter create github.com_work
```

### 2. Push Keys to Remote Hosts
```bash
keycutter push-keys <hostname>
```

Deploys your public SSH keys to remote servers:
- Automatically determines which keys to push based on SSH config
- Tries existing SSH auth first, falls back to password if needed
- Handles keycutter's special RemoteCommand configuration

Example:
```bash
# Push keys to a server
keycutter push-keys myserver.com

# Check which keys would be pushed first
keycutter authorized-keys myserver.com
```

### 3. View Authorized Keys
```bash
keycutter authorized-keys <hostname>
```

Shows which public keys would be offered to a host based on your SSH configuration. Useful for:
- Verifying key selection before pushing
- Debugging authentication issues
- Auditing key access

### 4. Update Keycutter
```bash
keycutter update [component]
```

Keeps keycutter and its components up to date:
- `keycutter update` - Full update (git, config, requirements, touch-detector)
- `keycutter update git` - Pull latest from repository
- `keycutter update config` - Update SSH config from current installation
- `keycutter update requirements` - Check/update system dependencies
- `keycutter update touch-detector` - Update YubiKey touch notifier

## Security Features

### Selective Agent Forwarding
Keycutter implements security boundaries through agent profiles:

```bash
# Add specific keys to an agent profile
keycutter agent add-key work gitlab.company.com_deploy

# Add hosts that can use this agent
keycutter agent add-host work production-server
```

This ensures:
- Only specified keys are available to specified hosts
- Different security domains remain isolated
- Prevents key misuse across boundaries

### Hardware Key Benefits
- **Uncopiable** - Private keys never leave the YubiKey
- **Touch Required** - Physical presence verification for each use
- **PIN Protected** - Lockout after failed attempts
- **Device-Specific** - Each YubiKey needs its own keys

## File Organization

Keycutter organizes everything under `~/.ssh/keycutter/`:

```
~/.ssh/keycutter/
├── keycutter.conf      # Main configuration
├── agents/             # Agent forwarding profiles
│   ├── work/          # Work-related keys
│   └── personal/      # Personal keys
├── hosts/             # Host-specific configs
├── keys/              # SSH keys (keytag format)
│   ├── github.com_alex@yubikey1
│   └── github.com_alex@yubikey1.pub
└── scripts/           # Helper scripts
```

## Simplified Version Considerations

A minimal version of keycutter could focus on:

1. **Core keytag functionality** - The automatic hostname resolution
2. **Basic key creation** - Just `keycutter create <keytag>`
3. **Simple key deployment** - `keycutter push-keys <host>`
4. **Minimal configuration** - Auto-generated, no manual editing needed

Remove or simplify:
- Agent forwarding complexity
- Multiple update subcommands
- Service-specific integrations (make GitHub/SourceHut optional)
- Advanced configuration options

The essence is: **Create hardware-backed SSH keys with a naming convention that eliminates SSH config management.**