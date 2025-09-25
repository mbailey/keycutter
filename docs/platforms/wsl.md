# WSL (Windows Subsystem for Linux) Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [SSH Configuration](#ssh-configuration)
5. [Known Issues and Workarounds](#known-issues-and-workarounds)
6. [YubiKey Integration](#yubikey-integration)
7. [Troubleshooting](#troubleshooting)

## Overview

This guide covers using Keycutter within Windows Subsystem for Linux (WSL). WSL allows you to run Linux tools on Windows, but requires special configuration for hardware security key access.

### WSL1 vs WSL2
- **WSL2** (recommended): Better performance, full Linux kernel, but requires ssh-sk-helper.exe for FIDO2 keys
- **WSL1**: Direct hardware access but limited compatibility

## Prerequisites

### Required Software
- **Windows**: Windows 10 version 1903+ or Windows 11
- **OpenSSH for Windows**: Version >= 8.9p1-1
  - Windows 11: Usually included in `C:\Windows\System32\OpenSSH\`
  - Windows 10: Download from [PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/releases)
- **WSL**: Ubuntu 20.04+ or equivalent distribution

### WSL Requirements
```bash
# Install in WSL
sudo apt update
sudo apt install openssh-client git netcat
```

## Initial Setup

### Step 1: Locate ssh-sk-helper.exe

Check these common locations:
```bash
# Windows 11 default location
ls -la /mnt/c/Windows/System32/OpenSSH/ssh-sk-helper.exe

# Manual install location
ls -la "/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"
```

### Step 2: Configure SSH_SK_HELPER

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# WSL SSH FIDO2 Configuration
# Check common locations for ssh-sk-helper.exe
if [[ -f "/mnt/c/Windows/System32/OpenSSH/ssh-sk-helper.exe" ]]; then
    export SSH_SK_HELPER="/mnt/c/Windows/System32/OpenSSH/ssh-sk-helper.exe"
elif [[ -f "/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe" ]]; then
    export SSH_SK_HELPER="/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"
fi

# Alternative: If ssh-sk-helper.exe is in Windows PATH
# if command -v ssh-sk-helper.exe >/dev/null 2>&1; then
#     export SSH_SK_HELPER="ssh-sk-helper.exe"
# fi
```

### Step 3: Verify Configuration

```bash
# Reload shell profile
source ~/.bashrc

# Check if SSH_SK_HELPER is set
echo $SSH_SK_HELPER

# Test FIDO2 key detection
ssh-keygen -t ed25519-sk -C "test@example.com"
# Should prompt for YubiKey touch
```

## SSH Configuration

### Key Storage
- WSL SSH keys: `~/.ssh/` (inside WSL filesystem)
- Keycutter keys: `~/.ssh/keycutter/keys/`
- Windows SSH keys: `/mnt/c/Users/[username]/.ssh/` (accessible from WSL)

### Agent Configuration
WSL and Windows maintain separate SSH agents. For keycutter:
```bash
# Use WSL SSH agent for Linux operations
eval $(ssh-agent)

# Keys requiring Windows authentication use ssh-sk-helper.exe
```

## Known Issues and Workarounds

### Windows 11: Windows Hello Passkey Prompt

**Issue**: When using FIDO2 SSH keys, Windows 11 shows a "Sign in with your passkey" dialog requiring you to:
1. Select "Security Key" from options (iPhone/iPad/Android device also shown)
2. Click Next
3. Then touch your security key

**Status**: This is a Windows 11 design decision that bundles Windows Hello with FIDO2 authentication. Currently, there's no way to disable this prompt.

**Workarounds**:
1. Accept the extra clicks as part of the security flow
2. Consider [openssh-sk-winhello](https://github.com/tavrez/openssh-sk-winhello) - alternative helper that may reduce prompts
3. Use SSH agent forwarding to minimize authentication frequency

### File Permission Issues

WSL may have different permission handling than Linux:
```bash
# Fix SSH key permissions
chmod 600 ~/.ssh/keycutter/keys/*
chmod 644 ~/.ssh/keycutter/keys/*.pub
```

### YubiKey Not Detected

If your YubiKey isn't detected:
1. Ensure Windows recognizes the device (check Device Manager)
2. Verify ssh-sk-helper.exe is correctly configured
3. Try unplugging and reinserting the YubiKey
4. Check Windows Security settings aren't blocking FIDO2 access

## YubiKey Integration

### Direct Access (Advanced)
For direct YubiKey access in WSL2, you can use USBIPD-WIN:
```bash
# Windows side (PowerShell as Administrator)
winget install usbipd

# List USB devices
usbipd list

# Attach YubiKey to WSL
usbipd attach --wsl --busid <BUSID>
```

**Note**: This is complex and usually unnecessary if ssh-sk-helper.exe is working.

### YubiKey Manager
- Use Windows GUI version for configuration
- CLI version (`ykman`) works in WSL with USBIPD-WIN
- Most users should configure YubiKey from Windows side

## Troubleshooting

### Common Problems and Solutions

#### "ssh-sk-helper.exe: not found"
```bash
# Verify the file exists
ls -la "$SSH_SK_HELPER"

# Check if path needs quotes (spaces in path)
export SSH_SK_HELPER="/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"
```

#### "Permission denied" when accessing YubiKey
- Run WSL terminal as Administrator (once to test)
- Check Windows Defender or antivirus isn't blocking
- Verify OpenSSH for Windows is properly installed

#### "No authenticator found" error
```bash
# Test if Windows can see the YubiKey
/mnt/c/Windows/System32/OpenSSH/ssh-keygen.exe -t ed25519-sk

# If this works but WSL doesn't, check SSH_SK_HELPER export
```

### Debug Commands
```bash
# Verbose SSH for debugging
ssh -vvv user@host

# Check SSH agent
ssh-add -l

# Test FIDO2 key generation
ssh-keygen -vvv -t ed25519-sk

# Verify environment
env | grep SSH_SK_HELPER
```

### Getting Help
1. Check keycutter logs: `keycutter --debug [command]`
2. Review Windows Event Viewer for ssh-sk-helper.exe errors
3. WSL logs: `dmesg | tail -20`
4. Report issues: [Keycutter GitHub Issues](https://github.com/mbailey/keycutter/issues)

## Additional Resources
- [Microsoft WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [OpenSSH for Windows Releases](https://github.com/PowerShell/Win32-OpenSSH/releases)
- [Keycutter Troubleshooting Guide](../troubleshooting.md)
- [YubiKey SSH Documentation](https://developers.yubico.com/SSH/)