---
name: keycutter
description: >-
  Keycutter — touch-gated SSH keys (YubiKey, or a Mac's Secure Enclave
  with Touch ID) and a sane multi-account `~/.ssh/keycutter/` config
  tree. Use when setting up SSH on a fresh machine with hardware-backed
  keys, making an SSH key that needs a touch for every signature (with
  or without a YubiKey), configuring per-host agent forwarding, or
  making the murky region of SSH config legible. Carries template
  config files, a `keycutter` command (install + key creation), and
  explanatory references.
---

# keycutter

## What keycutter is

A small set of conventions for SSH on machines that use hardware-backed
keys: a FIDO2 security key (YubiKey), or on a Mac, the Secure Enclave
with Touch ID:

- **Keytags** — SSH key files named `<service>_<username>@<machine>`
  (e.g. `github.com_alice@laptop`) so that one user can have many keys
  routed automatically by the SSH client.
- **Least-privilege agent forwarding** — when you must forward your agent,
  bind a key to the hosts it may reach with `ssh-add -h` (destination
  constraints, OpenSSH 8.9+), so a forwarded key can't be used for anything
  you didn't authorize (see `references/constrained-forwarding.md`).
- **A standard tree** under `~/.ssh/keycutter/` containing
  `keycutter.conf` (the main config), `hosts/*.conf` (per-context
  host blocks), and `controlmaster/`.

## What this skill is

This skill *is* keycutter. It carries:

- **Template config files** — `keycutter.conf`, `hosts/*.conf`,
  `controlmaster/`, and the per-directory READMEs that explain them.
- **A `keycutter` command** — a thin front-door dispatcher
  (`bin/keycutter`, at the repo root) over standalone per-verb porcelain
  scripts, each composable and readable on its own (Linus-git style):
  - `keycutter install` (`scripts/keycutter-install`) — copies templates
    into `~/.ssh/keycutter/` idempotently, with `--dry-run`, `--force`,
    and interactive diff-on-conflict prompts, then offers to put the
    `keycutter` command on your `PATH`.
  - `keycutter create` (`scripts/keycutter-create`) — mints one
    touch-gated SSH key, keytag-named: a FIDO2 `ed25519-sk` key on a
    YubiKey (default), or with `--authenticator secure-enclave` a P-256
    key inside the Mac's Secure Enclave, Touch ID on every signature.
    Validates the keytag, offers a device suffix, `--dry-run` prints the
    exact commands, and it refuses rather than silently falling back to
    a software key. Mutates no SSH config — key selection is a static
    `IdentityFile` token line in `keycutter.conf`; on an Enclave Mac,
    install writes one static `SecurityKeyProvider` line there (see
    `references/ssh-config-explained.md`).
- **Explanatory docs** — references that explain *why* keycutter exists,
  what each piece of SSH config is doing, and how the host / key tree
  maps to real workflows.

## Install

As a Claude Code plugin, from a clone of the `skill` branch (the tested
path):

```bash
git clone -b skill https://github.com/mbailey/keycutter keycutter-skill
claude plugin marketplace add ./keycutter-skill
claude plugin install keycutter@keycutter
```

Remove it afterwards: `claude plugin marketplace remove keycutter` (this
also uninstalls the plugin), then delete the clone. The keys and config
it made are separate: see the top-level `README.md`, "Remove it
afterwards".

Or standalone — clone and put `bin/` on your PATH:

```bash
git clone -b skill https://github.com/mbailey/keycutter keycutter-skill && export PATH="$PWD/keycutter-skill/bin:$PATH"
keycutter install --dry-run   # dispatches to skills/keycutter/scripts/keycutter-install
```

`bin/keycutter` is a small busybox dispatcher: `keycutter <verb> …` runs
the sibling `keycutter-<verb>` script under `skills/keycutter/scripts/`.
One verb per file — no internal subcommand switch — so adding a
capability is adding a file.

## Running the command (agents: read this)

