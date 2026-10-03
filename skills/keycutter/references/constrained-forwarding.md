# Constrained agent forwarding

`ForwardAgent yes` hands a remote host the use of your **whole** local
agent — every key it holds, for the life of the connection. OpenSSH 8.9
(2022) added a sharper tool: **destination-constrained keys**. You bind an
agent key to the specific hop(s) it may authenticate to, and the agent
refuses to sign for anywhere else — even across a forwarded agent socket.

This is the modern replacement for the per-profile agent sockets keycutter
used to ship (`agents/<profile>/`): the kernel of that idea — "only these
keys, only for these hosts" — is now enforced by the agent itself, with no
extra sockets to spawn and manage, and no fight with OpenSSH 10.1's move of
the agent socket under `~/.ssh/agent`.

## The recipe

Add the key to your agent with a destination constraint (`-h`):

```bash
# May authenticate ONLY to homeserver:
ssh-add -h homeserver ~/.ssh/keycutter/keys/github.com_alice@laptop

# May reach homeserver, and from homeserver onward to github.com:
ssh-add -h homeserver -h 'homeserver>github.com' \
  ~/.ssh/keycutter/keys/github.com_alice@laptop
```

- Each `-h [user@]host` names a hop the key may be used **to** (from the
  origin — the machine running your agent).
- `-h 'A>B'` names an **onward** hop: a key on a forwarded agent may go from
  A to B. Chain these to describe the exact path
  (`-h hop1 -h 'hop1>hop2' -h 'hop2>github.com'`).
- Ask for a destination you didn't authorize and the agent **refuses to
  sign** — the connection fails closed rather than quietly using the key.

Hosts are identified by their **host keys**, looked up from your
`known_hosts`, so a hop has to be a host you already trust. Wildcard
patterns are allowed.

Two things gate this, and both matter:

- **Client version** — if your `ssh-add` rejects `-h` it predates 8.9;
  check with `ssh -V`.
- **Agent capability** — `ssh-add -Q` (OpenSSH 10.3+) asks the *running*
  agent which extensions it supports. The client can be current while the
  agent behind `$SSH_AUTH_SOCK` (gpg-agent, 1Password, Secretive, or an
  older forwarded agent) is not — and it's the **agent** that enforces the
  constraint. If `-Q` can't list the agent's extensions (or the agent
  refuses the query), don't trust `-h` to be honoured on that agent.

## Version caveat — constraints need 8.9 end-to-end

A constraint is only enforced by a hop whose **agent and sshd** understand
it. Every host along a forwarded path must run OpenSSH ≥ 8.9 (client *and*
server) or the guarantee is only as strong as the weakest hop: an older hop
uses the key as if it were unconstrained. Common long-lived hosts still
below 8.9:

| Platform | Bundled OpenSSH | Enforces constraints? |
|---|---|---|
| RHEL / Rocky / Alma 8 | 8.0 | No |
| RHEL / Rocky / Alma 9 | 8.7 | No |
| Ubuntu 20.04 LTS | 8.2 | No |
| Debian 11 (bullseye) | 8.4 | No |
| Ubuntu 22.04+ / Debian 12+ | ≥ 8.9 | Yes |

Through an older hop, fall back to a narrower control: forward only for the
one command that needs it, or drop the *public* key on the destination and
skip forwarding entirely (see `fresh-machine.md` §6, rule 3).

One honest limit even at 8.9+: a constraint stops a compromised hop from
using your key for an *unpermitted* destination, but it does **not** stop
that hop re-forwarding the socket onward to another *permitted* one. The
permitted set is the boundary — keep it as small as the task needs.

## Why the constraint matters — how forwarding chains actually behave

Forwarding is transitive, and that surprises people:

- **Chains work to arbitrary depth.** Forward to hop1, and if hop1 forwards
  onward to hop2 (`ssh -A hop2` there, or `ForwardAgent yes` in its config),
  your agent is reachable from hop2 too. Verified to depth 3.
- **Every hop opts in again.** Forwarding is not automatic down the chain —
  each *client* along the way must request it (`-A` or `ForwardAgent yes`).
  Your origin only controls the first hop.
- **The origin can't stop an onward hop.** Once a hop holds the forwarded
  socket, nothing you set at the origin prevents it forwarding further.
  Plain forwarding has no "one hop only" flag — a destination constraint is
  what gives you one.
- **Any hop's root can use (not copy) the agent.** While you're connected,
  root on an intermediate can sign with your agent — but only while you're
  connected, and (for a FIDO2 key) every signature still needs your physical
  touch back at the origin. The key material never leaves the hardware.
- **Touch-at-origin is the backstop, but only a backstop.** A hardware key
  can be *used* down the chain and never *exfiltrated*, and each use blinks
  the key for a touch — that's your tell. But it only tells you *after* a
  signature is requested.

Put together: chains happen whether you plan for them or not, the origin
can't police them, and touch only tells you after the fact — so the real
control is to constrain the key to its intended destinations up front.
