# Complete Keycutter Setup Guide

This guide walks you through setting up Keycutter with multiple GitHub accounts and automatic Git URL rewriting.

## Prerequisites

- A YubiKey or other FIDO2 security key (optional but recommended)
- Git installed on your system
- SSH client

## Step 1: Install Keycutter

```bash
# Clone the repository
git clone https://github.com/mbailey/keycutter.git
cd keycutter

# Install
./install.sh
```

## Step 2: Create Your First SSH Key

Let's create a key for your personal GitHub account:

```bash
keycutter create github.com_alice
```

During key creation:

1. **YubiKey Touch**: If using a YubiKey, you'll need to touch it when prompted
2. **GitHub Integration**: Keycutter will offer to add the key to your GitHub account
3. **SSH Port 443**: If your firewall blocks port 22, accept the symlink creation
4. **Git URL Rewriting**: NEW! Accept the offer to set up automatic URL rewriting

Example output:
```
Creating SSH key: github.com_alice@macbook
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/alice/.ssh/keycutter/keys/github.com_alice@macbook
Your public key has been saved in /Users/alice/.ssh/keycutter/keys/github.com_alice@macbook.pub

Git URL Rewriting Setup
========================
Keycutter can automatically configure Git to use this key for your GitHub repos.
This means you can use standard GitHub URLs (e.g., https://github.com/alice/repo)
and Git will automatically use the correct SSH key.

Set up automatic Git URL rewriting for github.com/alice? [Y/n] Y

Added user mapping: github.com/alice -> github.com_alice@macbook

To enable Git URL rewriting, add this to your ~/.gitconfig:

[include]
    path = ~/.ssh/keycutter/gitconfig

Add this include directive automatically? [Y/n] Y
Backed up ~/.gitconfig to ~/.gitconfig.keycutter-backup
✓ Added include directive to ~/.gitconfig

Git URL rewriting is now active! You can clone with:
  git clone https://github.com/alice/your-repo
And Git will automatically use the github.com_alice@macbook key.

Success! Setup complete for key: github.com_alice@macbook
```

## Step 3: Test Your Setup

### Test SSH Connection

```bash
ssh -T git@github.com_alice
# Output: Hi alice! You've successfully authenticated...
```

### Test Git URL Rewriting

Clone a repository using the standard GitHub URL:

```bash
git clone https://github.com/alice/my-private-repo
# Git automatically uses your github.com_alice key!
```

## Step 4: Add a Work Account

Now let's add your work GitHub account:

```bash
keycutter create github.com_work
```

During setup, when asked about Git URL rewriting, you can:
- Accept automatic setup for your work username
- Or manually add organization mappings later

## Step 5: Configure Organization Mappings

If your work account accesses multiple organizations:

```bash
# Add organization mapping
keycutter git-config add-org CompanyOrg github.com_work
keycutter git-config add-org ClientOrg github.com_work

# View all mappings
keycutter git-config show
```

## Step 6: Working with Multiple Accounts

### Automatic Key Selection

With Git URL rewriting configured, Git automatically selects the right key:

```bash
# Personal repo - uses github.com_alice key
git clone https://github.com/alice/personal-project

# Work repo - uses github.com_work key  
git clone https://github.com/CompanyOrg/internal-app

# Another work repo - also uses github.com_work key
git clone https://github.com/ClientOrg/client-project
```

### Manual Key Selection (When Needed)

You can still manually specify which key to use:

```bash
# Force using work key for a personal repo fork
git clone git@github.com_work:alice/company-fork
```

## Common Workflows

### Adding a New Organization

When you need to access a new organization with your work key:

```bash
keycutter git-config add-org NewOrg github.com_work
```

### Switching Keys for an Existing Repository

If you cloned a repo with the wrong key:

```bash
cd existing-repo
git remote set-url origin git@github.com_work:CompanyOrg/repo
```

### Checking Which Key Will Be Used

```bash
# Test URL rewriting
keycutter git-config test https://github.com/CompanyOrg/repo

# Or use Git's config
git config --get-urlmatch url.insteadof https://github.com/CompanyOrg/repo
```

## Advanced Configuration

### Default Key with Exceptions

Set a default key for all GitHub access, with specific exceptions:

1. Edit `~/.ssh/keycutter/git-mappings.conf`:
```
# Default to personal key
default|github.com|github.com_alice

# Exceptions for work
org|CompanyOrg|github.com_work
org|ClientOrg|github.com_work
```

2. Regenerate the configuration:
```bash
keycutter git-config setup
```

### Multiple Git Services

Keycutter supports multiple Git services:

```bash
# Create keys for different services
keycutter create gitlab.com_work
keycutter create bitbucket.org_personal

# Configure URL rewriting
keycutter git-config add-user gitlab.com workuser gitlab.com_work
keycutter git-config add-user bitbucket.org alice bitbucket.org_personal
```

## Troubleshooting

### Key Not Being Used

If the wrong key is being used:

1. Check your mappings:
```bash
keycutter git-config show
```

2. Verify the include is active:
```bash
git config --list | grep "include.path.*keycutter"
```

3. Test the URL:
```bash
GIT_TRACE=1 git clone https://github.com/alice/repo 2>&1 | grep "trace: run_command"
```

### Permission Denied

If you get "Permission denied (publickey)":

1. Ensure the key exists:
```bash
ls ~/.ssh/keycutter/keys/
```

2. Check SSH agent has the key:
```bash
ssh-add -l
```

3. Test the specific key:
```bash
ssh -T git@github.com_alice
```

### YubiKey Issues

If your YubiKey isn't working:

1. Check it's connected:
```bash
keycutter keys
```

2. Ensure SSH agent is running:
```bash
keycutter agents
```

3. Try removing and reinserting the YubiKey

## Best Practices

1. **Use Descriptive Keytags**: `github.com_companyname` is clearer than `github.com_work`

2. **Regular Key Rotation**: Periodically create new keys and remove old ones

3. **Backup Your Configuration**: 
```bash
cp -r ~/.ssh/keycutter ~/.ssh/keycutter.backup
```

4. **Document Your Mappings**: Keep a note of which organizations use which keys

5. **Use Hardware Keys**: YubiKeys provide the best security for your SSH keys

## Next Steps

- Set up [selective agent forwarding](selective-agent-forwarding.md) for jump hosts
- Configure [commit signing](https://docs.github.com/en/authentication/managing-commit-signature-verification) with your SSH keys
- Explore [advanced SSH configurations](advanced-ssh-config.md)

## Getting Help

- Run `keycutter help` for command reference
- Check the [troubleshooting guide](troubleshooting.md)
- Visit the [GitHub repository](https://github.com/mbailey/keycutter) for issues and updates