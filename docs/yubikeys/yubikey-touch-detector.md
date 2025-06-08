---
alias: YubiKey Touch Detector
---
# YubiKey Touch Detector

Get notified when YubiKey needs a touch.

![](../assets/yubikey-is-waiting-for-a-touch.png)

## Quick Install with Keycutter

The easiest way to install YubiKey touch detection is through keycutter:

```shell
keycutter install-touch-detector
```

This command will:
- Detect your operating system (Linux or macOS)
- Present appropriate installation options
- Handle all dependencies and configuration
- Set up the service to run automatically

## Platform Support

### Linux
- **yubikey-touch-detector** - The original tool by [maximbaz](https://github.com/maximbaz/yubikey-touch-detector)
- Supports package manager installation (Arch), pre-built binaries, or building from source
- Uses systemd for service management

### macOS
- **yknotify** - Lightweight tool by [noperator](https://github.com/noperator/yknotify) that monitors system logs
- **gpg-tap-notifier-macos** - Native Swift app by [palantir](https://github.com/palantir/gpg-tap-notifier-macos) with better GPG integration

## Manual Installation

### Linux (yubikey-touch-detector)

**Package Manager (Arch Linux):**
```shell
sudo pacman -S yubikey-touch-detector
```

**Build from Source:**
```shell
# Install dependencies
sudo apt-get install -y libgpgme-dev  # Ubuntu/Debian
# or
sudo dnf install -y gpgme-devel       # Fedora

# Install via Go
go install github.com/maximbaz/yubikey-touch-detector@latest

# Set up systemd service
systemctl --user daemon-reload
systemctl --user enable --now yubikey-touch-detector.service
```

### macOS (yknotify)

```shell
# Install dependencies
brew install go terminal-notifier

# Install yknotify
go install github.com/noperator/yknotify@latest

# Set up LaunchAgent (see yknotify README for details)
```

## Checking Status

After installation, you can check if the touch detector is running:

```shell
keycutter check-requirements
```

Or manually:
- **Linux:** `systemctl --user status yubikey-touch-detector`
- **macOS:** `launchctl list | grep yknotify`
