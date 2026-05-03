---
name: keycutter
description: SSH key management with FIDO2/YubiKey. Use for key setup, YubiKeys, agents, or SSH troubleshooting.
---

# Keycutter

SSH key management tool for FIDO2/YubiKey support and multi-account SSH access.

**Install:** `curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash`

## Quick Reference

| Command | Purpose |
|---------|---------|
| `keycutter create <keytag>` | Create SSH key (`--resident` for portable) |
| `keycutter keys` | List all keys |
| `keycutter agents` | List agent profiles |
| `keycutter hosts` | List configured hosts |
| `keycutter config <host>` | Show SSH config for host |
| `keycutter push-keys <host>` | Push public keys to host |
| `keycutter update` | Update everything |
| `keycutter git-signing enable` | Enable SSH commit signing |

**YubiKey essentials:**
| `ykman config usb --disable OTP` | CRITICAL: Prevent "yubisneeze" (accidental OTP paste) |
| `ykman fido access change-pin` | Set FIDO2 PIN |

## Key Concepts

- **SSH Keytags:** `<service>_<identity>@<device>` — e.g. `github.com_alex@yubikey1`. Enables `git clone git@github.com_alex:owner/repo.git` without custom SSH Host entries.
- **Agents:** Security boundaries at `~/.ssh/keycutter/agents/` controlling which keys forward to which hosts.
- **Config:** `~/.ssh/keycutter/` with `keycutter.conf`, `agents/`, `hosts/`, `keys/`, `scripts/`.

## Quick Setup (YubiKey + GitHub)

```bash
ykman config usb --disable OTP            # 1. Disable OTP
ykman fido access change-pin              # 2. Set FIDO2 PIN
# install keycutter (see above)
export KEYCUTTER_ORIGIN=yubikey1          # 3. Name your device
keycutter create github.com_youruser      # 4. Create key
ssh -T github.com_youruser               # 5. Test it
```

## Documentation

- [Tutorial](../../../docs/tutorial.md) — Step-by-step workflows
- [SSH Keytags](../../../docs/ssh-keytags.md) — Naming convention details
- [Configuration](../../../docs/config/README.md) — Config structure
- [YubiKey Manager](../../../docs/yubikeys/ykman-yubikey-manager.md) — ykman install and commands
- [FIDO2 on YubiKeys](../../../docs/yubikeys/fido2-on-yubikeys.md) — PINs and credentials
- [Troubleshooting](../../../docs/troubleshooting.md) — Debugging SSH issues
- [Tips and Tricks](../../../docs/tips-and-tricks.md) — Advanced usage
- [Development](../../../docs/development.md) — Contributing to keycutter
