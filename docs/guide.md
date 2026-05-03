# Keycutter How-To Guide

A practical guide to using Keycutter for SSH key management and authentication.

## Getting Started

- [Create your first FIDO SSH key](../README.md#quick-start)
- [Check system requirements](install.md#prerequisites)
- [Understanding SSH keytags](design/ssh-keytags.md)

## Common Tasks

### Creating and Managing Keys

- Create a new FIDO SSH key: `keycutter create <ssh-keytag>`
- [SSH to a remote host](recipes/ssh-to-host.md)
- [Add SSH key to GitHub](../README.md#quick-start)
- Create portable key symlinks: `keycutter key link`

### Git Commit Signing

- [Git commit signing with SSH keys](git-signing.md)
- Configure per-identity signing: `keycutter git-identity create <keytag>`
- Set up automatic identity switching: `keycutter git-config setup`

## Configuration and Analysis

- Update Keycutter: `keycutter update`
- Check which keys would be offered: `keycutter authorized-keys <hostname>`

### YubiKey Setup

- [Set up a YubiKey with PIN protection](yubikeys/fido2-on-yubikeys.md)
- [Using YubiKey Manager (ykman)](yubikeys/ykman-yubikey-manager.md)
- [YubiKey touch notifications](yubikeys/yubikey-touch-detector.md)

## Platform-Specific Setup

### VSCode Integration

- [Configure VSCode Remote-SSH](vscode/remote-ssh-extension.md)
- [Example VSCode settings](vscode/settings/)

### Windows Subsystem for Linux (WSL)

- [GPG on WSL](yubikeys/gpg-on-wsl.md)
- WSL SSH configuration (see installation guide)

## SSH Configuration

- [Managing SSH agents](../ssh_config/keycutter/agents/README.md)
- [Defense layers and security](design/defense-layers-to-protect-against-key-misuse.md)
- Connect through firewalls using port 443

## Troubleshooting

- [Common issues and solutions](troubleshooting.md)
- [Debug SSH connections](troubleshooting.md#debugging-ssh-connections)
- [VSCode connection issues](vscode/remote-ssh-extension.md#troubleshooting)
- FIDO PIN reset procedures

## Advanced Topics

- [Project design goals](design/design-goals.md)
- [Why use FIDO SSH keys with Git](design/why-fido-ssh-keys-are-good-for-git-access-on-managed-devices.md)
- [Security best practices](design/defense-layers-to-protect-against-key-misuse.md)
- Multiple GitHub accounts and organizations

## Tips and Tricks

- [Useful commands and shortcuts](tips-and-tricks.md)
- Working with multiple YubiKeys
- Managing keys across devices

