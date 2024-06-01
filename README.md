---
alias: SSH Keycutter
---

# [Preview] Keycutter - FIDO SSH Keys made easy

*18 Mar 2024 - Preview release for review only*

Ever wondered how to contribute to an open-source project on GitHub from an employer managed (i.e. untrusted) laptop, without compromising the security of your personal GitHub account? Keycutter came out of an attempt to solve this problem but evolved into a tool improve security by simplifying FIDO SSH Key management.

## Key Concepts

- [SSH Keytags](docs/ssh-keytags.md)
- [Keycutter Config Directory](docs/keycutter-config-dir/README.md) 
- [Defense layers to protect against key misuse](docs/defense-layers-to-protect-against-key-misuse.md)
- [Why FIDO SSH Keys are good for Git access on managed devices](docs/why-fido-ssh-keys-are-good-for-git-access-on-managed-devices.md)
- [Design goals of the project](docs/design-goals.md)
- Side benefits
    - Doesn't announce your github keys to other services

## Keycutter creates

- **FIDO SSH Keys on Hardware Security Keys**
- **Git config:**
    - Commit and tag signing
    - User Name and Email
- **SSH config:**
    - Host alias automates SSH Key selection for authenticate

*While initially created for use with Yubikeys and GitHub, Keycutter can support other devices and services.*

## FIDO SSH Keys

FIDO SSH keys reside in Hardware Security Keys which allow for:

- **Multiple FIDO SSH Keys on the same Hardware**
- **No known way to extract the private key from the device**
- **User Presence Verification**: defend against remote attacks and malware
- **PIN retry lockout**: defend against stolen key

## SSH Keytags

**SSH Keytags** are labels to help organise SSH Keys across multiple devices and services.

**SSH Keytag format:**  Service_Identity@Device

- **Service:** FQDN of remote service (e.g. gitlab.com)
- **Identity:** The **user account** on remote service (e.g. alexdoe-work)
- **Device**: The **hardware security key** or **computer** where the private key resides.

**SSH Keytags are used:**

- In the SSH Key filename
- In the public key comment
- In the key name on services like GitHub

*Read more about [SSH Keytags](docs/ssh-keytags.md)*


## Quickstart

