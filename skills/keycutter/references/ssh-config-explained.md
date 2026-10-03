# SSH config explained

`keycutter.conf` and its `Include`d files are short, but SSH config syntax
is murky in places. This page walks every kept line and says what it does
and why it's there. Read it alongside
`skills/keycutter/templates/keycutter/keycutter.conf`.

## The `Include` lines

```sshconfig
Include keycutter/hosts/*.conf
Include keycutter/controlmaster/*.conf
```

SSH processes `Include` files in place, in glob order, before continuing
the rest of `keycutter.conf`. Both directories own their own config so
each feature (host profiles, connection multiplexing) is self-contained —
see `hosts/README.md` and `controlmaster/README.md`. Both globs end in
`*.conf`, so the `README.md` in each directory is never read as config.

## The GitHub / Sourcehut `HostName` stanzas

```sshconfig
Host github.com*
  HostName github.com # Enable GitHub CLI to find a known host.

Host git.sr.ht*
  HostName git.sr.ht
```

`github.com_alice` isn't a real DNS name — it's a keycutter *alias*: the
account tag baked into the hostname so multiple GitHub identities can
coexist without per-repo config. `HostName github.com` is what makes SSH
actually dial `github.com` when you type `ssh github.com_alice` or
`git clone git@github.com_alice:owner/repo.git`. **This is load-bearing.**
Earlier revisions of the upstream template survived without it because a
global `ProxyCommand` stripped the alias suffix on every connection; the
minimal skill drops that `ProxyCommand` entirely (see
`deferred-features.md` → SSH-over-SSM and the dropped `ssh-vanilla`), so
this stanza is now the *only* thing that resolves the alias. Miss it and
every multi-account alias breaks with a DNS lookup failure.

## The `*github.com*` / `*git.sr.ht*` behaviour stanzas

```sshconfig
Host *github.com*
  User git
  ForwardAgent no    # GitHub doesn't need access to your ssh-agent.
  IdentitiesOnly yes # Don't expose random public keys to GitHub.com.
  RequestTTY no      # GitHub does not (intentionally) provide shell access.
```

Wider glob (`*github.com*` matches the bare host too) carrying the
account-agnostic defaults: always connect as `git`, never forward the
agent to GitHub (it doesn't need it — see "ForwardAgent vs ProxyJump"
below), never offer keys beyond the one selected (`IdentitiesOnly`, see
below), and don't request a TTY (GitHub's SSH endpoint is
auth/git-only — no shell). The two commented lines under it
(`HostName ssh.github.com` / `Port 443`) are GitHub's documented firewall
workaround; uncomment both if port 22 is blocked where you are. The
Sourcehut stanza is the same reasoning, one service over.

## The keytag-matching line — mechanics of fork (c)

```sshconfig
Host *
  IdentityFile ~/.ssh/keycutter/keys/%n@%L
  IdentitiesOnly yes
  ForwardAgent no
  SendEnv KEYCUTTER_ORIGIN
```

This is the whole of key selection. Two SSH config tokens do the work:

- **`%n`** — the `Host` alias exactly as you typed it (e.g.
  `github.com_alice`, `homeserver`). Not the resolved `HostName` — the alias.
- **`%L`** — the *local* machine's short hostname (`hostname -s`), i.e.
  the "device" half of a keytag.

So for `ssh github.com_alice` run from a machine called `laptop`, this line
expands to `IdentityFile ~/.ssh/keycutter/keys/github.com_alice@laptop`. If
that file exists, ssh offers it. If it doesn't, ssh's own
missing-`IdentityFile`-tolerance kicks in (`type -1` internally) and the
line is a **silent no-op** — no error, no shell execution, just "this
identity isn't available." Empirically confirmed live against github.com
(OpenSSH 10.3p1): an existing
key at the token path is selected and offered (`explicit`); a missing one
is skipped cleanly, auth proceeds to a normal `Permission denied` with
zero keys offered.

This is *why* the older `Match exec "bash -c '[[ -f ... ]]'"` guards
that upstream keycutter used are gone: they were doing by hand (a shell
subprocess, on every connection) exactly what SSH's native file-tolerance
already does for free. Dropping them is a straight security win — no
shell execution for key selection — with no loss of the
drop-a-key-in-and-it-works UX. `keycutter-create` names keys
`<keytag>@<hostname -s>` for exactly this reason (see
`fresh-machine.md`).

**Two costs, both documented inline in `keycutter.conf`:**

- **(i) The default `~/.ssh/id_*` fallback is suppressed on every host.**
  Configuring *any* `IdentityFile` for a host replaces SSH's built-in
  default list (`id_rsa`, `id_ecdsa`, `id_ecdsa_sk`, `id_ed25519`,
  `id_ed25519_sk`) rather than adding to it (confirmed T2). A legacy key
  that was never renamed into the keytag convention stops being offered
  anywhere until you either mint a keycutter-named key for it or add an
  explicit `IdentityFile ~/.ssh/id_ed25519` line yourself (e.g. in
  `hosts/personal.conf`, which loads before the `Host *` block and wins on
  first match). On an all-keycutter machine this costs nothing — arguably
  a privacy feature, since it means keycutter never sprays a legacy key at
  a host that never asked for it.
