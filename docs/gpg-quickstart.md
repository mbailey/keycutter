# GPG Quick Start

This guide walks you through setting up GPG keys on a YubiKey using Keycutter.

## Prerequisites

- A YubiKey 4+ with OpenPGP support
- Keycutter installed (`keycutter --version`)
- A secure, offline environment for key creation (recommended)

## Overview

The GPG setup workflow:

1. **Create** - Generate master key + subkeys
2. **Backup** - Securely encrypt and store the master key
3. **Install** - Transfer subkeys to YubiKey
4. **Setup** - Configure your host for GPG/YubiKey

## Step 1: Configure Your Host

First, set up your system for GPG/YubiKey operation:

```bash
keycutter gpg setup
```

This installs required packages (gnupg, pinentry, ykman, pcscd) and configures gpg-agent. On macOS, it also sets up a LaunchAgent to keep gpg-agent running.

## Step 2: Create GPG Keys

Create a master key with Sign, Encrypt, and Auth subkeys:

```bash
keycutter gpg key create
```

You'll be prompted for:

- **Identity**: Your name and email (e.g., "Alice Developer <alice@example.com>")
- **Passphrase**: Strong passphrase to protect the key

The command creates:

- **Master key** (Certify only) - Used to manage your key identity
- **Sign subkey** - For signing commits, emails, and documents
- **Encrypt subkey** - For encrypting files and messages
- **Auth subkey** - For SSH authentication

## Step 3: Backup Your Master Key

**Critical**: Your master key is required to extend expiration dates and create new subkeys. Back it up securely:

```bash
keycutter gpg backup
```

This creates an encrypted archive containing:

- Master private key
- All subkeys
- Public key
- Revocation certificate

Store this backup in a secure, offline location (USB drive in a safe, encrypted cloud storage, etc.).

## Step 4: Install Subkeys to YubiKey

Transfer the subkeys to your YubiKey:

```bash
keycutter gpg key install
```

This moves the subkeys to your YubiKey's OpenPGP applet. After transfer:

- Subkeys exist only on the YubiKey (not on your computer)
- Operations require physical presence (touch the YubiKey)
- Keys cannot be extracted from the YubiKey

## Step 5: Test Your Setup

Verify the keys are on your YubiKey:

```bash
keycutter gpg key list
```

Test signing:

```bash
echo "test" | gpg --sign --armor
```

Your YubiKey will blink, waiting for you to touch it.

## Using GPG with SSH

If you enabled SSH support during setup (`--enable-ssh`), your Auth subkey can be used for SSH:

```bash
# Show your GPG-backed SSH public key
gpg --export-ssh-key YOUR_KEY_ID

# Add to authorized_keys or GitHub
```

## Next Steps

- [GPG Commands Reference](gpg-commands.md) - Full command documentation
- [GPG Configuration](gpg-configuration.md) - Customize settings
- [GPG Security](gpg-security.md) - Best practices
- [GPG Troubleshooting](gpg-troubleshooting.md) - Common issues

## Quick Reference

| Task | Command |
|------|---------|
| List keys | `keycutter gpg key list` |
| Create keys | `keycutter gpg key create` |
| Backup master | `keycutter gpg backup` |
| Install to YubiKey | `keycutter gpg key install` |
| Configure host | `keycutter gpg setup` |
