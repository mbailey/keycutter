# Keycutter minimal — fresh machine to working FIDO2 SSH

Two target outcomes, nothing else:

1. SSH to GitHub with a hardware-backed (FIDO2) key.
2. SSH to one of your own machines with agent forwarding set up correctly.

Uses only: the keycutter config tree + `ssh-keygen` + (optionally) `gh`.
No installer beyond `keycutter-install`, no other CLI. Every step is a
command you can read.

---

## 0. Prerequisites (2 minutes)

| Need | Check | Fix |
|---|---|---|
| OpenSSH ≥ 8.2p1 | `ssh -V` | **macOS:** Apple's bundled ssh (currently 10.2p1) *does* compile in the `sk` key types now, but ships **no FIDO middleware**, so an `ed25519-sk` key fails at use time with `No FIDO SecurityKeyProvider specified` (search that string — it's the tell). `brew install openssh` is still the fix; make sure it wins in `PATH`. **Linux:** distro OpenSSH is fine. |
| A FIDO2 key | YubiKey 5+, SoloKey, etc. plugged in | — |
| (optional) GitHub CLI | `gh --version` | only for uploading the key from the terminal; the web UI works too |

**macOS: pin your hostname first.** The config selects keys by
`keys/%n@%L`, where `%L` is this machine's short hostname. On macOS an
*unpinned* hostname follows DHCP/network location and drifts (e.g.
`laptop` → `laptop-2` on a café network) — and when `%L` changes, **every**
key silently stops matching (no error, ssh just offers nothing). Pin it once:

```bash
scutil --get HostName 2>/dev/null || echo '(unset — will drift)'
sudo scutil --set HostName laptop     # set once; now %L is stable
```

Linux hostnames don't drift this way — no action needed.

## 1. Install the config tree

```bash
# From a clone of this repo — copies skills/keycutter/templates/keycutter/
# into ~/.ssh/keycutter/ idempotently, prompting on conflicts:
./bin/keycutter install --dry-run   # preview first
./bin/keycutter install             # then install
# ...or run the porcelain script directly by its path:
#   skills/keycutter/scripts/keycutter-install --dry-run

# Wire it in. No ~/.ssh/config yet: create it with this one line.
# Already have one: append `Match all` then this line at its END, so your
# own settings keep priority (without `Match all` the Include hides in
# your last Host block).
#   Include keycutter/keycutter.conf
```

That's the whole install: file copies into `~/.ssh/keycutter/` (perms
tightened to `0700` on the directories that need it) plus one `Include`
line you add yourself. See `skills/keycutter/scripts/keycutter-install`'s
own `--help` for the create/differ/same plan it prints before touching
anything.

## 2. Create a FIDO2 key for GitHub

Name the key with an **SSH keytag**: `service_user@device`, where *device*
is this machine's short hostname (`hostname -s`) — that's what makes the
config select it automatically (see `ssh-config-explained.md`).

```bash
./bin/keycutter create github.com_alice
# no '@device' given -> offered github.com_alice@<hostname -s>, confirm Y
# -> touch your key when it blinks
```

That's the whole create — `keycutter-create` is a pure `ssh-keygen`
wrapper (fork (c), see `ssh-config-explained.md`): it validates the
keytag, proposes the device suffix, sets `0700`/`0600` perms, runs
`ssh-keygen -t ed25519-sk`, and prints (never runs) the GitHub follow-up
commands. It touches **no ssh config** — key selection is already handled
by the static `IdentityFile` line in `keycutter.conf`. The key is
non-resident and touch-required by default — the private key file on disk
is just a handle; it's useless without the hardware. Want a resident key
instead? `keycutter-create --resident ...` — see rule 3 below.

Want a different device label than your hostname? Pass the full keytag
yourself, e.g. `keycutter create github.com_alice@work-laptop`.

## 3. Give GitHub the public key

`keycutter-create` prints these for you at the end — copy-paste them:

```bash
gh ssh-key add --type authentication --title github.com_alice@laptop \
  ~/.ssh/keycutter/keys/github.com_alice@laptop.pub
gh ssh-key add --type signing --title github.com_alice@laptop \
  ~/.ssh/keycutter/keys/github.com_alice@laptop.pub   # optional: commit signing
```

`gh ssh-key add` 404s? A freshly-authed `gh` token lacks the key-write
scopes — grant them once:

```bash
gh auth refresh -h github.com -s admin:public_key,admin:ssh_signing_key
```

No `gh`? Paste the `.pub` contents at <https://github.com/settings/keys>.
(Org uses SAML SSO? Authorize the key on that same page.)

## 4. Use it

```bash
ssh -T github.com_alice          # touch → "Hi alice!"
git clone git@github.com_alice:owner/repo.git
```

Why this works with no `Host` stanza for your account: the config maps any
`github.com*` alias to the real `github.com` (user `git`), and the `Host *`
`IdentityFile ~/.ssh/keycutter/keys/%n@%L` line offers
`keys/<alias>@<your-hostname>` as the identity if it exists (silent no-op
otherwise — see `ssh-config-explained.md`). Second account? Just repeat
steps 2-3 with `github.com_alicework` —
`git clone git@github.com_alicework:org/repo.git` routes itself.

Firewall blocks port 22? GitHub also answers SSH on `ssh.github.com:443`.
Two ways to reach it:

- **Blanket (simplest)** — uncomment the `HostName ssh.github.com` and
  `Port 443` lines in the `Host *github.com*` block of `keycutter.conf`.
  *Every* GitHub alias now tunnels over 443; you keep using
  `github.com_alice` and your existing key, no other change.
