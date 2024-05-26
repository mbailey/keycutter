---
alias: SSH Keytags
---
# SSH Keytags

**Format:** `<Service>_<Identity>@<Device>`

SSH Keytags are labels that assist with identification, management and auditing of SSH Keys.

Keycutter recommends (but does not required or enforce) the following conventions.

**Traditionally, SSH Key identification left to user, with defaults being:**

- **Filenames:** id_rsa, id_rsa.pub
- **Comment:** user@host

**SSH Keytags** extend this to the format: **service_identity@device**:

- **Service:** The Service this key is used to connect to ( e.g. GitHub.com, Digital Ocean, AWS)
- **Identity:** The user/account the key authenticates as on the Service (e.g. alexdoe)
- **Device:** Physical Device where private key resides ( e.g. security key, computer, phone, etc)

**Where Keycutter uses SSH Keytags:**

- **SSH Key Filenames:** 
    - `~/.ssh/github.com_alexdoe@sk1`
    - `~/.ssh/github.com_alexdoe@sk1.pub`
- **SSH Key Comment:**  Helps identify public keys on other systems
- **SSH Key name on remote services:** Helps identify public keys on services like github.com

**SSH Keytags aid Key Identification, Management and Auditing:**

- **When a device is compromised:** you remove all public keys with that Device identifer in the SSH Keytag from services they were enabled for.
- **When a service or account is no longer needed:** Remove private/public SSH keys related to the Service and/or Service Identities.
- **Auditing**: Reconcile public SSH keys on services against private keys.

## Example: Alex and the three Hardware Security Keys

Alex has three Yubikeys:

- A Yubikey on her keyring
- A Yubikey Nano in her work laptop (for convenience)
- A Yubikey Nano in her personal laptop (for convenience)

**These are the SSH Keytags for the keys she has created:**

| Key Tag                            | Service | User          | Device                          |
| ---------------------------------- | ------- | ------------- | ------------------------------- |
| aws_alexdoe@keyring                | AWS     | alexdoe       | Yubikey on keychain             |
| aws_alexdoe@personal-laptop        | AWS     | alexdoe       | Yubikey Nano on Personal Laptop |
| github.com_alexdoe@keyring         | GitHub  | alexdoe       | Yubikey on keychain             |
| github.com_alexdoe@personal-laptop | GitHub  | alexdoe       | Yubikey Nano on Personal Laptop |
| github.com_alexdoe@work-laptop     | GitHub  | alexdoe       | Yubikey Nano on Work Laptop     |
| github.com_alexdoe@work-laptop     | GitHub  | alexdoe-work  | Yubikey Nano on Work Laptop     |

