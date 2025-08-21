# Git URL Rewriting Specification

## Overview
Implement automatic Git URL rewriting using Git's `insteadOf` configuration to eliminate the need for manual keytag specification in URLs. Users can clone/push with standard GitHub URLs, and Git will automatically rewrite them to use the appropriate SSH key via keycutter's keytag system.

## Problem Statement
Currently, users must manually specify keytags in URLs:
- `git clone git@github.com_work:company/repo.git`
- `git clone git@github.com_personal:myuser/repo.git`

This is:
- Non-intuitive for new users
- Different from standard GitHub URLs
- Error-prone (easy to use wrong key)
- Incompatible with copy-paste from GitHub

## Solution
Use Git's `url.<base>.insteadOf` configuration to automatically rewrite URLs based on patterns.

## Configuration Location Options

### 1. Global Config (~/.gitconfig) - RECOMMENDED
**Pros:**
- Single location for all projects
- User-specific (each user has their own keys)
- Easy to manage and backup
- Standard Git approach

**Cons:**
- Manual setup required
- Could conflict with existing configurations

### 2. System Config (/etc/gitconfig)
**Pros:**
- Works for all users on system

**Cons:**
- Requires root access
- Not portable
- Inappropriate for personal keys

### 3. Conditional Includes in Global Config
**Pros:**
- Can organize by directory/context
- More flexible

**Cons:**
- More complex setup
- Git 2.13+ required

### 4. Keycutter-Managed Config File
**Pros:**
- Full control over format
- Can be included from ~/.gitconfig
- Easy to regenerate/update

**Cons:**
- Requires include directive in ~/.gitconfig

## Proposed Implementation

### Approach: Keycutter-Managed Include File

1. Generate config file: `~/.ssh/keycutter/gitconfig`
2. User adds to `~/.gitconfig`: 
   ```
   [include]
       path = ~/.ssh/keycutter/gitconfig
   ```
3. Keycutter manages URL rewriting rules

### URL Rewriting Patterns

#### Pattern 1: Organization-Based (Work vs Personal)
```ini
# Work organizations
[url "git@github.com_work:CompanyOrg/"]
    insteadOf = https://github.com/CompanyOrg/
    insteadOf = git@github.com:CompanyOrg/
    insteadOf = ssh://git@github.com/CompanyOrg/

[url "git@github.com_work:AnotherWorkOrg/"]
    insteadOf = https://github.com/AnotherWorkOrg/
    insteadOf = git@github.com:AnotherWorkOrg/

# Personal account
[url "git@github.com_personal:myusername/"]
    insteadOf = https://github.com/myusername/
    insteadOf = git@github.com:myusername/
```

#### Pattern 2: Default Key with Exceptions
```ini
# Default to personal key for everything
[url "git@github.com_personal:"]
    insteadOf = https://github.com/
    insteadOf = git@github.com:

# Override for specific orgs (must come after default)
[url "git@github.com_work:CompanyOrg/"]
    insteadOf = https://github.com/CompanyOrg/
    insteadOf = git@github.com:CompanyOrg/
```

#### Pattern 3: Service-Based
```ini
# GitHub
[url "git@github.com_personal:"]
    insteadOf = https://github.com/
    insteadOf = git@github.com:

# GitLab
[url "git@gitlab.com_work:"]
    insteadOf = https://gitlab.com/
    insteadOf = git@gitlab.com:

# Bitbucket
[url "git@bitbucket.org_personal:"]
    insteadOf = https://bitbucket.org/
    insteadOf = git@bitbucket.org:
```

## User Configuration Flow

### Initial Setup
```bash
# 1. User creates keys
keycutter create github.com_personal
keycutter create github.com_work

# 2. Configure URL rewriting
keycutter git-config setup

# 3. System prompts for organization mappings
Which GitHub organizations use work key?
> CompanyOrg, AnotherOrg

Which is your personal GitHub username?
> myusername

# 4. Generate configuration
Created: ~/.ssh/keycutter/gitconfig
Add to ~/.gitconfig:
[include]
    path = ~/.ssh/keycutter/gitconfig
```

### Usage
```bash
# Clone with standard URLs - automatically uses correct key
git clone https://github.com/CompanyOrg/internal-repo
# Automatically rewritten to: git@github.com_work:CompanyOrg/internal-repo

git clone https://github.com/myusername/personal-project  
# Automatically rewritten to: git@github.com_personal:myusername/personal-project
```

## Commands

### New Commands
- `keycutter git-config setup` - Interactive setup wizard
- `keycutter git-config show` - Display current URL mappings
- `keycutter git-config add-org <org> <keytag>` - Add organization mapping
- `keycutter git-config remove-org <org>` - Remove organization mapping
- `keycutter git-config test <url>` - Test URL rewriting

### Integration with Existing Commands
- `keycutter create` - Optionally prompt to add URL rewriting
- `keycutter config` - Include git-config in regeneration

## Security Considerations

1. **Key Isolation**: URL rewriting maintains key isolation between accounts
2. **Explicit Mapping**: Only explicitly configured patterns are rewritten
3. **No Wildcards**: Avoid accidental key usage with specific patterns
4. **Audit Trail**: Log which key is used for each operation
5. **Override Capability**: Users can still manually specify keytags

## Migration Path

1. Detect existing manual keytag usage
2. Offer to convert to automatic rewriting
3. Preserve existing configurations
4. Provide rollback option

## Success Metrics

- Zero manual keytag specification needed
- Standard GitHub URLs work immediately
- Clear feedback on which key is being used
- No breaking changes to existing workflows

## Edge Cases

1. **Conflicting Patterns**: More specific patterns take precedence
2. **Multiple Accounts Same Org**: Require explicit subdirectory patterns
3. **Forked Repos**: Use parent organization's key
4. **New Organizations**: Prompt to configure on first use

## Example Configuration File

`~/.ssh/keycutter/gitconfig`:
```ini
# Generated by keycutter - DO NOT EDIT MANUALLY
# Regenerate with: keycutter git-config setup

# Work Organizations
[url "git@github.com_work:CompanyOrg/"]
    insteadOf = https://github.com/CompanyOrg/
    insteadOf = git@github.com:CompanyOrg/
    insteadOf = ssh://git@github.com/CompanyOrg/

[url "git@github.com_work:ClientOrg/"]
    insteadOf = https://github.com/ClientOrg/
    insteadOf = git@github.com:ClientOrg/

# Personal Account
[url "git@github.com_personal:myusername/"]
    insteadOf = https://github.com/myusername/
    insteadOf = git@github.com:myusername/

# Default fallback (optional)
[url "git@github.com_personal:"]
    insteadOf = https://github.com/
    insteadOf = git@github.com:
```