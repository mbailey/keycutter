# keycutter

Hardware-backed SSH, made legible.

**keycutter** is a small, auditable set of conventions and two short
scripts for running SSH with touch-gated keys (a FIDO2 YubiKey, or on a
Mac the Secure Enclave with Touch ID) across multiple accounts and
machines. It gives you a tidy `~/.ssh/keycutter/` config
tree, a one-command installer, and a key-minting helper — nothing you
can't read end to end in a sitting.

It is deliberately minimal. The goal is a setup a security-minded person
can fully understand before trusting it with their keys.

## Why

SSH config for hardware keys and multiple identities gets murky fast:
which key does a host use? What's forwardable where? keycutter answers
that with two ideas:

- **Keytags** — key files named `<service>_<user>@<machine>`
  (e.g. `github.com_alice@laptop`), so the SSH client routes the right
  key to the right host automatically, by name, with no per-account
  `Host` stanzas.
- **A standard tree** under `~/.ssh/keycutter/` — one `keycutter.conf`,
  per-context `hosts/*.conf`, and per-directory READMEs that explain
  every kept line. Included from your `~/.ssh/config` with one line.

Keys are hardware-backed and touch-required: `ed25519-sk` on a YubiKey,
or, **with no YubiKey, on a Mac**, a P-256 key made inside the Secure
Enclave that asks for Touch ID on every signature
(`keycutter create <keytag> --authenticator secure-enclave`). Either
way the private key file on disk is just a handle, useless without the
authenticator (for the Enclave: useless on any other Mac). Defaults keep keys private (`IdentitiesOnly
yes`) and agent forwarding **off** unless you opt in per host.

## Install

As a Claude Code plugin, from a clone of the `skill` branch (tested):

```bash
git clone -b skill https://github.com/mbailey/keycutter keycutter-skill
claude plugin marketplace add ./keycutter-skill
claude plugin install keycutter@keycutter
```

Or try it for one session only, installing nothing:
`claude --plugin-dir ./keycutter-skill`.

Or standalone — clone and put `bin/` on your PATH:

```bash
git clone -b skill https://github.com/mbailey/keycutter keycutter-skill
export PATH="$PWD/keycutter-skill/bin:$PATH"
```

## Quickstart

```bash
cd keycutter-skill

# 1. Install the config tree into ~/.ssh/keycutter/ (idempotent).
#    Prints a plan before touching anything; prompts on conflicts;
#    then offers to put the `keycutter` command on your PATH.
./bin/keycutter install --dry-run   # preview — writes nothing
./bin/keycutter install             # do it

# Wire it in. No ~/.ssh/config yet? Create it with:
#   Include keycutter/keycutter.conf
# Already have one? APPEND these two lines at its END (your settings keep
# priority; without `Match all` the Include hides inside your last Host):
#   Match all
#   Include keycutter/keycutter.conf

# 2. Mint a key for a host.
#    A Mac with no YubiKey: in the Secure Enclave, Touch ID per signature.
./bin/keycutter create github.com_alice --dry-run   # see the commands
./bin/keycutter create github.com_alice             # Touch ID
#    A YubiKey: touch it when it blinks.
./bin/keycutter create github.com_alice --authenticator yubikey

# 3. Upload the public key (paste the .pub at github.com -> Settings ->
#    SSH and GPG keys -> New SSH key), then round-trip:
ssh -T github.com_alice
```

`skills/keycutter/references/fresh-machine.md` walks the whole path —
fresh machine to working hardware-backed SSH — step by step, including
agent forwarding and roaming/resident-key recipes.
`TEST-ON-A-MAC.md` is the short Touch ID run against github.com.

### Secure Enclave keys: the origin names the authenticator

On a Mac with `/usr/lib/ssh-keychain.dylib`, an origin
(`KEYCUTTER_ORIGIN`, default the host name) **equal to the host name**
means the Secure Enclave:

- `keycutter install` uncomments one static line under `Host *` in
  `keycutter.conf`: `SecurityKeyProvider /usr/lib/ssh-keychain.dylib`.
  Whole machine, not per key (ssh picks the provider per host, not per
  key). No `Match exec`.
- `keycutter create` defaults to `--authenticator secure-enclave`: it runs
  `sc_auth create-ctk-identity` to mint a P-256 key in the Enclave with
  Touch ID protection, downloads its handle with
  `ssh-keygen -K -w /usr/lib/ssh-keychain.dylib`, and writes
  `keys/<keytag>` and `keys/<keytag>.pub`. `--dry-run` prints those
  commands and runs nothing.

