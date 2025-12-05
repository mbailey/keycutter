# Git Commit Signing with Keycutter

Keycutter supports portable, per-identity git commit signing using SSH keys. This allows you to:

- Sign commits with the same key used for authentication
- Automatically use different identities for different projects
- Sync your signing configuration across multiple machines

## Quick Start

### During Key Creation

When you create a new GitHub key, keycutter offers to configure git signing automatically:

```shell
$ keycutter create github.com_alex

# ... key creation process ...
# If you upload the key to GitHub, keycutter will offer:

Set up git commit signing with this key? [Y/n] y
Enter your name for commits: Alex Smith
Enter your email for commits: alex@example.com
✓ Created identity config: ~/.ssh/keycutter/git/github.com_alex.conf
✓ Git commit signing configured
```

### For Existing Keys

```shell
# Create symlinks for portable key references
keycutter key link

# Create a git identity config
keycutter git-identity create github.com_alex --name "Alex Smith" --email "alex@example.com"

# Generate the master config with includeIf rules
keycutter git-config setup
```

## How It Works

### 1. Portable Key Symlinks

Machine-specific keys like `github.com_alex@laptop` get generic symlinks:

```
~/.ssh/keycutter/keys/
├── github.com_alex@laptop           # Real key (machine-specific)
├── github.com_alex@laptop.pub
├── github.com_alex -> github.com_alex@laptop     # Symlink
└── github.com_alex.pub -> github.com_alex@laptop.pub
```

Git config references the symlink, making it portable across machines.

### 2. Per-Identity Config Files

Each identity gets a config file in `~/.ssh/keycutter/git/`:

```ini
# ~/.ssh/keycutter/git/github.com_alex.conf
[user]
    name = Alex Smith
    email = alex@example.com
    signingkey = ~/.ssh/keycutter/keys/github.com_alex.pub

[gpg]
    format = ssh

[commit]
    gpgsign = true
```

### 3. Master Config with includeIf Rules

A master config applies identities based on repository location:

```ini
# ~/.ssh/keycutter/git/config
[includeIf "gitdir/i:~/Code/github.com/alex/"]
    path = ~/.ssh/keycutter/git/github.com_alex.conf

[includeIf "gitdir/i:~/Code/github.com/alexwork/"]
    path = ~/.ssh/keycutter/git/github.com_alexwork.conf
```

Your `~/.gitconfig` includes the keycutter config:

```ini
[include]
    path = ~/.ssh/keycutter/git/config
```

## Commands

### `keycutter setup`

Bootstrap command that runs `key link` to create portable symlinks.

### `keycutter key link`

Creates generic symlinks for machine-specific keys:

```shell
$ keycutter key link
Creating symlink: github.com_alex -> github.com_alex@laptop
Created 1 symlink(s), skipped 0 (already up to date)
```

Options:
- `--dry-run`: Show what would be created without making changes

### `keycutter git-identity create`

Creates a per-key identity config for git commit signing:

```shell
keycutter git-identity create <keytag> [--name <name>] [--email <email>]
```

If name/email not provided, you'll be prompted interactively.

### `keycutter git-identity list`

Lists all configured git identities:

```shell
$ keycutter git-identity list
Git identity configs:
  github.com_alex (alex@example.com)
  github.com_alexwork (alex@company.com)
```

### `keycutter git-config setup`

Generates the master git config with includeIf rules:

```shell
$ keycutter git-config setup
Keycutter Git Config Setup
==========================

Found identity: github.com_alex
Enter gitdir pattern (e.g., ~/Code/github.com/username/) or skip: ~/Code/github.com/alex/

Generated: ~/.ssh/keycutter/git/config

Add include to ~/.gitconfig now? [Y/n] y
Added include to ~/.gitconfig
```

### `keycutter git-signing`

Per-repository signing commands:

```shell
# Show current signing status
keycutter git-signing status

# Enable signing for current repository
keycutter git-signing enable

# Enable signing globally
keycutter git-signing enable --global

# Disable signing
keycutter git-signing disable
```

## Syncing Across Machines

The configuration in `~/.ssh/keycutter/git/` is portable because:

1. **Keys are referenced by generic symlink** - The config references `github.com_alex.pub`, not `github.com_alex@laptop.pub`
2. **Each machine creates its own symlinks** - Run `keycutter setup` on each machine to create the symlinks pointing to that machine's keys
3. **Same config, different keys** - The same identity config works on any machine where the key exists

### Setup on a New Machine

```shell
# 1. Install keycutter and create your key
keycutter create github.com_alex

# 2. Create symlinks and sync config
keycutter setup

# 3. Your git signing just works!
```

## Verifying Signed Commits

### On GitHub

Add your SSH public key as a **signing key** in GitHub settings:
1. Go to Settings → SSH and GPG keys
2. Click "New SSH key"
3. Select "Signing Key" as the key type
4. Paste your public key

Commits signed with this key will show as "Verified" on GitHub.

### Locally

```shell
# Verify a signed commit
git verify-commit HEAD

# Show signature info in log
git log --show-signature
```

## Troubleshooting

### Signing key not found

Make sure the symlink exists and points to your real key:

```shell
ls -la ~/.ssh/keycutter/keys/github.com_alex*
```

Run `keycutter key link` if the symlink is missing.

### Wrong identity used

Check which includeIf rule matches your repository:

```shell
git config --show-origin user.signingkey
```

Verify your repository path matches the gitdir pattern in the includeIf rule.

### Commits not showing as verified on GitHub

Ensure you've added the SSH key as a **signing key** (not just authentication) on GitHub.
