# Keycutter Detailed Specification

## Overview

This specification defines the complete functionality of keycutter for potential reimplementation with a focus on simplicity and test-driven development.

## Core Concepts

### 1. SSH Keytags
**Purpose**: Eliminate manual SSH configuration through a naming convention.

**Format**: `<context>@<device>`
- Context can be:
  - Service-specific: `github.com_username`
  - Zone-based: `personal`, `work`, `private`
- Device: Typically the YubiKey identifier (e.g., `yubikey1`)

**Examples**:
- `github.com_alice@yubikey1` - Service-specific key
- `personal@yubikey1` - Zone key for all personal hosts
- `work@laptop` - Zone key for work hosts

### 2. Zone-Based Security Model
Three primary security zones with automatic key selection:

1. **Personal Zone** (`personal@device`)
   - Personal projects, home servers, personal cloud accounts
   - Isolated from work environments
   
2. **Work Zone** (`work@device`)  
   - Company resources, work repositories, corporate servers
   - Separate agent forwarding profile
   
3. **Private Zone** (`private@device`)
   - Highest security contexts
   - Minimal or no agent forwarding

### 3. Automatic SSH Routing
Keytags enable zero-config multi-account access:
```bash
# Service-specific routing
ssh github.com_personal
ssh github.com_work

# Zone-based routing (with host tagging)
ssh homeserver  # Uses personal@device if tagged 'personal'
```

## Current Command Interface

### Primary Commands
```bash
keycutter create <keytag> [--resident] [--type <type>]
keycutter authorized-keys <hostname>
keycutter push-keys <hostname>
keycutter check-requirements
keycutter config <hostname>
keycutter agents
keycutter hosts
keycutter keys
keycutter update [git|config|requirements|touch-detector]
```

### Agent Management Subcommands
```bash
keycutter agent add-key <agent> <key>
keycutter agent add-host <agent> <host>
keycutter agent remove-key <agent> <key>
keycutter agent remove-host <agent> <host>
```

### Host Management Subcommands
```bash
keycutter hosts
keycutter hosts edit <filename>
```

## Simplified Command Interface Proposal

### Core Commands Only
```bash
# Key Management
keycutter create <keytag>        # Create FIDO SSH key
keycutter list                   # List all keys
keycutter push <hostname>        # Deploy keys to host

# Configuration
keycutter setup                  # Initial setup/check requirements
keycutter update                 # Update keycutter

# Optional/Advanced
keycutter config <hostname>      # Show effective config
keycutter agent <agent> <action> # Manage agent profiles
```

### Setup Workflow
```bash
# 1. Initial setup
keycutter setup
# - Checks requirements
# - Creates ~/.ssh/keycutter/ structure
# - Adds Include to ~/.ssh/config

# 2. Create zone keys
keycutter create personal@yubikey1
keycutter create work@yubikey1

# 3. Create service keys as needed
keycutter create github.com_personal@yubikey1
keycutter create github.com_work@yubikey1

# 4. Tag hosts in ~/.ssh/keycutter/hosts/zones.conf
# Host *.home.lan 192.168.1.*
#   Tag personal
#
# Host *.company.com
#   Tag work

# 5. Push keys to hosts
keycutter push myserver.home.lan
```

## SSH Configuration Generation

### Directory Structure
```
~/.ssh/keycutter/
├── keycutter.conf          # Main config with Match rules
├── agents/                 # Agent profiles
│   ├── personal/          
│   │   └── ssh-agent.socket
│   └── work/
│       └── ssh-agent.socket
├── hosts/                  # Host configurations
│   ├── personal.conf       # Zone config for personal
│   ├── work.conf          # Zone config for work
│   └── zones.conf         # User's host tagging
├── keys/                   # SSH keys
│   ├── personal@yubikey1
│   ├── personal@yubikey1.pub
│   ├── github.com_alice@yubikey1
│   └── github.com_alice@yubikey1.pub
└── scripts/               # Helper scripts
```

### Key SSH Config Components

#### 1. Main SSH Config Include
```bash
# ~/.ssh/config
Include ~/.ssh/keycutter/keycutter.conf
```

