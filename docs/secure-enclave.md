# SSH keys in the Mac's Secure Enclave

A Mac with Touch ID already carries a hardware authenticator: the Secure
Enclave. `keycutter create` can mint an SSH key there, so a Mac user gets
the properties keycutter was built around (a private key that cannot be
copied, a finger on the sensor for every signature) with nothing to buy and
nothing to install. Apple ships the piece OpenSSH needs,
`/usr/lib/ssh-keychain.dylib`, with macOS.

```shell
keycutter create github.com_alex@laptop                  # Enclave, on a Mac with no YubiKey plugged in
keycutter create github.com_alex@laptop --authenticator secure-enclave   # Enclave, said explicitly (alias: mac)
keycutter create github.com_alex@laptop --authenticator yubikey          # the YubiKey, whatever is plugged in
```

Everything else is unchanged: the keytag, the `keys/` directory, the agent
profiles, `keycutter keys`, GitHub upload, the `ssh.github.com` alias.

## Which authenticator a new key goes to

The choice applies only to `-sk` key types (the default `ed25519-sk`, and
`ecdsa-sk`). Software keys (`rsa`, `ecdsa`, `ed25519`) are made the same
way as always and never ask. In order:

1. `--authenticator yubikey|secure-enclave` on the command line.
2. `KEYCUTTER_AUTHENTICATOR` in the environment.
3. A saved answer in `~/.ssh/keycutter/settings`
   (`KEYCUTTER_AUTHENTICATOR=...`).
4. Otherwise, on a Mac that has the provider and `sc_auth`:
   - **no YubiKey plugged in**: the Secure Enclave. keycutter prints one
     line saying so. Nothing is saved, so the next `create` with a YubiKey
     plugged in asks again.
   - **a YubiKey plugged in**: keycutter asks once, `[y]ubikey` or
     `[s]ecure enclave`, and saves the answer to `settings`.
   - On any other system: the YubiKey, as before. Nothing is saved.

To change a saved answer, edit `~/.ssh/keycutter/settings`, pass
`--authenticator`, or set the environment variable.

An Enclave key is always P-256, so `--type ed25519-sk` becomes `ecdsa-sk`
when the Enclave is chosen: the chip holds no other curve. `--resident`
does not apply to Enclave keys.

## What ends up on disk

`keycutter create github.com_alex@laptop` with the Enclave writes three
files to `~/.ssh/keycutter/keys/`:

| file | what it is |
| --- | --- |
| `github.com_alex@laptop` | a key **handle**, not a private key. It is a reference to the identity inside this Mac's chip and signs nothing anywhere else. |
| `github.com_alex@laptop.pub` | the public key, `sk-ecdsa-sha2-nistp256@openssh.com`, comment set to the keytag. Upload this. |
| `github.com_alex@laptop.secure-enclave` | an empty marker. Its presence is how the rest of keycutter knows to sign this key through Apple's provider. |

If you accept the `ssh.github.com` alias for a GitHub key, the alias gets
its own marker too, because keycutter's config looks the marker up by the
keytag the connection resolved to.

The marker drives two things:

- **`keycutter.conf`** adds `SecurityKeyProvider /usr/lib/ssh-keychain.dylib`
  to a connection whose key has a marker. It does this only on the Mac
  itself (`SSH_CONNECTION` empty), only for a key named for this origin,
  and only when the marker exists. YubiKey keys keep OpenSSH's built-in
  provider; a system that has no markers sees no change.
- **`ssh-agent-ensure`** loads a marked key with `ssh-add -S` so the agent,
  too, signs through the Enclave. Agent profiles and forwarding work the
  same as for any other key.

## Before you rely on one