Any other origin (`<host>-yk`), or not a Mac: no provider line, and keys
go on a YubiKey. **Cost:** with the line, a YubiKey stops signing on that
Mac, so a YubiKey owner sets `KEYCUTTER_ORIGIN=<host>-yk` before
installing. **Decided at install:** after changing the origin, run
`keycutter install` again. `create` refuses with the screen locked, the
lid closed (no Touch ID), or an Enclave identity of the same label.

## Remove it afterwards

A lab install is meant to come out cleanly. Run these yourself, in your
own terminal. Three parts, in this order:

```bash
# 1. The key in the Secure Enclave (Touch ID keys only).
sc_auth list-ctk-identities                 # your keytag is in the Label column;
                                            # the hex on its row (Public Key Hash) is <hash>
sc_auth delete-ctk-identity -h <hash>

# 2. The files it made. Your keys first:
rm ~/.ssh/keycutter/keys/github.com_alice@<device>{,.pub}
#    If keycutter install CREATED ~/.ssh/keycutter (you had none before):
rm -rf ~/.ssh/keycutter
#    then delete the `Include keycutter/keycutter.conf` line (and a `Match all`
#    you added with it) from ~/.ssh/config,
#    and the command symlink if you accepted it:
rm -f ~/.local/bin/keycutter

# 3. The plugin (this also uninstalls it), and the clone.
claude plugin marketplace remove keycutter
rm -rf ./keycutter-skill
```

Also delete the public key from GitHub (Settings → SSH and GPG keys). Deleting the Enclave
identity in step 1 already makes the key unusable everywhere.

## The command

`keycutter` is a thin busybox dispatcher (`bin/keycutter`, repo root) over
two standalone porcelain scripts, each readable on its own:

| Command | Script | Does |
|---|---|---|
| `keycutter install` | `skills/keycutter/scripts/keycutter-install` | copy templates into `~/.ssh/keycutter/`, idempotently; offer a `~/.local/bin` symlink |
| `keycutter create`  | `skills/keycutter/scripts/keycutter-create`  | mint one keytag-named key: `ed25519-sk` on a YubiKey, or `--authenticator secure-enclave` (Touch ID); `--dry-run` prints the commands |

Either script also runs directly by its path — the command just execs
them.

## Security model

The whole point is auditability:

- **Read it all.** Two short bash scripts plus config templates. No
  curl-pipe-bash, no hidden network calls, no build step. Install is
  `git clone` + running a script you've read.
- **Nothing acts without consent.** `keycutter install` prints its full
  plan and prompts before writing; the `~/.local/bin` symlink is
  *offered*, never created silently, and it never overwrites an existing
  command. Anything that touches `~/.ssh/` is verifiable by reading the
  script.
- **Hardware-gated.** Keys are `ed25519-sk` on a YubiKey or P-256 in the
  Mac's Secure Enclave; every use needs a physical touch (or Touch ID).
  `keycutter create` refuses rather than silently falling back to a
  software key.
- **Least privilege by default.** `IdentitiesOnly yes`, forwarding off
  unless opted in per host, and connection multiplexing shipped inert.
  `skills/keycutter/references/` documents the tradeoffs (agent forwarding
  chains, destination-constrained keys, `ProxyJump`) honestly.

## Relationship to upstream keycutter

The original, fuller keycutter CLI lives on the `master` branch of
[github.com/mbailey/keycutter](https://github.com/mbailey/keycutter) —
more features, more surface; this skill is the `skill` branch of the
same repo. **That project stands.** This is a
deliberately minimal subset focused on one thing done readably:
getting a fresh machine to working, hardware-backed SSH. It draws on the
upstream tool's ideas and conventions; it does not replace it.

## Layout

```text
bin/keycutter                  the keycutter command (thin busybox dispatcher)
.claude-plugin/                plugin.json, marketplace.json (Claude Code plugin metadata)
skills/keycutter/SKILL.md      the skill definition (Claude Code discovers this)
skills/keycutter/scripts/      keycutter-install, keycutter-create (porcelain)
skills/keycutter/templates/    the config tree that gets installed
skills/keycutter/references/   why keycutter exists and what each line does
skills/keycutter/test/         bats tests for the scripts
Makefile                       `make check` — shellcheck + bats
TEST-ON-A-MAC.md               make and use one Touch ID key against github.com
```

## Contributing / running the tests

```bash
make check      # shellcheck the scripts + run the bats suite
make test       # just the bats suite
make shellcheck # just the linter
```

## Licence

AGPL-3.0-or-later. See [`LICENSE`](LICENSE).