#### 2. Keytag Hostname Resolution (keycutter.conf)
```ssh
# Resolve service_username hostnames to actual hosts
Match host *_*
  Hostname %n
  ProxyCommand bash -c 'ssh_keytag_proxy_command=1 exec /usr/bin/ssh ${SSH_KEYTAG_PROXY_HOST:="$(sed "s/_[^_]*$//" <<< "%n")"} ${SSH_KEYTAG_PROXY_OPTIONS} %p'
```

#### 3. Zone-Based Key Selection (e.g., personal.conf)
```ssh
# Apply personal key to hosts tagged 'personal'
Match final tagged personal exec "bash -c '[[ -e ~/.ssh/keycutter/keys/personal@${KEYCUTTER_ORIGIN} ]]'"
  IdentityFile ~/.ssh/keycutter/keys/personal@${KEYCUTTER_ORIGIN}
  IdentityAgent ~/.ssh/keycutter/agents/personal/ssh-agent.socket
```

#### 4. Service-Specific Key Selection
```ssh
# Use specific key for github.com_username pattern
Match final host github.com_*
  IdentityFile ~/.ssh/keycutter/keys/%n@${KEYCUTTER_ORIGIN}
```

### Agent Forwarding Security

Each zone has its own agent profile:
1. Keys are symlinked into agent directories
2. ProxyCommand loads only those keys for the connection
3. Remote hosts can only access keys in their zone's agent

## Core Functionality for Reimplementation

### 1. Key Creation
- Generate FIDO2 SSH key using ssh-keygen
- Support resident and non-resident keys
- Store in keytag naming format
- Optionally upload to services (GitHub, SourceHut)

### 2. SSH Config Management
- Generate includes for ~/.ssh/config
- Create Match rules for keytag routing
- Implement zone-based tagging system
- Handle agent forwarding profiles

### 3. Key Deployment
- Extract authorized keys based on SSH config
- Deploy using ssh-copy-id with fallback auth
- Handle RemoteCommand edge cases

### 4. Security Zones
- Implement tag-based host matching
- Separate agent profiles per zone
- Automatic key selection based on zone

## Test Scenarios

### Basic Functionality
1. Create key with standard keytag
2. Verify SSH routing to correct host
3. Test multi-account access to same service
4. Verify key deployment to remote host

### Zone-Based Security
1. Create zone keys (personal, work)
2. Tag hosts in configuration
3. Verify correct key selection
4. Test agent forwarding isolation

### Edge Cases
1. Missing KEYCUTTER_ORIGIN variable
2. Non-existent keys referenced in config
3. Password-protected remote hosts
4. Existing authorized_keys preservation

### Security Tests
1. Verify agent isolation between zones
2. Test key visibility restrictions
3. Validate ProxyCommand security
4. Check for key leakage scenarios

## Installation Strategy

### Option 1: Self-Contained Clone
```bash
git clone https://github.com/mbailey/keycutter ~/.ssh/keycutter-app
~/.ssh/keycutter-app/install.sh
```

Benefits:
- Single directory contains everything
- Easy updates via git pull
- Can rename/move without breaking

### Option 2: Separate Binary and Config
```bash
# Install binary
curl -L https://github.com/mbailey/keycutter/releases/latest/keycutter > /usr/local/bin/keycutter

# Binary creates config on first run
keycutter setup
```

Benefits:
- Cleaner separation of code and data
- Easier distribution
- Standard Unix pattern

## Implementation Priorities

1. **Core keytag routing** - The magic that makes it work
2. **Zone-based keys** - Simplified security model
3. **Basic commands** - create, list, push
4. **SSH config generation** - Automated setup
5. **Agent forwarding** - Security boundaries
6. **Service integrations** - GitHub, etc. (optional)

## Future Considerations

### GPG Integration Options

1. **Unified Tool** (`keycutter ssh` / `keycutter gpg`)
   - Shared YubiKey management code
   - Consistent zone concept
   - Single tool to learn

2. **Separate Tools** (`keycutter` / `keycrypt`)
   - Focused functionality
   - Independent development
   - Clearer purpose

3. **Plugin Architecture**
   - Core YubiKey library
   - SSH and GPG as plugins
   - Extensible for other uses