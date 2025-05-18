---
alias: Keycutter
---

# Keycutter: Strengthen your SSH key privacy and security

Keycutter simplifies using multiple private SSH keys on multiple devices.

Ever wondered how to contribute to an open-source project on GitHub from an employer managed (i.e. untrusted) laptop, without compromising the security of your personal GitHub account?

Keycutter came out of an attempt to solve this problem but evolved into a tool to improve security by simplifying management and use of FIDO SSH Keys. It consists of:

- **`keycutter`:** A CLI tool for creating FIDO SSH keys and managing SSH config
- **[SSH Keytags](docs/ssh-keytags.md):** A naming convention that removes need for custom SSH configuration
- **[SSH configuration](docs/config/README.md):** Modular config structure that doesn't require manual editing

While initially created for use with YubiKeys and GitHub, Keycutter supports other FIDO devices and services.

## Contents

- [Features](#features)
- [Project Goals](#project-goals)
- [Example: SSH access to multiple GitHub accounts](#example-ssh-access-to-multiple-github-accounts)
- [Quickstart](#quickstart)
- [Installation](#installation)
- [Usage](#usage)
- [Tutorial](docs/tutorial.md)
- [Updating Keycutter](#updating-keycutter)
- [See also](#see-also)

## Features

- **[FIDO SSH keys (e.g. Yubikey)](./docs/yubikeys/fido2-on-yubikeys.md):** Uncopiable, physical presence verification, pin retry lockout.
- **[Multi-account SSH access to services](./docs/ssh-keytags.md#key-innovation-multi-account-ssh):** GitHub.com, GitLab.com, etc.
- **[Selective SSH Agent Forwarding](./ssh_config/keycutter/agents/README.md):** Enforce security boundaries.
- **[Public SSH Key privacy](./docs/design/defense-layers-to-protect-against-key-misuse.md):** Only offer relevant keys to remote host.
- **SSH over SSM (AWS):** Public key removed from remote host after login.
- **OS Support**: Linux, MacOS, Windows ([WSL](docs/install.md#wsl-windows-subsystem-for-linux)), [VSCode](docs/vscode/README.md) Remote-SSH Extension

## Project Goals

- **Safe:** Don't screw up users SSH keys or config. Confirm and backup changes.
- **Simple:** Keep the code and config it generates simple to audit.
- **Solid:** Support all the things people use SSH for (e.g. scp, rsync, etc).

## Example: SSH access to multiple GitHub accounts

**Connect to multiple Github accounts via SSH without custom config:**

```bash
git clone git@github.com_alex:mbailey/keycutter.git     # Github user @alex
ssh clone git@github.com_alexwork:mbailey/keycutter.git # Github user @alexwork
```

No Host entries needed - keycutter automatically routes to the correct host and uses the appropriate key.

## Quickstart

```shell
# Install Keycutter
$ curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash
<snip>
# Create a FIDO SSH Key
$ keycutter create github.com_alex
<snip>
# Use it
$ ssh -T github.com_alex
Confirm user presence for key ECDSA-SK SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
User presence confirmed
Hi alex! You've successfully authenticated, but GitHub does not provide shell access.
```

## Installation

```shell
curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash
```

The installer will check prerequisites and guide you through the setup. For detailed installation instructions, platform-specific configuration, and troubleshooting, see the [Installation Guide](./docs/install.md).

## Configuration

Keycutter organizes all SSH configuration under `~/.ssh/keycutter/` with a modular structure designed for easy management and security:

- **Agents**: Control SSH agent forwarding to specific hosts
- **Hosts**: Define host-specific settings and identity files
- **Keys**: Store SSH keys using the keytag naming convention
- **Scripts**: Helper scripts for SSH operations

See the [Configuration Guide](docs/config/README.md) for complete details.

## Usage

For a comprehensive guide on using Keycutter, see the [Tutorial](docs/tutorial.md).

To see all available commands, run:

```shell
keycutter --help
```

## Updating Keycutter

It's recommended to update keycutter periodically to ensure you have the
latest features and bug fixes.

To update an existing installation of Keycutter, use the following command:

```shell
keycutter update
```

This command will:

1. Pull the latest changes from the Keycutter git repository.
1. Check and update any requirements.
1. Confirm whether you want to update files in `~/.ssh/keycutter`

Here's an example of what you might see when running the update command:

```
🔄 Updating Keycutter from git...
Confirm user presence for key ECDSA-SK SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
User presence confirmed
Keycutter is already up to date.
All requirements are met.
Keycutter SSH update complete.
```

## See also

- **[Configuration Guide](docs/config/README.md):** Overview of keycutter's configuration structure
- **[Tips and tricks](docs/tips-and-tricks.md):** Undocumented features and cool tricks.

- **Prior art (and inspiration):**
  - **[ssh-over-ssm (github.com)](https://github.com/elpy1/ssh-over-ssm):** Original source of `keycutter/scripts/ssh-ssm`.
  - **[ssh-ident (github.com)](https://github.com/ccontavalli/ssh-ident):** Different agents and different keys for different projects, with ssh.
