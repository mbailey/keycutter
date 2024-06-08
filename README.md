---
alias: SSH Keycutter
---

# [Preview] Keycutter - FIDO SSH Keys made easy

- 8 Jun 2024: Preparing for alpha release (big changes being made)
- 18 Mar 2024: Preview release for review only

Ever wondered how to contribute to an open-source project on GitHub from an
employer managed (i.e. untrusted) laptop, without compromising the security of
your personal GitHub account?

Keycutter came out of an attempt to solve this problem but evolved into a tool
improve security by simplifying FIDO SSH Key management.

*While initially created for use with Yubikeys and GitHub, Keycutter supports other devices and services.*

**Keycutter is a config cookie cutter that creates:**

- **FIDO SSH Keys on Hardware Security Keys:**

    - **Secure and convenient authentication:** No way to extract the private key from the device.
    - **Support for multiple keys on the same device:** enforce separation between security domains.
    - **User presence verification:** defend against network attacks and malware.
    - **PIN retry lockout:** defend against stolen key

- **Git config:**

    - Commit and tag signing with SSH keys
    - Sets User name and email on a per-key basis.

- **SSH config:**

    - Automatic key selection for a given service and identity based on custom hostname.
    - Selective key forwarding to remote hosts.

**All config is stored in a single directory (`~/.keycutter`) which:**

- Can be kept in version control.
- Can be used on multiple devices / hosts.
 

## SSH Keytags

Managing multiple FIDO SSH keys across multiple devices and services can be an effort.

Keycutter introduces **SSH Keytags**, labels to help you organise and keep track of your
FIDO SSH Keys across multiple devices and services.

**SSH Keytags are used:**

- In the SSH Key filename
- In the public key comment
- In the key name on services like GitHub

**SSH Keytag format:**  <service>_<identity>@<device>

- **Service:** FQDN of remote service (e.g. gitlab.com)
- **Identity:** The **user account** on remote service (e.g. alexdoe-work)
- **Device**: The **hardware security key** or **computer** where the private key resides.

*Read more about [SSH Keytags](docs/ssh-keytags.md)*



## Installation

- **Prerequisites:**
  
  - **Bash >= 4.0**
  - **Git >= 2.34.0**
  - **GitHub CLI >= 2.0** (Greater than 2.4.0+dfsg1-2 on Ubuntu)
  - **OpenSSH >= 8.2p1** (WSL users need `ssh-sk-helper`([OpenSSH for Windows >= 8.9p1-1](https://github.com/PowerShell/Win32-OpenSSH/releases)))
  - **Yubikey Manager**

- **Recommended:**

    - **[yubikey-touch-detector](docs/yubikey-touch-detector.md)**: Displays a notification when touch required.

1. **Install Keycutter**:

    Clone the Git repo:

    ```shell
    git clone https://github.com/bash-my-aws/keycutter
    ```

    Add the following to your shell profile (e.g. bashrc or zshrc):

    ```shell
    # keycutter/ssh/config uses these to determine which SSH key to use
    export KEYCUTTER_HOSTNAME="$(hostname -s)" # or a preferred alias for this device
    [[ -z "${SSH_CONNECTION}" ]] && export KEYCUTTER_ORIGIN="${KEYCUTTER_HOSTNAME}"

    # WSL (Windows Subsystem for Linux) users need to set the path to ssh-sk-helper.exe
    if [[ -f "/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe" ]]; then
        export SSH_SK_HELPER="/mnt/c/Program Files/OpenSSH/ssh-sk-helper.exe"
    fi
    ```

    As a config cookie cutter, keycutter is not required to be in the path
    but it is useful for generating new configs.
    Optionally add the bin directory to your path:
    ```shell
    # Used for generating config with keycutter
    export PATH="$PATH:${PWD}/keycutter/bin"
    ```


## Usage

### Create a FIDO SSH Key

Provide an SSH Keytag (<service>_<identity>@<device>) to the create command:

```shell
keycutter create github.com_alexdoe@personal
```

    For a particular service and identity on a device, separate domain name and
    user name with an underscore and append the device name after the `@`
    symbol.
    
    ```shell
    keycutter create github.com_alexdoe@personal-laptop
    ```

2. **Clone any GitHub repo using your new key**: 

    ```shell
    git clone git@github.com_alexdoe:bash-my-aws/keycutter
    ```

3. **Commit a change signed with your new SSH Key**:

    ```shell
    cd keycutter
    date >> README.md 
    git commit -S -m "I signed this commit with my new SSH Key"
    ```

4. **Review Keycutter Configuration Directory:** or [view example files here](docs/keycutter-config-dir/example/).

    ```shell
    $ tree ~/.keycutter
    /home/alexdoe/.keycutter
    ├── git
    │   ├── allowed_signers
    │   ├── config.d
    │   │   └── github.com_alexdoe-work
    │   └── config
    └── ssh
        ├──config 
        ├──config 
        ├──hosts 
        │   └── github.com_alexdoe-work
        └── keys
            ├── github.com_alexdoe-work@yk01
            └── github.com_alexdoe-work@yk01.pub
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


## See also

- [Keycutter Documentation](docs/README.md)
- [Tips and tricks](docs/tips-and-tricks.md): Undocumented features and cool tricks.
