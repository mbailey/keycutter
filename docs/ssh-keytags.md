---
alias: SSH Keytags
---

# SSH Keytags

SSH Keytags are labels that assist with identification, management and auditing of SSH Keys.

**Format:** `<Service>_<Identity>@<Device>`

## Key Innovation: Multi-Account SSH

With keycutter, you can SSH to services using multiple accounts without creating separate Host entries:

```bash
# Connect to github.com as user 'alex'
ssh github.com_alex

# Connect to github.com as user 'work'
ssh github.com_work
```

This automatically:

- Connects to the actual host (`github.com`)
- Uses the appropriate key (`github.com_alex@yourdevice` or `github.com_work@yourdevice`)
- No Host configuration needed for each account

## SSH Keytags aid Identification, Management and Auditing of SSH Keys

Users of FIDO SSH keys are likely to end up with mutiple keys on mutiple devices.

- **If a device is compromised:** Remove all public keys with that Device identifer from services they were enabled for.
- **When a service account is no longer needed:** Remove private/public SSH keys related to the Service Identities.
- **Auditing**: Reconcile public SSH keys on services against private keys.

## What are SSH Keytags

**Traditionally, SSH Key identification left to user, with defaults being:**

- **Filenames:** id_rsa, id_rsa.pub
- **Comment:** `<user>@<host>`

**SSH Keytags** extend this to the format: **`[<service>_]<user>@<device>`**:

- **Service:** The Service this key is used to connect to ( e.g. GitHub.com, Digital Ocean, AWS)
- **User:** The user/account the key authenticates as on the Service (e.g. alex)
- **Device:** Physical Device where private key resides ( e.g. security key, computer, phone, etc)

**Keycutter uses SSH Keytags in the following places:**

- **SSH Key Filenames:**
  - `~/.ssh/github.com_alex@homepc`
  - `~/.ssh/github.com_alex@homepc.pub`
- **SSH Key Comment:** Helps identify public keys on other systems
- **SSH Key name on remote services:** Helps identify public keys on services like github.com

## Usage Examples

The following is a fictional example of a user with 3 yubikeys:

- One on a keyring carried everywhere.
- The other two residing in personal and employer managed computers.

The following help explain why each key is required:

1. **Services identify a user by their SSH key:** Each service account (e.g. `github.com`) requires different keys.
2. **FIDO SSH keys cannot be copied between Yubikeys:** Each need their own key for each service account.
3. **Alex does not use the same credentials across security domains.**
4. **Alex accesses some personal services from the employer managed computer and vice versa.**

| Keytag                     | Service                             | Identity                  | Device  | Credential Security <br>Domain |
| -------------------------- | ----------------------------------- | ------------------------- | ------- | ------------------------------ |
| `homelab_alexd@keyring`    | unix hosts                          | unix user: `alexd`        | keyring | Personal                       |
| `homelab_alexd@homepc`     | unix hosts                          | unix user: `alexd`        | homepc  | Personal                       |
| `work_e12345@workpc`       | unix hosts                          | unix user: `e12345`       | workpc  | Work                           |
| `work_root@workpc`         | unix hosts                          | unix user: `root`         | workpc  | Work                           |
| `github.com_workgh@workpc` | Github                              | Github User: `workgh`     | workpc  | Work                           |
| `github.com_workgh@homepc` | Github                              | Github User: `workgh`     | homepc  | Work                           |
| `github.com_alex@homepc`   | Github                              | Github User: `personalgh` | homepc  | Personal                       |
| `aws-ssm_e12345@workpc`    | AWS EC2 Instances<br>(SSH over SSM) | Employee Number           | workpc  | Work                           |
| `aws-ssm_personal@homepc`  | AWS EC2 Instances<br>(SSH over SSM) | Generic                   | homepc  | Personal                       |