- **(ii) The device label must equal `hostname -s`.** `%L` is a native,
  static token — it can't read `$KEYCUTTER_ORIGIN` the way the old exec
  guards could. A custom device label (not your actual hostname) or a
  roaming YubiKey that needs a portable name doesn't fit this line; use
  the static-stanza escape hatch below instead.

### The escape hatch — fork (b), per-host static stanza

For the two cases above (legacy default-named keys on a given host,
custom device labels), add an explicit `Host` block ahead of `Host *` in
`hosts/personal.conf` or `hosts/work.conf`:

```sshconfig
Host somehost
  IdentityFile ~/.ssh/id_ed25519          # legacy key, not keytag-named
  # or:
  IdentityFile ~/.ssh/keycutter/keys/somehost_alice@custom-label
```

First-match-wins: a `Host` block in `hosts/*.conf` (loaded via `Include`
before `Host *`) takes precedence over the generic token line. This is
the only per-key config keycutter minimal ever asks you to write by hand
— everything else routes itself.

## `SecurityKeyProvider` — the Secure Enclave, whole machine

```sshconfig
Host *
  # SecurityKeyProvider /usr/lib/ssh-keychain.dylib
```

A key made with `keycutter create --authenticator secure-enclave` lives in
the Mac's Secure Enclave. The file at `keys/<keytag>` is only a handle; to
sign, ssh must call Apple's provider (`/usr/lib/ssh-keychain.dylib`)
instead of its built-in FIDO code. `SecurityKeyProvider` is that switch.

**Why whole machine, not per key:** ssh picks the provider per *host*,
not per key, and `Match exec` has no token for the chosen `IdentityFile`.
A per-key rule fails the moment a host reuses another key: it gets the
built-in provider, cannot sign, and falls back to a password. So the line
is one static line under `Host *`, and it stays zero-exec.

**The origin names the authenticator.** The template ships the line
commented. `keycutter install` uncomments it only on a Mac with the dylib
whose origin (`KEYCUTTER_ORIGIN`, default the host name) equals its host
name. Any other origin (e.g. `<host>-yk`), or not a Mac, keeps the
comment. Costs: on an Enclave Mac a YubiKey stops signing; and it is
decided at install, so re-run install after changing the origin. Check
it with `ssh -G <alias> | grep -i securitykeyprovider` (`internal` = the
built-in default, the dylib = the Enclave).

## `IdentitiesOnly yes`

Without this, SSH offers *every* key in your agent/default list to every
host until one is accepted — noisy, and it leaks "here are all my key
fingerprints" to any host you connect to (including ones that shouldn't
get to see them). With `IdentitiesOnly yes`, only the `IdentityFile`(s)
explicitly resolved for that `Host` block are offered. Combined with the
one-key-per-host-alias convention above, each connection offers exactly
one key.

## `ForwardAgent` vs `ProxyJump`

Two different problems that look similar:

- **`ForwardAgent yes`** relays your local `ssh-agent` socket to the
  remote host so a program *running on that host* can use your keys (e.g.
  `git pull` from GitHub while SSH'd into `homeserver`). The remote host can
  *use* your agent for the duration of the connection — every use still
  needs your physical touch on the FIDO2 key, but it's still a wider trust
  boundary than not forwarding. Forwarding is also **transitive**: a host
  you forward to can forward your agent onward, and nothing your origin sets
  can stop it. Bind the key to its intended destinations with `ssh-add -h`
  to make forwarding safe — see `references/constrained-forwarding.md`.
- **`ProxyJump bastion`** just routes your connection's bytes through an
  intermediate host on the way to the real destination — the bastion never
  sees your key material or your agent at all.

Default is `ForwardAgent no` everywhere (set once, in the `Host *` block).
Opt in per host only when the *remote* genuinely needs to make outbound
authenticated connections with your identity (`hosts/*.conf`, see
`fresh-machine.md` §6 for the full walk-through, including the
hop-machine pub-key-drop recipe). If you're just hopping
*through* a machine to reach another one, use `ProxyJump`, not
`ForwardAgent` — it's strictly narrower.

## `SendEnv KEYCUTTER_ORIGIN`

A single inert line: `SendEnv` only takes effect if the *server's* sshd
also has `AcceptEnv KEYCUTTER_ORIGIN` configured, which almost nothing
does by default. Kept for forward-compatibility with the static-stanza
escape hatch and any future dynamic-origin use, at zero cost when unused.

## ControlMaster — connection multiplexing tradeoff

`Include keycutter/controlmaster/*.conf` pulls in connection multiplexing
(reuse an authenticated TCP session across multiple SSH invocations, so a
FIDO2 touch made once covers several connections within the persist
window). It's a separate, self-contained feature directory — read
`controlmaster/README.md` for the config, the socket-permission and
session-piggyback tradeoffs, and how to opt individual hosts in or out.
Short version: convenience (fewer touches) traded for a widened window in
which an already-authenticated session can be reused by anything else
running as your user on the same machine. FIDO2 key material itself is
never at risk either way — the tradeoff is about session reuse, not key
theft.

## Agent profiles — retired

The old `agents/` directory and its `IdentityAgent`-per-profile mechanism
(fine-grained control over *which* keys a forwarded agent offers) has been
retired. Its goal — least-privilege forwarding — is now met natively by
destination-constrained agent keys (`ssh-add -h`, OpenSSH 8.9+), which the
agent enforces per hop even across a forwarded socket. See
`references/constrained-forwarding.md` and the retirement note in
`references/deferred-features.md`.