From an installed plugin the command is **`"${CLAUDE_PLUGIN_ROOT}/bin/keycutter"`**.
Use that full path: the plugin's `bin/` is not on the user's `PATH`, and
a relative `./bin/keycutter` only works from inside a clone. Below,
`KC` stands for it:

```bash
KC="${CLAUDE_PLUGIN_ROOT}/bin/keycutter"
```

When you hand the user a command to run in their terminal, write the path
out in full (`${CLAUDE_PLUGIN_ROOT}/bin/keycutter`, as this page shows it
to you): `$KC` and `CLAUDE_PLUGIN_ROOT` are not set in their shell.

## Rules for the agent (read before running anything)

The point of this skill is to keep your agent away from your keys. So:

- **Never run `install` or `create` unasked.** Offer; the user decides.
- **`create` runs in the user's own terminal, never in your Bash tool.**
  It needs a touch or Touch ID and may ask a question; with no terminal it
  refuses. Show the exact command (`--dry-run` is safe for you to run)
  and ask the user to run the real one.
- **`install` likewise:** run `--dry-run` yourself if useful; the user
  runs the real install in their terminal. **Never `--force`.**
- **Never `gh ssh-key add`**, and never `gh auth refresh -s admin:public_key`
  (that widens the user's GitHub token). Print the command or point at
  GitHub's Settings page; the user uploads the public key.
- **Never read `~/.ssh/keycutter/keys/*`** (beyond listing names). Never
  set `KEYCUTTER_ALLOW_NO_TTY`: it exists for the test suite.

## Choose the authenticator first

**No YubiKey on a Mac means the Secure Enclave.** Most people have no
YubiKey. Check before suggesting anything:

```bash
uname -s                                   # Darwin = a Mac
ls /usr/lib/ssh-keychain.dylib             # Apple's SSH signer (recent macOS)
command -v sc_auth                         # mints Secure Enclave keys
ioreg -p IOUSB -l | grep -i yubikey        # any output = a YubiKey is plugged in
echo "${KEYCUTTER_ORIGIN:-unset} $(hostname -s)"   # the origin, and the host name
```

**The origin names the authenticator.** `KEYCUTTER_ORIGIN` defaults to
the host name (`hostname -s`). On a Mac with Apple's provider:

- **origin = host name** (the default): the **Secure Enclave**. The key is
  made inside the Mac's Secure Enclave and never leaves it; every
  signature asks for Touch ID. `keycutter install` writes
  `SecurityKeyProvider /usr/lib/ssh-keychain.dylib` under `Host *` in
  `keycutter.conf`, for the whole machine, and `keycutter create`
  defaults to the Enclave. This is the suggestion for a lab attendee.
- **any other origin** (e.g. `<host>-yk`): a security key (YubiKey). No
  provider line; `create` defaults to `ed25519-sk`.
- **Not a Mac:** a YubiKey, or nothing. keycutter makes no software keys.

**The cost, say it out loud:** with that line, a YubiKey (`-sk` key file)
**stops signing on that Mac**, because ssh picks one provider per host,
not per key. A YubiKey owner on a Mac sets `KEYCUTTER_ORIGIN=<host>-yk`
before installing, or skips the Enclave. **It is decided at install
time:** after changing the origin, run `keycutter install` again.

```bash
"$KC" create github.com_alice --authenticator secure-enclave --dry-run   # you may run this: prints the exact sc_auth / ssh-keygen commands
"$KC" create github.com_alice --authenticator secure-enclave             # the USER runs this, in their terminal; Touch ID
```

The Enclave key lands as `~/.ssh/keycutter/keys/<keytag>` (a handle,
useless on any other Mac) and `<keytag>.pub`. Refusals to expect: screen
locked, lid closed (no Touch ID), an Enclave identity with the same label
already exists. A failure no YubiKey can explain? Suggest
`--authenticator secure-enclave`, not `brew install openssh`.

## Quickstart

Three steps take a fresh machine to a working, hardware-backed SSH key:
install the config tree, cut a key, test it. **The user runs these in
their own terminal**; you show them.

```bash
# 1. Install — copy templates into ~/.ssh/keycutter/ (idempotent).
"$KC" install --dry-run   # show the plan, write nothing
"$KC" install             # write it (prompts on conflicts)
# then wire it in. Without this, `ssh github.com_alice` fails on DNS.
#   No ~/.ssh/config yet: create it with this one line:
#     Include keycutter/keycutter.conf
#   Already have one: APPEND these two lines at the END, so your own
#   settings keep priority (ssh takes the first value it reads). The
#   `Match all` matters: without it the Include lands inside your last
#   Host block and silently does nothing for other hosts.
#     Match all
#     Include keycutter/keycutter.conf

# 2. Create — mint a key for a host, keytag-named
#    <service>_<username>[@device]. No device suffix given -> you're
#    offered <keytag>@$(hostname -s).
"$KC" create github.com_alice                                  # a Mac whose origin is its host name: the Enclave
"$KC" create github.com_alice --authenticator yubikey          # a YubiKey

# 3. Upload the public key: paste ~/.ssh/keycutter/keys/github.com_alice@<device>.pub
#    at github.com -> Settings -> SSH and GPG keys -> New SSH key.
#    Then round-trip (Touch ID, or touch the YubiKey):
ssh -T github.com_alice
```

**Roll back the config:** delete the `Include keycutter/keycutter.conf`
line (and a `Match all` you added with it) from `~/.ssh/config`, then remove `~/.ssh/keycutter` (if keycutter
created it). Full removal, Enclave identity included: the top-level
`README.md`, "Remove it afterwards".

`ssh -G github.com_alice` shows what SSH resolved without connecting —
useful for checking `hostname`, `identityfile`, `identitiesonly` and
`securitykeyprovider` (the dylib = the Enclave) before anyone touches a key. `references/fresh-machine.md`
walks the YubiKey round-trip end to end (prerequisites, agent forwarding
to your own machines, resident/roaming YubiKey recipes).

> `keycutter install` / `keycutter create` are the front door. Each verb
> also runs standalone as `skills/keycutter/scripts/keycutter-install` /
> `skills/keycutter/scripts/keycutter-create` if you'd rather call the
> porcelain directly — the `keycutter` command just execs them.

## Where things live

- `bin/keycutter` (repo root) — the `keycutter` command: a thin busybox
  dispatcher over the per-verb scripts below it.
- `templates/` — example versions of every shippable config file.
- `scripts/keycutter-*` — porcelain commands (`keycutter-install`,
  `keycutter-create`), each runnable on its own.
- `test/` — bats tests for the scripts (`test/keycutter-create.bats`).
- `references/` — explanatory pages:
  - [`references/fresh-machine.md`](references/fresh-machine.md) —
    fresh machine to working FIDO2 SSH, step by step (install, create,
    test, agent forwarding, roaming/resident-key recipes).
  - [`references/ssh-config-explained.md`](references/ssh-config-explained.md) —
    what every kept line in `keycutter.conf` does and why (keytag
    matching, `IdentitiesOnly`, `ForwardAgent` vs `ProxyJump`,
    `ControlMaster`).
  - [`references/deferred-features.md`](references/deferred-features.md) —
    what was cut from upstream and why, each with its manual
    equivalent today (agent profiles — retired in favour of native
    destination constraints — SSH-over-SSM, git signing,
    touch-notify, WSL).

## Upstream

The full keycutter CLI lives on the `master` branch of
[mbailey/keycutter](https://github.com/mbailey/keycutter) (this skill is
its `skill` branch) — the original,
more featureful implementation this skill draws from. That project
stands; this is a deliberately minimal, security-auditable subset
(fresh-machine SSH with hardware-backed keys), packaged to be read
end-to-end. See the top-level [`README.md`](../../README.md) for how the
two relate.
