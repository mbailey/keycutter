# YubiKey Setup

## CRITICAL: Disable OTP to Prevent "Yubisneeze"

YubiKey Nano/5C Nano sit flush in USB ports and get accidentally touched, pasting OTP codes into whatever has focus. **Disable OTP first:**

```bash
ykman config usb --disable OTP
```

This only disables OTP over USB. FIDO2 and all other interfaces remain active.

## Install YubiKey Manager

**macOS:**
1. Download the official package from yubico.com/support/download/yubikey-manager/
2. Add to PATH: `export PATH="$PATH:/Applications/YubiKey Manager.app/Contents/MacOS"`

Note: Do not use `brew install` for ykman — Homebrew installs an outdated GUI-only version.

**Linux (Fedora):** `sudo dnf install yubikey-manager`
**Linux (Ubuntu):** Use Yubico PPA:
```bash
sudo add-apt-repository ppa:yubico/stable && sudo apt-get update
sudo apt install yubikey-manager
```

## Set FIDO2 PIN

A PIN protects credentials if the YubiKey is lost. Required for resident keys.

```bash
ykman fido info                    # Check PIN status
ykman fido access change-pin       # Set or change PIN
```

PIN rules: 4-63 chars, 8 attempts before lockout (requires FIDO2 reset).

## Useful ykman Commands

```bash
ykman info                         # Device info, serial, firmware
ykman fido info                    # FIDO2 PIN status
ykman fido credentials list        # List resident credentials
ykman fido credentials delete      # Delete a credential
ykman config usb --disable OTP     # Disable OTP (prevent yubisneeze)
```

## Creating Keys

### Create a FIDO SSH Key

```bash
keycutter create github.com_alex
```

This will:
1. Prompt to append `@<device>` to the keytag (using KEYCUTTER_ORIGIN or hostname)
2. Generate an ed25519-sk key at `~/.ssh/keycutter/keys/<keytag>`
3. For GitHub keys: offer to upload via `gh` CLI and create ssh.github.com symlink

**Options:**
- `--resident` — Store key on YubiKey (discoverable credential, portable across machines)
- `--type <type>` — Key type: `ed25519-sk` (default), `ecdsa-sk`, `ed25519`, `ecdsa`, `rsa`

### Set Device Name

```bash
export KEYCUTTER_ORIGIN=yubikey1    # Name for this device
keycutter create github.com_alex    # Creates github.com_alex@yubikey1
```

### Resident vs Non-Resident Keys

- **Non-resident (default):** Key handle stored on disk, YubiKey signs. Needs the key file present.
- **Resident (`--resident`):** Full credential stored on YubiKey. Works on any machine with `ssh-keygen -K` to extract.

## Quick Setup Walkthrough

For someone setting up keycutter with a YubiKey for the first time:

```bash
# 1. Disable OTP on YubiKey (prevents accidental OTP paste)
ykman config usb --disable OTP

# 2. Set FIDO2 PIN
ykman fido access change-pin

# 3. Install keycutter
curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash

# 4. Set your device name
export KEYCUTTER_ORIGIN=yubikey1  # or laptop, homepc, etc.

# 5. Create a key for GitHub
keycutter create github.com_yourusername

# 6. Test it
ssh -T github.com_yourusername

# 7. Clone a repo using your identity
git clone git@github.com_yourusername:owner/repo.git
```
