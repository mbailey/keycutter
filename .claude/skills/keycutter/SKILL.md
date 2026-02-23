---
name: keycutter
description: SSH key management with FIDO2/YubiKey, keytags, agents, and multi-account SSH access.
version: 1.0.0
---

# Keycutter

SSH key management tool focused on FIDO2/YubiKey support and multi-account SSH access.

**Repository:** github.com/mbailey/keycutter
**Install:** `curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash`

## Quick Reference

| Command | Purpose |
|---------|---------|
| `keycutter create <keytag>` | Create SSH key (add `--resident` for portable) |
| `keycutter keys` | List all keys |
| `keycutter agents` | List agent profiles |
| `keycutter hosts` | List configured hosts |
| `keycutter config <host>` | Show SSH config for host |
| `keycutter update` | Update everything |
| `keycutter check-requirements` | Check prerequisites |

## Core Concepts

### SSH Keytags

Naming convention: `<service>_<identity>@<device>` (e.g. `github.com_alex@yubikey1`)

Enables multi-account SSH without custom Host entries:
```bash
git clone git@github.com_alex:owner/repo.git       # as @alex
git clone git@github.com_work:owner/repo.git        # as @work
```

### Agents (Security Boundaries)

Agent profiles at `~/.ssh/keycutter/agents/` control which keys are forwarded to which hosts via `IdentityAgent` in SSH config.

### Configuration Structure

```
~/.ssh/keycutter/
  keycutter.conf        # Main config (included by ~/.ssh/config)
  agents/               # Agent profiles
  hosts/                # Host-specific SSH config
  keys/                 # SSH keys (keytag naming)
  scripts/              # Helper scripts (ssh-agent-ensure)
```

## Detailed Guides

For detailed instructions, see the reference files:

- [YubiKey Setup](references/yubikey-setup.md) — OTP disable (yubisneeze prevention), PIN setup, ykman commands
- [Command Reference](references/commands.md) — Full command reference for agents, hosts, keys, git-signing
- [Troubleshooting](references/troubleshooting.md) — Common issues and debugging
