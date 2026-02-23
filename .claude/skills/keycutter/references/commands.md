# Keycutter Command Reference

## Agent Commands
```bash
keycutter agent show <agent>                # Show agent details and keys
keycutter agent keys <agent>                # List keys in agent
keycutter agent hosts <agent>               # List hosts using agent
keycutter agent add-key <agent> <key>       # Add key to agent
keycutter agent remove-key <agent> <key>    # Remove key from agent
```

## Host Commands
```bash
keycutter host show <host>                  # Show host config
keycutter host agent <host>                 # Get agent for host
keycutter host keys <host>                  # List keys for host
keycutter host config <host>                # Show SSH config impact
keycutter host edit <host>                  # Edit host config file
```

## Key Commands
```bash
keycutter key show <key>                    # Show key details + fingerprint
keycutter key agents <key>                  # List agents containing key
keycutter key hosts <key>                   # List hosts using key
```

## Git Commit Signing
```bash
keycutter git-signing enable [--global]     # Enable SSH commit signing
keycutter git-signing disable [--global]    # Disable signing
keycutter git-signing status                # Show signing config
```

## SSH known_hosts Management
```bash
keycutter ssh-known-hosts delete-line <n>   # Delete specific line
keycutter ssh-known-hosts remove <host>     # Remove all entries for host
keycutter ssh-known-hosts fix <host>        # Interactive fix
keycutter ssh-known-hosts backup            # Create backup
keycutter ssh-known-hosts restore <file>    # Restore from backup
```

## Update Commands
```bash
keycutter update                            # Full update (git + config + requirements + touch-detector)
keycutter update git                        # Pull latest from git
keycutter update config                     # Update SSH config
keycutter update requirements               # Check system requirements
keycutter update touch-detector             # Update YubiKey touch notification
```

## Other Commands
```bash
keycutter authorized-keys <hostname>        # Show keys offered to host
keycutter push-keys <hostname>              # Push public keys to host
keycutter check-requirements                # Check prerequisites
keycutter install-touch-detector            # Install YubiKey touch notification
```

## Shell Completions

Completions are at `shell/completions/keycutter.bash` in the repo.

**macOS requires bash-completion@2:**
```bash
brew install bash-completion@2
```

The installer auto-links completions if `~/.local/share/bash-completion/completions/` or `/etc/bash_completion.d/` exists. Otherwise:
```bash
echo 'source ~/.local/share/keycutter/shell/completions/keycutter.bash' >> ~/.bashrc
```
