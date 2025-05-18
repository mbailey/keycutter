# Keycutter Configuration

Keycutter's SSH configuration is designed to be modular and easy to understand. All configuration files are organized under `~/.ssh/keycutter/` to keep your main SSH directory clean.

## Configuration Structure

```
~/.ssh/keycutter/
├── agents/                # Agent-specific configurations
├── hosts/                 # Host-specific configurations
├── keys/                  # SSH keys and keytags
├── keycutter.conf         # Main keycutter configuration
└── scripts/               # Helper scripts
```

## Configuration Components

### [Agents](../../ssh_config/keycutter/agents/README.md)

Manage SSH agent forwarding configurations.

- Control which keys are forwarded to specific hosts
- Enforce security boundaries between different environments
- Separate work and personal SSH keys

### [Hosts](../../ssh_config/keycutter/hosts/README.md)

Define host-specific SSH settings.

- Group hosts by profile (personal, work, etc.)
- Set custom forwarding rules per host
- Configure host-specific identity files

### [Keys](../../ssh_config/keycutter/keys/README.md)

Store SSH keys following the SSH Keytag naming convention.

This directory contains:

- FIDO SSH private and public key pairs
- Symbolic links for service aliases
- Keys organized by the keytag format: `<service>_<identity>@<device>`

## Main Configuration File

The `keycutter.conf` file is the main configuration that:

- Includes host-specific configurations
- Sets up the SSH proxy command for keycutter
- Defines global SSH settings for keycutter-managed connections

## How It Works

1. Your main `~/.ssh/config` includes `keycutter/keycutter.conf`
2. `keycutter.conf` includes configurations from the `hosts/` directory
3. Host configurations reference keys from the `keys/` directory
4. Agent configurations control which keys are forwarded

This modular approach makes it easy to:

- Add new hosts without modifying global config
- Manage keys across multiple devices
- Maintain separation between different security contexts

## See Also

- [SSH Keytags](../ssh-keytags.md) - Understanding the keytag naming convention
- [Tutorial](../tutorial.md) - Step-by-step usage examples
- [Defense Layers](../design/defense-layers-to-protect-against-key-misuse.md) - Security design principles