- **It lives in this Mac.** The identity cannot be exported, backed up or
  moved to another machine. Register a second key with each service (a
  YubiKey, or another Mac's Enclave key) so a lost or wiped Mac is not a
  lockout.
- **It signs only from this Mac's own console.** keycutter sets the
  provider only when `SSH_CONNECTION` is empty, so in a shell you reached
  over SSH the key is not offered. Use agent forwarding from the Mac for
  that case, as with a YubiKey.
- **Touch ID needs the lid open** (or a Touch ID keyboard). With the lid
  shut the sensor is unavailable and a signature is refused outright,
  with no prompt and no sound. keycutter refuses to mint a Touch ID key
  in clamshell mode for the same reason.
- **Mint it with the screen unlocked.** An identity created behind a
  locked screen never registers with the token: `sc_auth` reports success
  and ssh cannot see the key. keycutter checks and refuses.
- **One signature, one touch.** Git commit signing with this key means a
  finger on the sensor for every commit. That is the feature, not a bug:
  nothing signs as you without you.
- **P-256 only**, as above. GitHub, GitLab and OpenSSH servers accept
  `sk-ecdsa-sha2-nistp256@openssh.com` keys.

### `--no-touch`

`keycutter create <keytag> --no-touch` mints the identity with no presence
check (`sc_auth -t none`). It still cannot leave the chip, but any process
running as you on an unlocked Mac can sign with it, silently. It exists for
a Mac that runs with the lid shut at a desk. Keep such a key out of any
agent profile you forward, and prefer a Touch ID key everywhere else.

## How a key is made

For the curious, and for anyone debugging it by hand:

1. `sc_auth create-ctk-identity -l <keytag> -k p-256-ne -t bio` asks the
   Enclave for a non-exportable P-256 identity labelled with the keytag.
   Touch ID is required here and on every later signature. keycutter does
   not trust the command's exit status (it is 0 even on failure); it lists
   the identities afterwards and takes the new fingerprint as the receipt.
2. `ssh-keygen -K -w /usr/lib/ssh-keychain.dylib` downloads the handles of
   **every** identity the provider knows, so keycutter runs it in a private
   temporary directory and keeps only the file whose fingerprint matches
   step 1. The provider asks for a PIN it does not have; keycutter answers
   with an empty one so the download never stops at a prompt.
3. The handle is installed as the key, its `.pub` is rewritten with the
   keytag as comment, and the empty `.secure-enclave` marker is written
   beside them, all mode `0600`.

keycutter refuses to mint when a key, `.pub` or marker of that name already
exists, or when an Enclave identity with the same label already exists.

## Removing a key

```shell
sc_auth list-ctk-identities -t ssh                 # find the hash by its label, the keytag
sc_auth delete-ctk-identity -h <hash>
rm ~/.ssh/keycutter/keys/<keytag>{,.pub,.secure-enclave}
```

Then remove the public key from GitHub (or wherever it was authorised) and
from any `ssh.github.com` alias. `keycutter keys` lists the key by name
only, never the marker.

## When it goes wrong

| you see | what it means |
| --- | --- |
| `the screen is locked` from `keycutter create` | Unlock the Mac and run it again. A key minted now would be invisible to ssh. |
| `Touch ID is unavailable while the lid is closed` | Open the lid or use a Touch ID keyboard; or decide for `--no-touch`, knowing what it gives up. |
| `a Secure Enclave identity labelled '<keytag>' already exists` | An earlier attempt left an identity behind. Delete it (`sc_auth delete-ctk-identity -h <hash>`) or choose another keytag. |
| `sc_auth did not create identity` | Read the line `sc_auth` printed just above it; the usual cause is the lid or the lock screen. |
| `no downloaded handle has fingerprint ...` | The identity exists but the provider did not serve it. Delete it and mint again with the screen unlocked. |
| `device not found` or `Failed to get private key` when ssh uses the key | The identity was minted behind a locked screen. Delete it and mint again. |
| the key is never offered in an SSH session on another host | By design: the provider is set only on the Mac's own console. Forward an agent from the Mac instead. |
| `ssh-keygen -t ecdsa-sk -w /usr/lib/ssh-keychain.dylib` fails with `provider failure` | Expected: Apple's provider cannot enrol keys, which is why keycutter mints with `sc_auth`. |

A Secure Enclave Touch ID prompt does not trigger `keycutter-touch-notify`
yet; the sound is for YubiKeys today.
