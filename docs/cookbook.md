---
alias: Keycutter Cookbook
---
# Keycutter Cookbook

A collection of practical recipes for common SSH tasks using Keycutter.

## Getting Started
- Create your first FIDO SSH key
- [Set up a YubiKey with PIN protection](yubikeys/fido2-on-yubikeys.md)
- [Understand SSH key naming conventions](design/ssh-keytags.md)
- Add a key to GitHub
- Clone your first repository using the new key

## Git Operations
- [Why use FIDO SSH keys with Git](design/why-fido-ssh-keys-are-good-for-git-access-on-managed-devices.md)
- Clone a repository using SSH
- Push commits signed with your SSH key
- Use different keys for different GitHub accounts
- Work with multiple GitHub organizations
- [Using rsync and inline commands](tips-and-tricks.md)

## Remote Access
- SSH to a remote host
- [Managing SSH agents](ssh-agent.md)
- Copy files securely using scp/rsync
- Set up jump hosts
- Connect through firewalls (port 443)
- [Using VSCode Remote-SSH](vscode/remote-ssh-extension.md)

## Device Management
- [Set up and manage YubiKeys with ykman](yubikeys/ykman-yubikey-manager.md)
- Work with multiple YubiKeys
- Manage multiple SSH agents
- Move keys between devices
- [Get notified when YubiKey needs touch](yubikeys/yubikey-touch-detector.md)

## Platform Specific
- Set up WSL for FIDO SSH keys
- Configure macOS for FIDO SSH keys
- [Configure VSCode Remote-SSH](vscode/remote-ssh-extension.md)
- [Example VSCode settings](vscode/settings/)

## AWS Integration
- Use SSH over AWS Systems Manager (SSM)
- Access EC2 instances securely
- Temporary access to cloud resources

## Troubleshooting
- [Common issues and solutions](troubleshooting.md)
- Debug SSH key offerings to hosts
- Recover from lost/damaged security key
- Reset FIDO PIN after failed attempts
- Fix common VSCode connection issues
- [Understanding security layers](design/defense-layers-to-protect-against-key-misuse.md)

## Security Best Practices
- [Project design goals and philosophy](design/design-goals.md)
- [Defense in depth approach](design/defense-layers-to-protect-against-key-misuse.md)
- Enforce security boundaries between accounts
- Manage keys for different trust levels
- Regular security maintenance tasks
- Audit your SSH key usage

*Note: This is a work in progress. Each recipe will be filled out with detailed instructions.*
