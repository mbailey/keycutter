# Why FIDO SSH keys are good for Git access on managed (untrusted) devices

## FIDO SSH keys

- **Can be used for SSH authentication and signing Git commits**
- **Can't be extracted or copied from the physical device.**
- **Support Resident Keys / Discoverable Credentials**: stored directly on FIDO device, these are convenient for Security Keys used across multiple devices but adds to the risk if the Security Key falls into the wrong hands.

## YubiKeys

- Can store multiple FIDO SSH Keys (compared to only one GPG based SSH key)
- Can lock out users permanently after N incorrect PIN attempts
- Can require a user to touch them before use - preventing malware or networked attacker
- Include Nano models which can be left permanently in devices
- Include keyring style devices that are convenient for using between devices.
- *Additionally, can be used for Passkey / MFA (multi-factor authentication) to GitHub*

## Github

- Allows individuals to have multiple accounts: Good for enforcing security boundaries.
- Allows accounts to have multiple SSH keys
- Does not allow key reuse between accounts

## Git

- Allows conditional inclusion of global config files based on repo config values
- Allows replacement of domain part in remote.origin.url to trigger custom SSH config

## SSH

- Allows config.d style inclusion of config files

## What this enables us to do

- Use separate GitHub accounts per security domain (e.g. personal, work, public)
- Use Resident SSH Keys only on Secutity Keys you intend to use across multiple devices.
- Use Keycutter to create a FIDO SSH key per yubikey, per github account
- Cloning git repos with Keytag identity part instead of github.com will then ensure:
    - SSH knows which key to use for auth
    - Git knows which key to use for signing
