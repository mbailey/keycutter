# SSH Keytags - device@service-identity

SSH Keytags are labels that assist with identification, management and auditing of SSH Keys.

Keycutter recommends (but does not required or enforce) the following conventions.

**Traditionally, SSH Key identification left to user, with defaults being:**

- **Filename:** id_rsa
- **Comment:** user@host

**SSH Keytags** replace this with **device@service-identity**:

- **Device:** Physical Device where private key resides ( e.g. security key, computer, phone, etc)
- **Service:** The Service this key is used to connect to ( e.g. GitHub.com, Digital Ocean, AWS)
- **Identity:** The user/account the key authenticates as on the Service (e.g. alexdoe)

**Where Keycutter uses SSH Keytags:**

- **SSH Key Filenames:** 
    - ~/.ssh/sk01@github-alexdoe
    - ~/.ssh/sk01@github-alexdoe.pub
- **SSH Key Comment:**  Helps identify public keys on other systems
- **GitHub SSH Key name:** Helps identify public keys on Github

**SSH Keytags aid Key Identification, Management and Auditing:**

- **When a device is compromised:** you remove all public keys with that Device identifer in the SSH Keytag from services they were enabled for.
- **When a service or account is no longer needed:** Remove private/public SSH keys related to the Service and/or Service Identities.
- **Auditing**: Reconcile public SSH keys on services against private keys.

## Example: Alex and the three Security Keys

Alex has three Yubikeys:

- A Yubikey Nano in her work laptop (for convenience)
- A Yubikey Nano in her nsfwork laptop (for convenience)
- A Yubikey on her keyring (in case neither laptop is available)

These are the SSH Keytags for the keys she has created:

| Key Tag                       | Device                          | Service | User          |
| ----------------------------- | ------------------------------- | ------- | ------------- |
| keyring@aws-alexdoe           | Yubikey on keychain             | AWS     | @alexdoe      |
| keyring@github-alexdoe        | Yubikey on keychain             | GitHub  | @alexdoe      |
| nsfwork-laptop@aws-alexdoe    | Yubikey Nano on Personal Laptop | AWS     | @alexdoe      |
| nsfwork-laptop@github-alexdoe | Yubikey Nano on Personal Laptop | GitHub  | @alexdoe      |
| work-laptop@github-alexdoe    | Yubikey Nano on Work Laptop     | GitHub  | @alexdoe      |
| work-laptop@github-alexdoe    | Yubikey Nano on Work Laptop     | GitHub  | @alexdoe-work |

