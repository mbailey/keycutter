---
alias: Keycutter
---
# Keycutter: FIDO SSH keys made easy.

Keycutter simplifies using multiple private SSH keys on multiple devices.

Ever wondered how to contribute to an open-source project on GitHub from an employer managed (i.e. untrusted) laptop, without compromising the security of your personal GitHub account?

Keycutter came out of an attempt to solve this problem but evolved into a tool to improve security by simplifying management and use of FIDO SSH Keys.

**Keycutter consists of:**

- **`keycutter`:** A CLI tool for creating FIDO SSH keys and managing SSH config.
- **SSH Keytags:** A naming convention that removes need for custom SSH configuration.
- **SSH configuration and scripts:** These don't require modification to use.

**It supports:**

- **Multi-account SSH access to services:** GitHub.com, GitLab.com, etc.
- **FIDO SSH keys ( e.g. Yubikey )):** Uncopiable, physical presence verification, pin retry lockout.
- **Selective SSH Agent Forwarding:** Enforce security boundaries.
- **Public SSH Key privacy:** Only offer relevant keys to remote host.
- **SSH over SSM (AWS):** Public key removed from remote host after login.
- **WSL**: Windows Subsystem for Linux
- **VSCode:** Connect via Remote-SSH Extension

*While initially created for use with YubiKeys and GitHub, Keycutter supports other devices and services.*

## Contents

- [Quickstart](#QUickstart)
- [SSH Keytags](#SSH-Keytags)
- [Installation](#Installation)
- [Usage](#Usage)
- [ISSUES](ISSUES.md)


## Quickstart

```shell
curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash
```

## Goals

- **Safe:** Don't screw up users SSH keys or config. Confirm and backup changes.
- **Simple:** Keep the code and config it generates simple to audit.
- **Solid:** Support all the things people use SSH for (e.g. scp, rsync, etc).

## SSH Keytags

Managing multiple FIDO SSH keys across multiple devices and services can be an effort.

Keycutter introduces **SSH Keytags**, labels to help you organise and keep track of your
FIDO SSH Keys across multiple devices and services.

**SSH Keytags are used:**

- In the SSH Key filename
- In the public key comment
- In the key name on services like GitHub

**SSH Keytag format:**  `<service>_<identity>@<device>`

- **Service:** FQDN of remote service (e.g. gitlab.com)
- **Identity:** The **user account** on remote service (e.g. alex-work)
- **Device**: The **hardware security key** or **computer** where the private key resides.

*Read more about [SSH Keytags](docs/design/ssh-keytags.md)*

## Installation

### 1. Install Prerequisites

*Note: The installer checks requirements for you.*

 **Required:**
  
- **Bash >= 4.0**
- **Git >= 2.34.0**
- **OpenSSH >= 8.2p1** 
  - **WSL** Users need `ssh-sk-helper`([OpenSSH for Windows >= 8.9p1-1](https://github.com/PowerShell/Win32-OpenSSH/releases)))
  - **macOS** Bundled OpenSSH is borked. Update with `brew install openssh` and reload terminal
- **nc**

**Recommended:**

- **GitHub CLI >= 2.0**: (Greater than 2.4.0+dfsg1-2 on Ubuntu)
- **[YubiKey Touch Detector](https://github.com/maximbaz/yubikey-touch-detector):**  Get notified when YubiKey needs a touch.
- **YubiKey Manager (`ykman`)**: Used to set a PIN on Yubikeys, and perform other configuration.

### 2. Install Keycutter

**Clone the Git repo and run installer:**

```shell
git clone https://github.com/bash-my-aws/keycutter
cd keycutter
./install.sh
```

**WSL users: Add this to you shell to your shell profile (e.g. bashrc or zshrc):**

```shell
# WSL (Windows Subsystem for Linux) users need to set the path to ssh-sk-helper.exe
if [[ -f "/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe" ]]; then
	export SSH_SK_HELPER="/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"
fi
```

## Usage

Keycutter provides several commands to manage your SSH keys and configuration:

### Core Commands

```shell
keycutter create <ssh-keytag> [--resident] [--type <key-type>]  # Create a new SSH key
keycutter list                                                   # List SSH keys on GitHub
keycutter authorized-keys <hostname>                            # Show public keys that would be offered to host
keycutter update                                                # Update keycutter from git and refresh config
```

### Additional Commands

```shell
keycutter update-git                                            # Update keycutter from git repository
keycutter update-ssh-config                                     # Update SSH configuration files
keycutter check-requirements                                    # Check if all required software is installed
keycutter smoke                                                 # Run connection tests
```

### Examples

#### 1. Create a FIDO SSH Key

```shell
# Create a key for your personal GitHub account on your work laptop
keycutter create github.com_alex@workpc

# Create a resident key (stored on security key) for your work GitHub account
keycutter create github.com_alexwork@yubikey5 --resident

# Create a specific type of key for GitLab
keycutter create gitlab.com_alex@laptop --type ed25519-sk
```

#### 2. Clone a GitHub repo using your new key

```shell
git clone git@github.com_alex:bash-my-aws/keycutter
```

#### 3. Commit a change signed with your new SSH Key

```shell
cd keycutter
date >> README.md 
git commit -m "I signed this commit with my new SSH Key"
```

#### 4. List your GitHub SSH keys

```shell
keycutter list
```

#### 5. Check what keys would be offered to a host

```shell
keycutter authorized-keys github.com
```

### Explore your new config

You're ready for FIDO SSH access to anything you were using file based SSH keys for.

**Example ssh config generated by keycutter**

With the exception of a single `Include` line added to `~/.ssh/config`, all SSH
configuration generated by keycutter lives under `~/.ssh/keycutter`.

```shell
$ tree ~/.ssh

/home/alex/.ssh
├── config
├── config.backup.1728393975
└── keycutter
    ├── agents
    ├── hosts
    ├── keycutter.conf
    ├── keys
    │   ├── github.com_alexpersonal@x2
    │   ├── github.com_alexpersonal@x2.pub
    │   ├── github.com_alexwork@x2
    │   ├── github.com_alexwork@x2.pub
    │   ├── ssh.github.com_alex-personal@x2 -> github.com_alexpersonal@x2
    │   └── ssh.github.com_work-user@x2 -> github.com_alexwork@x2
    └── scripts
        ├── ssh-agent-ensure
        ├── ssh.bat
        ├── ssh-ssm
        ├── ssh-vanilla
        └── sync-file-to-remote
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
2. Check and update any requirements.
3. Update your SSH configuration with any new changes.

Here's an example of what you might see when running the update command:

```
🔄 Updating Keycutter from git...
Confirm user presence for key ECDSA-SK SHA256:bW8s2icYERtlbt9Y9jrzCDEcdgcmMbWRiBjxtroNLoI
User presence confirmed
Keycutter is already up to date.
All requirements are met.
Keycutter SSH update complete.
```

## See also

- **[Keycutter Documentation](docs/README.md)**
- **[Tips and tricks](docs/tips-and-tricks.md):** Undocumented features and cool tricks.

- **Prior art (and inspiration):**
    - **[ssh-over-ssm (github.com)](https://github.com/elpy1/ssh-over-ssm):** Original source of `keycutter/scripts/ssh-ssm`.
    - **[ssh-ident (github.com)](https://github.com/ccontavalli/ssh-ident):** Different agents and different keys for different projects, with ssh. 
