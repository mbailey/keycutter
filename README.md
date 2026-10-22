---
alias: Keycutter
---

# Keycutter: hardware-backed SSH keys, one per account

Keycutter keeps your SSH keys in hardware, a YubiKey or a Mac's Secure
Enclave, with one key per service and account. The private key cannot be
copied off the device, and every use needs a touch, so nothing on your laptop
can act as you without your finger.

It began with a question: how do you contribute to open source on GitHub from
a laptop your employer manages, without handing that laptop your personal
GitHub identity? The answer holds against more than a managed laptop. Malware,
an intruder, a malicious admin, and now AI coding agents can all run as you,
with your shell, your `~/.ssh` and your `git push`. A key on disk is theirs to
use. A key in hardware signs only when you touch it.

What it stops is silent use. A touch you give is still a touch, and a key
minted with `--no-touch` makes no such check.

In daily use by its author and others since March 2024. Built for YubiKeys;
since October 2026 a Mac with Touch ID can use its Secure Enclave instead,
with nothing to plug in.

## Quickstart

```shell
# Install
$ curl https://raw.githubusercontent.com/mbailey/keycutter/master/install.sh | bash

# Create a key for one GitHub account (YubiKey, or the Secure Enclave on a Mac)
$ keycutter create github.com_alex

# Use it (touch the key when asked)
$ ssh -T github.com_alex
Confirm user presence for key ECDSA-SK SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
User presence confirmed
Hi alex! You've successfully authenticated, but GitHub does not provide shell access.
```

## What you get

- **Hardware keys:** a [YubiKey][] (or any FIDO2 device), or the
  [Secure Enclave][] on a Mac. Uncopiable, a touch per use, and on the
  YubiKey a PIN with retry lockout.
- **[Keytags][]:** keys named `<service>_<user>@<device>`, so
  `ssh github.com_alex` and `ssh github.com_alexwork` each pick the right key
  with no `Host` blocks to write. The naming is the configuration.
- **[Agent profiles][]:** choose which keys each remote host may use. A work
  server never sees a personal key.
- **[Key privacy][]:** only the key meant for a host is offered to it.
- **Commit signing:** `keycutter git-signing enable` signs commits with the
  same key, one touch per commit.
- **SSH over SSM (AWS):** the public key is removed from the host after login.
- **Linux, macOS and Windows ([WSL][]),** including [VS Code Remote-SSH][].

## Example: two GitHub accounts, no custom config

```bash
git clone git@github.com_alex:mbailey/keycutter.git      # GitHub user @alex
git clone git@github.com_alexwork:mbailey/keycutter.git  # GitHub user @alexwork
```

Keycutter routes `github.com_<user>` to `github.com` and offers the matching
key. No `Host` entries, one key per account.

## Project goals

- **Safe:** never damage a user's SSH keys or config. Confirm and back up changes.
- **Simple:** keep the code, and the config it writes, easy to audit.
- **Solid:** work for everything SSH is used for (scp, rsync, agent forwarding).

## Going further

- **[Tutorial][]:** common workflows, step by step.
- **[Installation][]:** prerequisites, platforms, troubleshooting.
- **[Configuration][]:** the `~/.ssh/keycutter/` tree: agents, hosts, keys, scripts.
- **[Secure Enclave][]:** Mac keys: how they are made, what lives where, the caveats.
- **[Tips and tricks][]:** undocumented features.
- **[Development][]:** how to develop and test keycutter locally.

`keycutter --help` lists every command. `keycutter update` pulls the latest
version and offers to refresh the files under `~/.ssh/keycutter`.

## Prior art

- **[ssh-over-ssm][]:** the original source of `keycutter/scripts/ssh-ssm`.
- **[ssh-ident][]:** different agents and keys for different projects, with ssh.

[Agent profiles]: ssh_config/keycutter/agents/README.md
[Configuration]: docs/config/README.md
[Development]: docs/development.md
[Installation]: docs/install.md
[Key privacy]: docs/design/defense-layers-to-protect-against-key-misuse.md
[Keytags]: docs/ssh-keytags.md
[Secure Enclave]: docs/secure-enclave.md
[Tips and tricks]: docs/tips-and-tricks.md
[Tutorial]: docs/tutorial.md
[VS Code Remote-SSH]: docs/vscode/README.md
[WSL]: docs/install.md#wsl-windows-subsystem-for-linux
[YubiKey]: docs/yubikeys/README.md
[ssh-ident]: https://github.com/ccontavalli/ssh-ident
[ssh-over-ssm]: https://github.com/elpy1/ssh-over-ssm
