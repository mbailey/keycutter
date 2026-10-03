# Deferred and retired features

The minimal skill ships a curated slice of upstream keycutter
(`github.com/mbailey/keycutter`). Four capabilities are deliberately left
out for now — each for a stated reason, each with a manual equivalent you
can use today; if they return, they return as opt-in includes or reference
pages, never silently active. One more — agent profiles — has been
**retired** outright, superseded by a native OpenSSH mechanism (below).

## Agent profiles (retired — superseded by native constraints)

**What it was:** `agents/<profile>/` directories of symlinks into `keys/`,
activated per-host via `IdentityAgent`, so a laptop could forward only
`personal`-tagged keys to personal hosts and only `work`-tagged keys to
work hosts — least-privilege forwarding instead of all-or-nothing
`ForwardAgent yes`.

**Why it's gone:** OpenSSH 8.9 (2022) added **destination-constrained agent
keys** (`ssh-add -h`), which enforce "this key may only authenticate to
these hosts" in the agent itself — cryptographically, per hop, across a
forwarded socket. That is exactly what the profile directories were
approximating, done natively with no extra sockets to spawn or manage (and
without fighting OpenSSH 10.1's relocation of the agent socket). The
per-profile socket mechanism is retired, not deferred — it is not coming
back.

**Use this instead:** `references/constrained-forwarding.md` — the
`ssh-add -h` recipe, the forwarding-chain caveats, and the pre-8.9
fallback. For the simple "forward my whole agent to one trusted host" case,
opt in per host in `hosts/personal.conf` / `hosts/work.conf`
(`ForwardAgent yes`), as walked through in `fresh-machine.md` §6.

**Note on the `personal`/`work` key-selection rules still in those files:**
`hosts/personal.conf` / `hosts/work.conf` carry three `Match final tagged
personal|work exec "bash -c '[[ ... ]]'"` blocks each — a *working* (not
retired) mechanism, pre-dating fork (c), that offers a `personal`/`work`-named
key once you tag a host (`Host foo` / `Tag personal`, itself
commented-out-by-example today). These are read-only file-existence tests,
and — verified empirically — the `exec` never runs unless a host is actually
tagged: `ssh -G` against any untagged host fires zero `bash -c` calls, so a
fresh/default install has no shell execution from these files. Tagging a
host *does* start firing that host's three `exec` tests on every connection
to it (same cost profile as upstream, read-only). Not yet migrated to the
fork-(c) static-token style — a candidate follow-up for the `hosts/*.conf`
surface.

## SSH-over-SSM

**What it was:** `Match Host i-*,m-*` routed AWS instance-ID hosts through
`scripts/ssh-ssm`, which pushed a temporary RSA key via
`aws ssm send-command` and tunneled the session — no bastion, no open
port 22, works through AWS's control plane.

**Gate:** two security-review findings — the review's only
**High**-severity finding (`%r` root command injection in the
generated remote command), plus an over-broad
`StrictHostKeyChecking no`. Both need dedicated fixes upstream before this
ships again, even as opt-in.

**Manual equivalent today:** the AWS CLI's own SSM plugin —
`aws ssm start-session --target i-0123456789abcdef0`, or a manual
`ProxyCommand` line using `aws ssm start-session` per AWS's documented
pattern, scoped to the one host you need it for.

## Git commit/tag signing

**What it was:** `git-signing enable/disable/status` (the best-tested
code in upstream keycutter, 292 lines / 32 tests) auto-detected a signing
key from the remote URL's keytag and set it up for you.

**Gate:** none blocking — it's genuinely handy and cleanly implemented,
just disproportionate to ship as a script for what it actually does. A
candidate to return as a small script if demand shows.

**Manual equivalent today** — the three `git config` lines, using the
`.pub` file `keycutter-create` already minted:

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/keycutter/keys/github.com_alice@laptop.pub
git config --global commit.gpgsign true
```

(Drop `--global` to scope it to one repo. Don't forget to also
`gh ssh-key add --type signing ...` — see `fresh-machine.md` §3 — or
GitHub won't recognize the key for verification.)

## Touch notification

**What it was:** `install-touch-detector` +
`keycutter-touch-notify(-install)` (~950 lines combined) installed
`yubikey-touch-detector` (Linux) or `yknotify` via `go install @latest`
(macOS) plus a launchd plist and a `.wav`, so the OS pops a notification /
plays a sound whenever the key is waiting for a touch.

**Gate:** none blocking, but it's a parallel product with its own
installers and an unpinned `go install @latest` supply chain — out of
scope for the config-and-one-script shape of this skill. Real UX value
(you stop wondering whether it's hung or waiting), but it deserves its own
review, not a ride-along in keycutter-minimal.

**Manual equivalent today:** nothing built-in — watch the terminal, most
FIDO2 keys also blink/flash physically while waiting. Candidate: a
separate skill, pointed at from here once one exists.

## WSL

**What it was:** `scripts/ssh.bat` + `SSH_SK_HELPER` docs routed FIDO2
operations from WSL out to Windows OpenSSH (WSL itself typically can't
talk to a USB FIDO2 token directly).

**Gate:** none blocking — legitimate platform need, just docs-shaped
rather than script-shaped for a minimal skill.

**Manual equivalent today:** point `SSH_SK_HELPER` at Windows OpenSSH's
security-key middleware from inside WSL, per Microsoft's WSL + OpenSSH
FIDO2 documentation, and run `ssh-keygen`/`ssh` from WSL as normal once
that's wired. A platform-specific doc page is the right home for this if
WSL usage shows up — not written yet (no current WSL user driving it).
