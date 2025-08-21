# Git URL Rewriting

Keycutter can automatically configure Git to use the correct SSH key based on the repository you're accessing. This eliminates the need to manually specify keytags in URLs.

## How It Works

When you create a GitHub key with keycutter, it can automatically set up Git URL rewriting. This means you can use standard GitHub URLs like:

```bash
git clone https://github.com/username/repo
```

Instead of the keytag format:

```bash
git clone git@github.com_username:username/repo
```

Git will automatically rewrite the URL to use the correct SSH key.

## Automatic Setup

When creating a new GitHub key, keycutter will:

1. Detect your GitHub username from the keytag
2. Offer to set up automatic URL rewriting
3. Add the necessary configuration to `~/.ssh/keycutter/gitconfig`
4. Optionally add an include directive to your `~/.gitconfig`

Example:
```bash
$ keycutter create github.com_alice

# After key creation, you'll see:
Git URL Rewriting Setup
========================
Keycutter can automatically configure Git to use this key for your GitHub repos.
This means you can use standard GitHub URLs (e.g., https://github.com/alice/repo)
and Git will automatically use the correct SSH key.

Set up automatic Git URL rewriting for github.com/alice? [Y/n]
```

## Manual Setup

You can also set up Git URL rewriting manually:

```bash
# Interactive setup wizard
keycutter git-config setup

# Add specific organization mapping
keycutter git-config add-org CompanyOrg github.com_work

# Add user mapping
keycutter git-config add-user github.com alice github.com_alice

# Show current mappings
keycutter git-config show

# Test URL rewriting
keycutter git-config test https://github.com/alice/repo
```

## Configuration Files

### Git Mappings (`~/.ssh/keycutter/git-mappings.conf`)

This file stores your URL rewriting rules:

```
# Format: <pattern_type>|<pattern>|<keytag>
user|alice|github.com_alice
org|CompanyOrg|github.com_work
```

### Generated Git Config (`~/.ssh/keycutter/gitconfig`)

Keycutter generates Git configuration based on your mappings:

```ini
# User: alice
[url "git@github.com_alice:alice/"]
    insteadOf = https://github.com/alice/
    insteadOf = git@github.com:alice/
    insteadOf = ssh://git@github.com/alice/

# Organization: CompanyOrg
[url "git@github.com_work:CompanyOrg/"]
    insteadOf = https://github.com/CompanyOrg/
    insteadOf = git@github.com:CompanyOrg/
```

### Including in Git Config

Add this to your `~/.gitconfig` to enable URL rewriting:

```ini
[include]
    path = ~/.ssh/keycutter/gitconfig
```

## Benefits

- **Simpler URLs**: Use standard GitHub URLs everywhere
- **Automatic key selection**: Git automatically uses the correct SSH key
- **Copy-paste friendly**: URLs from GitHub work without modification
- **Reduced errors**: No need to remember which key to use

## Troubleshooting

### Check if URL rewriting is active

```bash
# Test a URL to see how it will be rewritten
git config --get-urlmatch url.insteadof https://github.com/alice/repo

# Show all URL rewriting rules
git config --list | grep insteadof
```

### Verify the include is working

```bash
# Check if keycutter config is included
git config --list | grep "include.path.*keycutter"
```

### Debug URL rewriting

```bash
# See what Git will actually use
GIT_TRACE=1 git clone https://github.com/alice/repo
```

## Security Considerations

- URL rewriting maintains key isolation between accounts
- Only explicitly configured patterns are rewritten  
- You can still manually specify keytags when needed
- The configuration is user-specific and stored in your home directory