# GPG Configuration

Keycutter's GPG integration uses a layered configuration system that allows customization at multiple levels while providing secure defaults.

## Configuration Precedence

Configuration values are loaded in the following order (highest precedence first):

1. **CLI arguments** - Override everything
2. **Environment variables** - GPG_* and YUBIKEY_* prefixed
3. **User config file** - `~/.config/keycutter/gpg.conf`
4. **Default values** - Built-in secure defaults

## Configuration Files

### Default Values

Built-in defaults are defined in `config/gpg/defaults`:

```bash
# Key algorithm (ed25519 recommended for new keys)
GPG_KEY_TYPE="ed25519"

# Subkey expiration (master key never expires by default)
GPG_EXPIRATION="2y"
GPG_MASTER_EXPIRATION="0"

# Cipher preferences
GPG_CIPHER_PREFS="AES256 AES192 AES"
GPG_DIGEST_PREFS="SHA512 SHA384 SHA256"
```

### User Configuration

Create `~/.config/keycutter/gpg.conf` to customize your defaults:

```bash
# Use RSA keys for compatibility with older systems
GPG_KEY_TYPE="rsa4096"

# Set default identity
GPG_IDENTITY="Your Name <you@example.com>"

# Custom backup location
GPG_BACKUP_DIR="/path/to/secure/backup"
```

### GPG Configuration Template

The `config/gpg/gpg.conf` file contains hardened GPG settings based on the [drduh YubiKey Guide](https://github.com/drduh/YubiKey-Guide). This template is installed to GNUPGHOME by `keycutter gpg setup`.

Key security settings include:

- Strong cipher preferences (AES256, SHA512)
- Secure memory requirements
- Long key ID format
- Cross-certification enforcement

## Configuration Reference

### Key Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `GPG_KEY_TYPE` | `ed25519` | Key algorithm (`ed25519`, `rsa4096`) |
| `GPG_EXPIRATION` | `2y` | Subkey expiration period |
| `GPG_MASTER_EXPIRATION` | `0` | Master key expiration (0=never) |
| `GPG_IDENTITY` | (none) | Default identity for new keys |
| `GPG_COMMENT` | (none) | Comment to embed in keys |

### Cipher Preferences

| Variable | Default | Description |
|----------|---------|-------------|
| `GPG_CIPHER_PREFS` | `AES256 AES192 AES` | Symmetric cipher preferences |
| `GPG_DIGEST_PREFS` | `SHA512 SHA384 SHA256` | Hash algorithm preferences |
| `GPG_COMPRESS_PREFS` | `ZLIB BZIP2 ZIP Uncompressed` | Compression preferences |
| `GPG_CERT_DIGEST` | `SHA512` | Certificate digest algorithm |

### YubiKey Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `YUBIKEY_TOUCH_POLICY` | `on` | Touch policy (`on`, `off`, `cached`) |
| `YUBIKEY_PIN_RETRIES` | `3` | User PIN retry count |
| `YUBIKEY_ADMIN_PIN_RETRIES` | `3` | Admin PIN retry count |

### Backup Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `GPG_BACKUP_DIR` | (none) | Default backup destination |
| `GPG_BACKUP_FORMAT` | `gpg` | Backup format (`gpg`, `luks`) |
| `GPG_KEYSERVER` | `hkps://keys.openpgp.org` | Keyserver for publishing |

## Using Configuration

### Loading Configuration

The `gpg-config-load` function loads configuration with precedence handling:

```bash
source lib/gpg

# Load with defaults
gpg-config-load

# Load with CLI overrides
gpg-config-load GPG_KEY_TYPE=rsa4096 GPG_EXPIRATION=1y
```

### Getting Configuration Values

```bash
# Get a value (returns error if not set)
key_type=$(gpg-config-get GPG_KEY_TYPE)

# Get with default fallback
backup_dir=$(gpg-config-get GPG_BACKUP_DIR "/tmp/gpg-backup")
```

### Debugging Configuration

```bash
# Show all loaded configuration
gpg-config-load
gpg-config-dump
```

## Examples

### Create Key with Custom Settings

```bash
# Via environment variables
GPG_KEY_TYPE=rsa4096 GPG_EXPIRATION=1y keycutter gpg key create

# Via CLI arguments
keycutter gpg key create --key-type rsa4096 --expiration 1y
```

### Non-Interactive Key Creation

Set configuration in `~/.config/keycutter/gpg.conf`:

```bash
GPG_IDENTITY="Alice Developer <alice@example.com>"
GPG_KEY_TYPE="ed25519"
GPG_EXPIRATION="2y"
```

Then create without prompts:

```bash
keycutter gpg key create --yes
```

## See Also

- [GPG Quick Start](gpg-quickstart.md) - Getting started guide
- [YubiKey Setup](yubikeys/README.md) - YubiKey configuration
- [drduh Guide](https://github.com/drduh/YubiKey-Guide) - Comprehensive YubiKey GPG guide
