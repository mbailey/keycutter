---
alias: Keycutter
---

# [Preview] Keycutter - FIDO SSH Keys made easy

Ever wondered how to contribute to an open-source project on GitHub from an employer managed (i.e. untrusted) laptop, without compromising the security of your personal GitHub account?

Keycutter came out of an attempt to solve this problem but evolved into a tool to improve security by simplifying FIDO SSH Key management.

## 🚀 What is Keycutter?

Keycutter streamlines the creation and management of FIDO SSH keys on hardware security devices (e.g., YubiKeys). It automatically sets up SSH configurations, making your keys ready for immediate use.

Originally designed for YubiKeys and GitHub, Keycutter now supports various devices and services.

## 🌟 Key Features

### Security
- **Unstealable FIDO SSH keys**: Keys cannot be extracted from the device
- **Physical presence verification**: Require a touch to approve each use
- **PIN retry lockout**: Protect against stolen hardware security tokens

### Convenience
- **Automatic SSH key selection**: Based on service/identity and host aliases
- **AWS SSH-over-SSM support**: Seamless integration with AWS environments

### Privacy
- **Security Boundary Separation**: Use different keys for personal, work, and other contexts
- **Selective key forwarding**: Map keys to specific services and devices

### Flexibility
- **Centralized configuration**: All configs stored in `~/.ssh/keycutter`
- **Version control friendly**: Easy to backup and sync across devices

## 🏷️ SSH Keytags: Simplified Key Management

Keycutter introduces SSH Keytags to effortlessly organize your FIDO SSH keys across multiple devices and services.

**Format**: `<service>_<identity>@<device>`

Example: `github.com_alex-work@workpc`

Learn more about [SSH Keytags](docs/design/ssh-keytags.md).

## 🛠️ Quick Start

### Prerequisites

- Bash >= 4.0
- Git >= 2.34.0
- OpenSSH >= 8.2p1 (WSL users: [OpenSSH for Windows >= 8.9p1-1](https://github.com/PowerShell/Win32-OpenSSH/releases))
- nc (netcat)

Recommended:
- GitHub CLI >= 2.0
- [YubiKey Touch Detector](docs/yubikeys/yubikey-touch-detector.md)
- YubiKey Manager (`ykman`)

### Installation

Choose one of the following installation methods:

#### Option 1: Quick Install (curlbash)

```bash
curl -sSL https://raw.githubusercontent.com/bash-my-aws/keycutter/master/install.sh | bash
```

This script will check for prerequisites, clone the repository, and set up Keycutter for you.

#### Option 2: Manual Install

1. Clone the repository:
   ```bash
   git clone https://github.com/bash-my-aws/keycutter
   ```

2. Run the install script:
   ```bash
   cd keycutter
   ./install.sh
   ```

### Post-Installation Setup

Add the following to your shell profile (e.g., `.bashrc` or `.zshrc`):

```bash
export KEYCUTTER_HOSTNAME="$(hostname -s)"
[[ -z "${SSH_CONNECTION}" ]] && export KEYCUTTER_ORIGIN="${KEYCUTTER_HOSTNAME}"
export PATH="$PATH:$HOME/.local/share/keycutter/bin"

# For WSL users:
[[ -f "/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe" ]] && \
  export SSH_SK_HELPER="/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"
```

## 💻 Usage

### Create a FIDO SSH Key

```bash
keycutter create github.com_alex@workpc
```

### Use Your New Key

Clone a repo using your new key:
```bash
git clone git@github.com_alex:bash-my-aws/keycutter
```

### Explore Your Keycutter Config

```bash
tree ~/.ssh/keycutter
```

## 📚 Learn More

- [Full Documentation](docs/README.md)
- [Tips and Tricks](docs/tips-and-tricks.md)

## 🙏 Acknowledgements

- [ssh-over-ssm](https://github.com/elpy1/ssh-over-ssm): Inspiration for `keycutter/scripts/ssh-ssm`
- [ssh-ident](https://github.com/ccontavalli/ssh-ident): Inspired our approach to key management

## 📄 License

This project is licensed under the [MIT License](LICENSE).
