# Touch ID SSH keys on macOS

macOS 26 (Tahoe) and later can hold SSH keys in the Secure Enclave and require
Touch ID each time they are used. Keycutter supports this as a key type:

```shell
keycutter create github.com_alex@laptop --type touchid
```

## How it works

Apple ships `/usr/lib/ssh-keychain.dylib`, a FIDO `SecurityKeyProvider` that
exposes CryptoTokenKit identities to OpenSSH as `ecdsa-sk` (P-256) keys. The
provider can't enroll new keys, so keycutter:

1. Creates a non-exportable P-256 identity that needs biometrics:
   `sc_auth create-ctk-identity -l <ssh-keytag> -k p-256-ne -t bio`
2. Downloads its key handle with `ssh-keygen -K -w /usr/lib/ssh-keychain.dylib`
   into `~/.ssh/keycutter/keys/<ssh-keytag>` (the private key never leaves the
   Secure Enclave).
3. Writes a marker to `~/.ssh/keycutter/keys/.touchid/<ssh-keytag>` holding the
   identity's public key hash.

The marker tells keycutter's SSH config to set
`SecurityKeyProvider /usr/lib/ssh-keychain.dylib` for that key, and tells
`ssh-agent-ensure` to load it with `ssh-add -S`. YubiKey keys keep using the
default provider.

Homebrew OpenSSH (needed for YubiKey keys on macOS) and Apple's OpenSSH can
both load the provider.

## Trade-offs compared with a YubiKey

- **Bound to one Mac.** The key can't be moved or backed up. Keep a second key
  (for example a YubiKey) registered with each service so losing the Mac
  doesn't lock you out.
- **P-256 only.** Keys are `sk-ecdsa-sha2-nistp256@openssh.com`. GitHub accepts
  these for authentication and signing.
- **Touch ID, not physical presence of a separate device.** Someone with your
  unlocked Mac and your fingerprint can use the key. A YubiKey adds a second
  device.

## Not yet supported

- **Git commit signing.** `ssh-keygen -Y sign` needs the provider too. Until
  keycutter wraps `gpg.ssh.program`, set it up by hand, e.g. a script that runs
  `SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib ssh-keygen "$@"`.
- **Profile hosts (`work`, `personal`).** The `hosts/*.conf` profiles only
  get the provider through `ssh-agent-ensure`. Direct use without an agent needs
  `SecurityKeyProvider /usr/lib/ssh-keychain.dylib` in that profile.

## Removing a Touch ID key

```shell
cat ~/.ssh/keycutter/keys/.touchid/<ssh-keytag>   # public key hash
sc_auth delete-ctk-identity -h <hash>
rm ~/.ssh/keycutter/keys/<ssh-keytag>{,.pub} ~/.ssh/keycutter/keys/.touchid/<ssh-keytag>
```

Also remove the public key from GitHub or any `authorized_keys` it was added to.
