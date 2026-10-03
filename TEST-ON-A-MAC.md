# Test on a Mac: one Touch ID key, used against github.com

Branch `skill` of github.com/mbailey/keycutter. You need a Mac with Touch ID, a recent macOS
(it must have `/usr/lib/ssh-keychain.dylib` and `sc_auth`), the lid
**open** and the screen **unlocked**. No YubiKey. Nobody has run this
with a real Touch ID yet: these steps are the proof.

It all happens in a **scratch dir**, so an existing `~/.ssh/keycutter`
(upstream keycutter, say) is never touched. Run it in your own terminal.

```bash
ME=alice                                   # your GitHub username
TAG="github.com_${ME}@$(hostname -s)"
D="$HOME/keycutter-lab-test"               # scratch config tree; your ~/.ssh is untouched
unset KEYCUTTER_ORIGIN                     # origin = host name = the Secure Enclave

# 1. Get the branch; install the config tree into the scratch dir.
#    Answer y to the plan, and n to the offer of a ~/.local/bin symlink.
git clone -b skill https://github.com/mbailey/keycutter keycutter-skill && cd keycutter-skill
./bin/keycutter install --dest "$D"
grep -n 'SecurityKeyProvider' "$D/keycutter.conf"     # expect it UNcommented, under Host *

# 2. Make the key. Touch ID asks now (and on every use).
./bin/keycutter create "$TAG" --dest "$D" --dry-run   # the exact commands it will run
./bin/keycutter create "$TAG" --dest "$D"

# 3. Give GitHub the public key: paste the output of this at
#    github.com -> Settings -> SSH and GPG keys -> New SSH key.
cat "$D/keys/$TAG.pub"

# 4. Use it, through the scratch config. Check what ssh resolved first:
#    the scratch file's `Include keycutter/...` lines still read from
#    ~/.ssh/keycutter, so an existing tree there can add settings.
ssh -F "$D/keycutter.conf" -G "github.com_${ME}" | grep -E '^(hostname|user|securitykeyprovider) '
#    expect: hostname github.com, user git, securitykeyprovider /usr/lib/ssh-keychain.dylib
ssh -F "$D/keycutter.conf" -i "$D/keys/$TAG" -T "github.com_${ME}"   # Touch ID, then "Hi alice! ..."
```

## What good looks like

- Step 1: the plan line `keys: Secure Enclave: origin '<host>' = this
  Mac's host name ...`, and `grep` shows the line without a `#`.
- Step 2 says `origin '<host>' is this Mac's host name -> Secure Enclave`
  and ends `keycutter-create: created .../keys/<TAG>`.
  `sc_auth list-ctk-identities` now shows `<TAG>` in the Label column.
- Step 4 asks for Touch ID, then GitHub greets you. Cancel the Touch ID
  prompt and it fails: that is the point.

## If it refuses

- *screen is locked* / *lid closed*: unlock, open the lid, run step 2 again.
- *already exists*: an Enclave identity with that label is left from a
  previous try. Remove it (below), then retry.
- *did not create identity*: sc_auth exits 0 even when it fails, so
  keycutter checks the listing. Read the sc_auth message above it.
- *no terminal*: you ran it from a tool, not a terminal. Use a terminal.

## Remove it afterwards

```bash
TAG="github.com_alice@$(hostname -s)"      # as above
sc_auth list-ctk-identities                # the hex on the $TAG row (Public Key Hash) is <hash>
sc_auth delete-ctk-identity -h <hash>
rm -rf "$HOME/keycutter-lab-test"          # the scratch tree and the key handle
```

Then delete the key on github.com (Settings -> SSH and GPG keys), and the
clone. Nothing else was written: no `~/.ssh/config` change, no symlink.

For the real install an attendee does (into `~/.ssh/keycutter`, with the
`Include` line), and its removal, see `README.md`.
