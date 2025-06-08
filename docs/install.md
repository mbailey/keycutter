# Installation Guide

## Prerequisites

The Keycutter installer checks requirements automatically, but here's what you'll need:

### Required

- **Bash >= 4.0**
- **Git >= 2.34.0**
- **OpenSSH >= 8.2p1**
  - **WSL** Users need `ssh-sk-helper` ([OpenSSH for Windows >= 8.9p1-1](https://github.com/PowerShell/Win32-OpenSSH/releases))
  - **macOS** Bundled OpenSSH is broken. Update with `brew install openssh` and reload terminal
- **nc** (netcat)

### Recommended

- **GitHub CLI >= 2.0** (Greater than 2.4.0+dfsg1-2 on Ubuntu)
- **YubiKey Touch Detector:** Get notified when YubiKey needs a touch (install with `keycutter install-touch-detector`)
- **YubiKey Manager (`ykman`):** Used to set a PIN on YubiKeys and perform other configuration

## Installation Methods

### Quick Install (Recommended)

```shell
curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash
```

### Manual Install

Clone the Git repo and run the installer:

```shell
git clone https://github.com/mbailey/keycutter
cd keycutter
./install.sh
```

## Platform-Specific Configuration

### WSL (Windows Subsystem for Linux)

Add this to your shell profile (e.g. bashrc or zshrc):

```shell
# WSL users need to set the path to ssh-sk-helper.exe
if [[ -f "/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe" ]]; then
    export SSH_SK_HELPER="/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"
fi
```

### macOS

The built-in OpenSSH on macOS doesn't support FIDO keys properly. Install the latest version:

```shell
brew install openssh
```

After installation, close and reopen your terminal for the changes to take effect.

## Verifying Installation

After installation, verify everything is working:

```shell
keycutter --help
```

You should see the Keycutter help menu displaying available commands.

## Troubleshooting

If you encounter issues during installation:

1. Check that all prerequisites are installed
2. Ensure you have the latest version of OpenSSH
3. For WSL users, verify that ssh-sk-helper.exe is properly configured
4. See the [Troubleshooting Guide](troubleshooting.md) for common issues

## Next Steps

- Read the [Tutorial](tutorial.md) to learn how to use Keycutter
- Create your first FIDO SSH key with `keycutter create`
- Install YubiKey touch notifications with `keycutter install-touch-detector`
- Explore the [Configuration Guide](config/README.md) to understand how Keycutter organizes SSH configuration