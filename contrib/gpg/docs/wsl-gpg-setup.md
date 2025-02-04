# Setting up YubiKey GPG in Windows Subsystem for Linux (WSL)

Formatted with claude-3-5-sonnet

This guide explains how to use your YubiKey with GPG in WSL by relaying GPG agent communications between Windows and Linux.

## Prerequisites

- Windows 10/11 with WSL2 installed
- YubiKey configured with GPG keys
- WSL Ubuntu/Debian environment

## Quick Setup

Run the automated setup script:

```bash
./bin/gpg-wsl-setup
```

This will:
1. Install required packages (socat, gpg)
2. Install GPG4Win on Windows if needed
3. Download and configure npiperelay
4. Set up the GPG relay service
5. Configure your shell to start the relay automatically

After running the script, start a new terminal session or source your shell config file.

## Manual Installation Steps

### 1. Windows Setup

1. Install GPG4Win on Windows if not already installed
   ```powershell
   winget install GnuPG.Gpg4win
   ```

2. Download npiperelay
   - Get the latest release from https://github.com/benpye/wsl-ssh-pageant/releases
   - Download the `wsl-ssh-pageant-amd64-gui.exe` file
   - Rename it to `npiperelay.exe`
   - Place it in your Windows user profile at `%USERPROFILE%\WSL\npiperelay.exe`

### 2. WSL Setup

1. Install required packages:
   ```bash
   sudo apt update
   sudo apt install -y socat gpg gpg-agent
   ```

2. Disable systemd GPG agent socket activation:
   ```bash
   systemctl --user mask --now gpg-agent-browser.socket
   systemctl --user mask --now gpg-agent-extra.socket
   systemctl --user mask --now gpg-agent-ssh.socket
   systemctl --user mask --now gpg-agent.socket
   ```

### 3. Configure GPG Relay

1. Add the GPG relay function to your shell configuration (e.g. `~/.bashrc` or `~/.zshrc`):
   ```bash
   # Source the GPG relay script
   source ~/.config/gpg/gpg-relay
   ```

2. Create the GPG relay configuration directory:
   ```bash
   mkdir -p ~/.config/gpg
   ```

3. Copy the GPG relay script:
   ```bash
   cp /path/to/shell/gpg-relay ~/.config/gpg/
   ```


### 4. Usage

1. Start a new WSL session or source your shell configuration:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

2. The GPG relay will start automatically. You can verify it's working with:
   ```bash
   gpg --card-status
   ```

## Troubleshooting

### Common Issues

1. **GPG agent connection errors**
   - Verify Windows GPG agent is running
   - Check socket paths match between Windows and WSL
   - Restart the relay with `gpg-relay`

2. **YubiKey not detected**
   - Ensure YubiKey is recognized in Windows
   - Try unplugging and reinserting the YubiKey
   - Run `gpg --card-status` to verify connection

3. **Socket in use errors**
   - Check for existing GPG agent processes
   - Remove stale socket files
   - Ensure systemd sockets are masked

### Debugging

To get more detailed output:

```bash
# Check Windows GPG agent status
check_windows_gpg_agent

# Restart Windows GPG agent
restart_windows_gpg_agent

# View socket locations
ls -l ~/.gnupg/S.gpg-agent*
ls -l /run/user/$UID/gnupg/S.gpg-agent*
```

## Notes

- The relay setup only needs to be done once per WSL installation
- The relay will automatically start with your shell
- YubiKey operations in WSL will use the Windows GPG agent
- This setup supports both GPG operations and SSH authentication through GPG

## References

- [npiperelay GitHub repository](https://github.com/jstarks/npiperelay)
- [GnuPG documentation](https://www.gnupg.org/documentation/)
- [YubiKey GPG setup guide](../README.md)
