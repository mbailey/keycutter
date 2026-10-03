# keycutter — config tree

This is the **keycutter SSH config tree**. It lives in two places:

- In this repo, at `skills/keycutter/templates/keycutter/` — the *source*
  set of templates that `keycutter install` ships.
- On a configured machine, at `~/.ssh/keycutter/` — your *installed*
  copy, included from `~/.ssh/config` via:

  ```sshconfig
  Include keycutter/keycutter.conf
  ```

This README ships in both places so the tree is self-explanatory
wherever you encounter it. The "why does keycutter exist" question is
answered in the repo's top-level [`README.md`](../../../../README.md) and,
for agents, in [`SKILL.md`](../../SKILL.md).

## Layout

```text
keycutter.conf          # main SSH config: keytags, Match rules, defaults
hosts/
  personal.conf         # `personal` profile — agent socket + Match rules
  work.conf             # `work` profile — agent socket + Match rules
  README.md             # hosts/ explained
controlmaster/
  controlmaster.conf    # SSH ControlMaster (multiplexing) — reduces FIDO2 touches
  README.md             # ControlMaster explained
  sockets/              # ControlMaster runtime sockets — machine-local
keys/                   # YOUR FIDO2 SSH keys — minted on each machine,
                        #   never shipped in templates
```

Least-privilege agent forwarding is no longer a directory of profiles —
it's done natively with destination-constrained agent keys (`ssh-add -h`,
OpenSSH 8.9+). See `skills/keycutter/references/constrained-forwarding.md`.

This config tree ships no `scripts/` of its own -- the exec-based
ProxyCommand scripts (`ssh-agent-ensure`, `ssh-ssm`, `ssh-vanilla`,
`ssh.bat`, `sync-file-to-remote`) were dropped (zero-exec key selection,
see `keycutter.conf`); some return as opt-in includes later (see
`skills/keycutter/references/deferred-features.md`). The porcelain
scripts that build and install this tree (`keycutter-create`,
`keycutter-install`) live in the repo's `skills/keycutter/scripts/`
directory and are driven by the `keycutter` command — they are not part
of this installed tree.

Three feature directories follow the same pattern — each owns its config, its docs, and any runtime state it produces:

- `hosts/` — host-specific SSH config (per-context Host blocks).
- `controlmaster/` — connection multiplexing (config + runtime sockets).

## Installing / updating

The keycutter repo carries a `keycutter install` command (the
`keycutter-install` script) that copies templates into `~/.ssh/keycutter/`:

```bash
keycutter install --dry-run    # preview
keycutter install              # interactive — prompts on conflicts
keycutter install --force      # overwrite differing files
```

(`keycutter install` dispatches to the standalone
`skills/keycutter/scripts/keycutter-install` porcelain, which you can also
run directly by its path. `keycutter install` additionally offers to
symlink the `keycutter` command onto your `PATH`.)

For each template file:

- **missing at dest** — copied.
- **identical at dest** — skipped silently.
- **different at dest** — unified diff is shown and you're asked
  whether to overwrite. Default is to keep your version.

No file is overwritten without your consent unless you pass `--force`.

## What you'll edit on your machine

- `controlmaster/controlmaster.conf` — add your real hostnames to the
  `Host` line so ControlMaster multiplexing kicks in for them.
- `hosts/personal.conf` — replace the placeholder
  `Host laptop desktop homeserver` block with your own machines, add
  per-host config.
- `hosts/work.conf` — same idea, for work hosts.

The rest (`keycutter.conf`, the scripts, the per-directory READMEs)
is the framework — usually safe to leave alone.

## What's NOT in templates (and why)

- `keys/` — SSH keys are minted on the machine that will use them
  (FIDO2 keys are bound to a YubiKey). Templates can't supply them.
- `controlmaster/sockets/` (contents) — runtime sockets by definition.
  The directory itself ships as an empty `.gitkeep` placeholder so SSH
  has somewhere to write; the sockets that land inside it are gitignored.