*See [Installation](#Installation) for pre-requisites and more detail.*

1. **Install Keycutter**:

    Clone the Git repo:

    ```shell
    git clone https://github.com/bash-my-aws/keycutter
    ```

    Add the bin directory to your path:

    ```shell 
    export PATH="$PATH:${PWD}/keycutter/bin" # You may want to add to ~/.bashrc
    ```

2. **Create a FIDO SSH Key**:
 
    ```shell
    keycutter create github.com_alexdoe@personal-laptop
    ```

4. **Clone any GitHub repo using your new key**: 

    ```shell
    git clone git@github.com_alexdoe:bash-my-aws/keycutter
    ```

5. **Commit a change signed with your new SSH Key**:

    ```shell
    cd keycutter
    date >> README.md 
    git commit -S -m "I signed this commit with my new SSH Key"
    ```

6. **Review Keycutter Configuration Directory:** or [view example files here](docs/keycutter-config-dir/example/).

    ```shell
    $ tree ~/.keycutter
    /home/alexdoe/.keycutter
    ├── git
    │   ├── allowed_signers
    │   ├── config.d
    │   │   └── github.com_alexdoe-work
    │   └── config
    └── ssh
        ├──hosts 
        │   └── github.com_alexdoe-work
        └── keys
            ├── github.com_alexdoe-work@yk01
            └── github.com_alexdoe-work@yk01.pub
    ```

## Installation

### Prerequisites
  
  - **Bash >= 4.0**
  - **Git >= 2.34.0**
  - **GitHub CLI >= 2.0** (Greater than 2.4.0+dfsg1-2 on Ubuntu)
  - **OpenSSH >= 8.2p1**
  - **Yubikey Manager**

### Setup for WSL (Windows Subsystem for Linux)

WSL does not support USB devices natively. We can access the Security Device from Linux by using a helper program called `ssh-sk-helper.exe` that forwards requests to Windows OpenSSH .

`ssh-sk-helper.exe` is distributed with Windows OpenSSH version 8.? or later.

#### Steps to enable FIDO SSH Keys in WSL

1. **Download and install a recent [OpenSSH for Windows](https://github.com/PowerShell/Win32-OpenSSH/releases):** (for `ssh-sk-helper.exe`):
2. **Configure OpenSSH in WSL to use `ssh-sk-helper.exe`:**

    ```shell
     echo 'export SSH_SK_HELPER="/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"' >> ~/.bashrc
     ```

### Install from Git

1. Clone the Git repo:

    ```shell
    git clone https://github.com/bash-my-aws/keycutter
    ```

2. Add the bin directory to your path:

    ```shell 
    export PATH="$PATH:${PWD}/keycutter/bin" # You may want to add to ~/.bashrc
    ```

## Usage

### Create FIDO SSH Key

Provide an SSH Keytag to the create command:

```shell
keycutter create <service>_<identity>@<device> # e.g. keycutter create github.com_alexdoe@personal-laptop
```

**Example**: XXX Update

```shell
$ keycutter create github.com_alexdoe@personal-laptop

Creating FIDO SSH Key for laptop@github-alexdoe
Generating FIDO SSH key: /home/alex/.keycutter/ssh/keys/laptop@github-alexdoe
Creating directory: /home/alex/.keycutter/ssh/keys
Generating public/private ecdsa-sk key pair.
You may need to touch your authenticator to authorize key generation.
Enter PIN for authenticator: 
You may need to touch your authenticator (again) to authorize key generation.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/alex/.keycutter/ssh/keys/laptop@github-alexdoe
Your public key has been saved in /home/alex/.keycutter/ssh/keys/laptop@github-alexdoe.pub
The key fingerprint is:
SHA256:W9CBCBS3jqDcQ4hBBX4MqUQMfzxfjsPlARZ6qpnMNm4 laptop@github-alexdoe
The key's randomart image is:
+-[ECDSA-SK 256]--+
|B=+o+o=o ..      |
|o*+. +.o.. .     |
|+oo+= o = .      |
|o.+o O * o       |
|.. oo * S .      |
| o +.  . o       |
|  O     .        |
| oE.             |
| ..              |
+----[SHA256]-----+
SSH key generated at /home/alex/.keycutter/ssh/keys/laptop@github-alexdoe
Creating symlink: /home/alex/.keycutter/ssh/keys/laptop@github-alexdoe -> github-alexdoe
This allows us to leave omit device part of SSH Keytag when referring to keyfile.

Starting SSH Agent... Agent pid 74274
Adding key to SSH Agent... Identity added: /home/alex/.keycutter/ssh/keys/laptop@github-alexdoe (laptop@github-alexdoe)
Configuring git to use the SSH Key for commit/tag signing for relevant repos

Setting up GitHub specific configuration...
Creating SSH configuration file /home/alex/.keycutter/ssh/hosts/github-alexdoe
Adding SSH key to GitHub for auth and commit/tag signing: /home/alex/.keycutter/ssh/keys/laptop@github-alexdoe
Upload public key to GitHub for auth and commit signing using Github CLI? (Y/n) y
  ✓ Logged in to github.com as someuser (keyring)
? You're already logged into github.com. Do you want to re-authenticate? No
GitHub CLI: Required scopes are available.
Adding SSH authentication key (/home/alex/.keycutter/ssh/keys/laptop@github-alexdoe.pub) to GitHub
✓ Public key added to your account
Adding SSH signing key (/home/alex/.keycutter/ssh/keys/laptop@github-alexdoe.pub) to GitHub
✓ Public key added to your account

GitHub Organisations that enable or enforce SAML SSO will require additional setup.
Setup complete for key: laptop@github-alexdoe
```

### keycutter list

```shell
keycutter list
```

**Currently lists:**

- FIDO SSH Keys (resident and non-resident)
- Keys uploaded to GitHub (authentication and signing)

**Example:**

```shell
$ keycutter list
Non-resident FIDO SSH Keys:
/home/alex/.keycutter/ssh/keys/laptop@github-alexdoe.pub
Resident FIDO SSH Keys:
Enter PIN for authenticator: 
You may need to touch your authenticator to authorize key download.
No keys to download
  ✓ Logged in to github.com as alexdoe (keyring)
? You're already logged into github.com. Do you want to re-authenticate? No
GitHub CLI: Required scopes are available.
TITLE                  ID        KEY                                             TYPE            ADDED
laptop@github-alexdoe  96665164  sk-ecdsa-sha2-nistp256...a8To7Y10AAAAEc3NoOg==  authentication  8m
laptop@github-alexdoe  266976    sk-ecdsa-sha2-nistp256...a8To7Y10AAAAEc3NoOg==  signing         8m
```

## What it does

1. Creates a FIDO SSH key: with an SSH Keytag identifying the Security Key it
   resides on and the Service Identity it is used to authenticate as (e.g.
   yubi1@github-alexdoe)

2. Create SSH helper config: to tell ssh which key to use enabled the following
   commands to work immediately:

    ```shell
    ssh git@github.com_alexdoe
    git clone git@github.com_alexdoe:bash-my-aws/keycutter.git
    ```

3. Create Git helper config: sets signing key, name and email

4. Add public key to GitHub: auth & signing

## Why? - Strengthening Security Boundaries on Managed Devices

Connecting to your personal github account from a work managed laptop may allow
an admin, remote attacker or any software running on the laptop to view and
modify your repositories and sign commits / tags as you. It may also allow any
of these actors to copy your credentials for continued remote use.

- Mitigations: 
    - Short lived credentials
        - They still have access as long as you do
    - Credentials tied to source address
        - No good if attacker behind same ip
            - VPN
            - work / home / cafe NAT
            - can inject themself into ISP

My employer recently mandated that staff work on their laptops with MDM (mobile
device management). This opens up the possibility of other people and processes
on my laptop without my knowledge, raising privacy and security concerns. In the
same month, a client also mandated we work on their managed devices.

Until this point in my life, I have always had full control over the computers I
work on. This meant that at times my personal, work and public identities and
data were present on the same device. It's always better to maintain clear
separation between different security domains but like with backups or flossing,
best practice is not ubiquitous.

I decided to explore how I could defend against the operator of a managed device
accessing **credentials** or **data** they should not have access to.

SSH Key Cutter is one project to come out of this.

## See also

- [tips-and-tricks](docs/tips-and-tricks.md)

- FIDO keys that require user-presence confirmation offer a little more defence, but are also similarly phishable.
- https://www.openssh.com/agent-restrict.html