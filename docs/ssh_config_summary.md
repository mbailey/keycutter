# SSH_CONFIG(5) Summary

## Overview
The `ssh_config` file contains configuration data for the OpenSSH SSH client. Configuration is loaded in priority order from:
1. Command-line options
2. User config: `~/.ssh/config`
3. System config: `/etc/ssh/ssh_config`

First obtained value for each parameter is used, so host-specific configurations should appear before general defaults.

## File Format
- Keyword-argument pairs, one per line
- Comments: lines starting with `#` or empty lines
- Arguments in quotes if containing spaces
- Keywords are case-insensitive, arguments are case-sensitive
- Can use `=` separator: `keyword=value` or `keyword value`

## Key Structural Elements

### Host Blocks
```
Host pattern
    # Config options for matching hosts
```
- Patterns support wildcards (`*`, `?`)
- Negation with `!` prefix
- Multiple patterns separated by whitespace

### Match Blocks
Conditional configuration based on criteria:
- `canonical`, `final`, `exec`, `localnetwork`
- `host`, `originalhost`, `tagged`, `user`, `localuser`

## Essential Keywords

### Connection
- **Hostname** - Real hostname to connect to
- **Port** - Port number (default: 22)
- **User** - Username to log in as
- **ProxyJump** - Jump hosts for connection
- **ProxyCommand** - Custom connection command

### Authentication
- **IdentityFile** - SSH key files (default: `~/.ssh/id_*`)
- **IdentitiesOnly** - Only use specified keys (yes/no)
- **PubkeyAuthentication** - Use public key auth (yes/no)
- **PasswordAuthentication** - Use password auth (yes/no)
- **PreferredAuthentications** - Auth method order

### Host Keys
- **UserKnownHostsFile** - Known hosts files
- **StrictHostKeyChecking** - Host key verification (yes/no/ask/accept-new)
- **HostKeyAlias** - Alias for host key lookup
- **UpdateHostKeys** - Accept new host keys from server

### Forwarding
- **LocalForward** - Forward local port to remote
- **RemoteForward** - Forward remote port to local
- **DynamicForward** - SOCKS proxy
- **ForwardAgent** - Forward SSH agent (yes/no/path)
- **ForwardX11** - Forward X11 (yes/no)

### Connection Management
- **ControlMaster** - Connection multiplexing (yes/no/ask/auto)
- **ControlPath** - Socket for multiplexed connections
- **ControlPersist** - Keep master connection alive
- **ServerAliveInterval** - Keepalive interval
- **ServerAliveCountMax** - Max keepalive failures

### Include Files
- **Include** - Include other config files
- Supports globs, tokens, env variables
- Can be used inside Host/Match blocks

## Patterns
- `*` - Match zero or more characters
- `?` - Match exactly one character
- `!` - Negate pattern (must have positive match too)
- Pattern lists are comma-separated

## Tokens
Runtime variable expansion in many keywords:
- `%%` - Literal %
- `%h` - Remote hostname
- `%p` - Remote port
- `%r` - Remote username
- `%u` - Local username
- `%d` - Local home directory
- `%C` - Hash of connection info
- `%n` - Original hostname from command line

## Environment Variables
- `${VAR}` syntax for environment variable expansion
- Supported in: CertificateFile, ControlPath, IdentityAgent, IdentityFile, Include, KnownHostsCommand, UserKnownHostsFile
- LocalForward/RemoteForward support env vars for Unix sockets only

## Common Use Cases

### Multi-account/Multi-key Setup
```
Host github.com-work
    Hostname github.com
    User git
    IdentityFile ~/.ssh/work_key

Host github.com-personal
    Hostname github.com
    User git
    IdentityFile ~/.ssh/personal_key
```

### Jump Host Configuration
```
Host target
    ProxyJump jumphost
    # Or: ProxyCommand ssh jumphost -W %h:%p
```

### Connection Multiplexing
```
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%C
    ControlPersist 10m
```

### Conditional Configuration
```
Match host *.internal.com
    ProxyJump bastion.internal.com

Match user root
    PasswordAuthentication no
```

## Best Practices
1. Put host-specific configs before wildcards
2. Use `Host *` at the end for defaults
3. Set `StrictHostKeyChecking` appropriately for security
4. Use `IdentitiesOnly yes` to prevent agent key sprawl
5. Enable `ControlMaster` for frequently accessed hosts
6. Use tokens and env vars for flexible configs
7. Organize with Include files for complex setups