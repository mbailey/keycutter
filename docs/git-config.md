# Git Configuration with Keycutter

Keycutter can automatically configure Git to use the correct SSH keys for different GitHub/GitLab accounts and organizations. This eliminates the need to manually specify SSH keys or manage complex `.ssh/config` entries.

## How It Works

Keycutter uses Git's `url.*.insteadOf` configuration to automatically rewrite repository URLs to use the correct SSH keytag. When you clone or push to a repository, Git will automatically use the right SSH key based on the account or organization.

## Quick Start

### 1. Scan and Configure Existing Keys

```bash
# Scan for Git service keys and set up configuration
keycutter git-config scan
```

This will find all your GitHub/GitLab/Bitbucket keys and offer to configure them interactively.

### 2. Add Account Mappings

Map accounts or organizations to specific SSH keys:

```bash
# Add an account to use a specific key
keycutter git-config add github.com_personal myusername
keycutter git-config add github.com_work mycompany
```

### 3. Activate in Git

Add this to your `~/.gitconfig` to enable all keycutter configurations:

```gitconfig
[include]
    path = ~/.ssh/keycutter/git-configs/*.gitconfig
```

## Commands

### `keycutter git-config scan`
Scans for SSH keys that look like Git service keys (e.g., `github.com_*`) and offers to set them up interactively.

### `keycutter git-config status`
Shows the current configuration status, listing all configured keys and their associated accounts.

### `keycutter git-config setup <keytag>`
Interactive setup for a specific key. Prompts you to enter the accounts/organizations that should use this key.

### `keycutter git-config add <keytag> <account>`
Adds an account or organization to a key's configuration. For example:
- `keycutter git-config add github.com_work mycompany` - Use work key for company repos
- `keycutter git-config add github.com_personal myusername` - Use personal key for personal repos

### `keycutter git-config generate <keytag>`
Regenerates the Git configuration file for a specific key. Useful after manually editing mapping files.

## How URL Rewriting Works

When you have a key `github.com_work` mapped to organization `mycompany`, keycutter generates:

```gitconfig
[url "git@github.com_work:mycompany/"]
    insteadOf = https://github.com/mycompany/
    insteadOf = git@github.com:mycompany/
```

This means:
- `git clone https://github.com/mycompany/repo` → Uses your work SSH key
- `git clone git@github.com:mycompany/repo` → Also uses your work SSH key
- The SSH connection actually goes to `git@github.com_work:mycompany/repo`

## File Structure

Keycutter stores Git configurations in `~/.ssh/keycutter/git-configs/`:

```
git-configs/
├── github.com_personal.mappings      # Accounts using personal key
├── github.com_personal.gitconfig     # Generated Git config
├── github.com_work.mappings          # Accounts using work key
└── github.com_work.gitconfig         # Generated Git config
```

- `.mappings` files list the accounts/organizations (one per line)
- `.gitconfig` files are auto-generated from the mappings

## Example Workflow

```bash
# 1. Create a new GitHub key for your work account
keycutter create github.com_work@laptop

# 2. Set up Git configuration for the key
keycutter git-config setup github.com_work@laptop
# Enter your company's GitHub organization name when prompted

# 3. Add the include to your ~/.gitconfig (one-time setup)
echo '[include]' >> ~/.gitconfig
echo '    path = ~/.ssh/keycutter/git-configs/*.gitconfig' >> ~/.gitconfig

# 4. Clone a work repository - automatically uses work key!
git clone https://github.com/mycompany/internal-repo
```

## Multiple Accounts Example

If you have personal projects and work projects on GitHub:

```bash
# Personal account
keycutter git-config add github.com_personal myusername
keycutter git-config add github.com_personal my-side-project-org

# Work account  
keycutter git-config add github.com_work mycompany
keycutter git-config add github.com_work mycompany-subsidiary

# Now these automatically use the right keys:
git clone https://github.com/myusername/personal-repo      # Uses personal key
git clone https://github.com/mycompany/work-repo          # Uses work key
```

## Troubleshooting

### Git still asks for username/password
Make sure you've:
1. Added the include to your `~/.gitconfig`
2. Set up the correct account mappings
3. Uploaded the SSH public key to GitHub/GitLab

### Wrong key being used
Check which key Git is using:
```bash
GIT_SSH_COMMAND="ssh -v" git fetch
```

Verify your mappings:
```bash
keycutter git-config status
```

### Changes not taking effect
Git configs are loaded when Git starts. If you've just made changes, new Git commands will use them automatically.

## Benefits

- **Automatic key selection** - No need to remember which key to use
- **Works with existing workflows** - Clone with HTTPS URLs as normal
- **No SSH config complexity** - Keycutter handles the SSH configuration
- **Per-organization control** - Different keys for different organizations
- **Easy to audit** - See all mappings with `git-config status`