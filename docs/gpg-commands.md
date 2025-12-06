# GPG Commands Reference

Complete reference for Keycutter's GPG commands.

## Command Overview

```
keycutter gpg key list [--all]              # List GPG keys on YubiKey
keycutter gpg key create [options]          # Create master key + subkeys
keycutter gpg key install [options]         # Install subkeys to YubiKey
keycutter gpg setup [options]               # Configure host for GPG
keycutter gpg backup [options]              # Backup master key
```

## keycutter gpg key list

List GPG keys on the current YubiKey and optionally show available master keys from backup locations.

### Usage

```bash
keycutter gpg key list [--all]
```

### Options

| Option | Description |
|--------|-------------|
| `--all` | Also show master keys from registered backup locations |

### Examples

```bash
# List keys on current YubiKey
keycutter gpg key list

# Include master keys from backups
keycutter gpg key list --all
```

### Output

Displays:

- Key fingerprint
- Key capabilities (Sign, Encrypt, Auth, Certify)
- Creation date
- Expiration date (if set)
- User ID (name and email)

## keycutter gpg key create

Create a GPG master key with Sign, Encrypt, and Auth subkeys. Uses an ephemeral GNUPGHOME to ensure keys never touch disk unencrypted.

### Usage

```bash
keycutter gpg key create [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--identity ID` | User ID (e.g., "Name <email>") | Prompted |
| `--key-type TYPE` | Algorithm: `ed25519` or `rsa4096` | `ed25519` |
| `--expiration PERIOD` | Subkey expiration: `1y`, `2y`, etc. | `2y` |
| `--master-expiration P` | Master key expiration | `0` (never) |
| `--passphrase PASS` | Passphrase for key protection | Prompted |
| `--master-only` | Create only the Certify master key | Create all |
| `--subkeys` | Add subkeys to existing master | - |
| `--fingerprint FP` | Master key fingerprint (with `--subkeys`) | - |
| `--yes`, `-y` | Non-interactive mode (use config defaults) | Interactive |

### Examples

```bash
# Interactive creation with prompts
keycutter gpg key create

# Non-interactive with identity
keycutter gpg key create \
  --identity "Alice Developer <alice@example.com>" \
  --passphrase "secure-passphrase" \
  --yes

# Create with RSA keys (for older system compatibility)
keycutter gpg key create --key-type rsa4096

# Create only master key (add subkeys later)
keycutter gpg key create --master-only --identity "Alice <alice@example.com>"

# Add subkeys to existing master
keycutter gpg key create --subkeys --fingerprint ABC123...
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `GPG_IDENTITY` | Default identity |
| `GPG_KEY_TYPE` | Default key algorithm |
| `GPG_EXPIRATION` | Default subkey expiration |

## keycutter gpg key install

Install GPG subkeys from a master key backup to a YubiKey. This transfers the Sign, Encrypt, and Auth subkeys to the YubiKey's OpenPGP applet.

### Usage

```bash
keycutter gpg key install [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--backup FILE` | Path to encrypted backup | Prompted |
| `--backup-pass PASS` | Passphrase for backup decryption | Prompted |
| `--passphrase PASS` | Key passphrase for operations | Prompted |
| `--admin-pin PIN` | YubiKey admin PIN | `12345678` |
| `--force` | Overwrite existing keys on YubiKey | Prompt |
| `--yes`, `-y` | Non-interactive mode | Interactive |

### Examples

```bash
# Interactive installation
keycutter gpg key install

# Non-interactive from specific backup
keycutter gpg key install \
  --backup /path/to/backup.tar.gz.gpg \
  --backup-pass "backup-passphrase" \
  --passphrase "key-passphrase" \
  --admin-pin "12345678" \
  --yes
```

### Prerequisites

- YubiKey inserted with OpenPGP applet enabled
- pcscd service running (Linux)
- Master key backup available

### Notes

- Subkeys are **moved** to the YubiKey (not copied)
- After transfer, operations require the physical YubiKey
- Use `--force` to overwrite existing keys on the YubiKey

## keycutter gpg setup

Configure your host for GPG/YubiKey operation. Installs packages, configures gpg-agent, and sets up platform-specific requirements.

### Usage

```bash
keycutter gpg setup [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--enable-ssh` | Enable SSH support in gpg-agent |
| `--skip-packages` | Skip package installation |
| `--skip-config` | Skip GPG configuration |
| `--skip-launchagent` | Skip macOS LaunchAgent setup (macOS only) |
| `--skip-wsl-relay` | Skip WSL relay setup (WSL only) |
| `--yes`, `-y` | Non-interactive mode |

### Examples

```bash
# Full interactive setup
keycutter gpg setup

# Setup with SSH support
keycutter gpg setup --enable-ssh

# Skip package installation (use existing)
keycutter gpg setup --skip-packages
```

### Platform Support

| Platform | Packages Installed | Notes |
|----------|-------------------|-------|
| macOS | gnupg, pinentry-mac, ykman | Uses Homebrew, sets up LaunchAgent |
| Ubuntu/Debian | gnupg, pinentry-curses, ykman, pcscd | Enables pcscd service |
| Fedora/RHEL | gnupg2, pinentry-curses, ykpers, pcsc-lite | Enables pcscd service |
| WSL | socat, gpg | Configures relay to Windows GPG agent |

### Configuration Files

The setup configures:

- `~/.gnupg/gpg.conf` - GPG settings
- `~/.gnupg/gpg-agent.conf` - Agent settings (with optional SSH support)
- `~/.bashrc` / `~/.zshrc` - Shell configuration for GPG agent
- macOS: `~/Library/LaunchAgents/gpg-agent.plist` - LaunchAgent

## keycutter gpg backup

Create an encrypted backup of your GPG master key. The backup includes the master key, all subkeys, public key, and revocation certificate.

### Usage

```bash
keycutter gpg backup [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--fingerprint FP` | Key fingerprint to backup | Prompted |
| `--output-dir DIR` | Directory for backup file | Prompted |
| `--passphrase PASS` | Key passphrase for export | Prompted |
| `--backup-pass PASS` | Passphrase for backup encryption | Prompted |
| `--yes`, `-y` | Non-interactive mode | Interactive |

### Examples

```bash
# Interactive backup
keycutter gpg backup

# Non-interactive backup to specific location
keycutter gpg backup \
  --fingerprint ABC123... \
  --output-dir /mnt/secure-usb \
  --passphrase "key-passphrase" \
  --backup-pass "backup-passphrase" \
  --yes
```

### Backup Contents

The encrypted `.tar.gz.gpg` archive contains:

| File | Description |
|------|-------------|
| `master.key` | Master private key (armor format) |
| `subkeys.key` | All subkeys (armor format) |
| `public.key` | Public key (armor format) |
| `revoke.asc` | Revocation certificate |
| `README.md` | Restore instructions |

### Security Notes

- Use a strong, unique backup passphrase
- Store backups offline in secure locations
- Consider multiple backup copies in different locations
- Test backup restoration periodically

## See Also

- [GPG Quick Start](gpg-quickstart.md) - Getting started guide
- [GPG Configuration](gpg-configuration.md) - Customize defaults
- [GPG Security](gpg-security.md) - Best practices
- [GPG Troubleshooting](gpg-troubleshooting.md) - Common issues