- **Per-alias** — if you want 443 only for specific aliases, add a
  companion stanza to a `hosts/*.conf` file (this is why the `ssh.` prefix
  needs its own stanza: `Host github.com*` deliberately doesn't match it, so
  without this the name dies in DNS):

  ```text
  Host ssh.github.com*
    HostName ssh.github.com
    Port 443
  ```

  Then connect as `ssh.github.com_alice`. Because the alias now carries the
  `ssh.` prefix, `%n` is `ssh.github.com_alice`, so give the matching key
  that name too — create it as `ssh.github.com_alice@<device>` (or copy the
  key blob across to that filename).

## 5. SSH to your own machine (e.g. `homeserver`)

```bash
# Create a key for it (same pattern, no service prefix needed):
./bin/keycutter create homeserver@laptop

# Put the public key on the machine (any way you like):
ssh-copy-id -i ~/.ssh/keycutter/keys/homeserver@laptop.pub homeserver

ssh homeserver   # touch → you're in
```

Same magic: `keys/homeserver@laptop` is auto-selected for host `homeserver`.

## 6. Agent forwarding to that machine — done correctly

Forwarding lets programs on `homeserver` use keys held on **this** machine
(e.g. `git pull` from GitHub on homeserver with your key). Keycutter's
default is `ForwardAgent no` everywhere; you opt in per host.

```bash
# a) hold the GitHub key in your local agent (handle only; touch still guards every use)
ssh-add ~/.ssh/keycutter/keys/github.com_alice@laptop

# b) opt in for this one host — in ~/.ssh/keycutter/hosts/personal.conf:
#      Host homeserver
#        ForwardAgent yes

# c) use it
ssh homeserver
# ...on homeserver:
ssh -T git@github.com          # touch happens on YOUR machine → "Hi alice!"
git clone git@github.com:owner/repo.git
```

**macOS: make sure you `ssh-add` into a FIDO-capable agent.** A fresh Mac's
default `SSH_AUTH_SOCK` points at Apple's launchd ssh-agent, which can't
hold `sk` keys — `ssh-add` fails with `Error loading key ... invalid format`
or the key just never gets used. The Homebrew OpenSSH agent (the same one
`brew install openssh` gives you above) can:

```bash
echo "$SSH_AUTH_SOCK"                       # Apple's is under /private/tmp/com.apple.launchd...
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/keycutter/keys/github.com_alice@laptop
```

Linux's stock agent is fine as-is.

**The three rules that make this "correct":**

1. **Only forward to machines you trust** — while you're connected, root on
   `homeserver` can *use* (not copy) your agent keys. Every use still needs
   your physical touch, which is your tell.
2. **Just hopping through a bastion? Use `ProxyJump bastion`, not
   forwarding.** Forwarding is only for when the remote itself needs your key.
3. **If `homeserver` also runs the keycutter config** (`IdentitiesOnly yes`),
   drop the *public* half of the key on homeserver at
   `keys/<alias>@<homeserver's-own-hostname>` (bare filename, no `.pub`
   suffix) so the `%n@%L` line offers it there and the forwarded agent signs
   — proven empirically (live test against github.com, OpenSSH 10.3p1):

   ```bash
   scp ~/.ssh/keycutter/keys/github.com_alice@laptop.pub \
       homeserver:.ssh/keycutter/keys/github.com_alice@homeserver
   ```

   Hops that don't run the keycutter config need nothing at all — no env
   var, no extra step.

   **Symptom if you skip rule 3:** `Too many authentication failures`
   (the connection drops before you're asked to touch). On a hop running
   the keycutter config, `IdentitiesOnly yes` plus a missing
   `keys/<alias>@<hop-hostname>` public half means ssh can't match the
   forwarded key to a local `IdentityFile`, so it offers every key the
   forwarded agent holds and the server cuts you off at `MaxAuthTries`.
   Dropping the `.pub` on the hop (above) fixes it.

## Roaming / resident YubiKeys

A YubiKey that moves between machines needs one of three patterns (see
`ssh-config-explained.md` for the mechanics of why):

1. **Same handle, per-machine filenames** — the non-resident "private key"
   file is a machine-independent blob; copy the one file to each machine as
   `<alias>@<that-machine>`. One registered key on the service, works
   wherever the token is plugged in.
2. **Resident key** — `keycutter-create --resident ...` stores the handle
   on the token itself; regenerate the local file on any machine with
   `ssh-keygen -K` (`ssh-add -K` on some builds). True roaming, nothing to
   carry by hand.
3. **Token-named key + static stanza** — name the key
   `<alias>@keyring-yk5` and add a 3-line `Host` stanza in
   `hosts/personal.conf` (the fork-(b) escape hatch) so it isn't tied to
   any one `%L`. Travels with a synced tree.

---

## That's the whole system

- One directory of config (`~/.ssh/keycutter/`), included from `~/.ssh/config`
- One `ssh-keygen -t ed25519-sk` per identity, named `service_user@device`
  (`keycutter-create` does exactly this, plus keytag validation and perms)
- Keys route themselves by name; defaults keep keys private
  (`IdentitiesOnly yes`) and forwarding off unless you opt in

Everything else the full keycutter CLI does (agent profiles, SSH-over-SSM,
git signing, touch notifications, self-update) is deferred — see
`deferred-features.md` for each one's manual equivalent today.
