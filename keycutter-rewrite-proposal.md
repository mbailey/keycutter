# Keycutter Rewrite Proposal: Simplified Version

## Executive Summary

Keycutter solves a real problem - managing multiple SSH identities with hardware keys - but its current complexity obscures its value. This proposal outlines a rewrite focused on immediate usability, clear benefits, and a 5-minute setup experience.

## Core Vision

**"Three keys to rule them all"** - Personal, Work, and Public zones that automatically organize your digital identity across all services.

## Key Improvements

### 1. Instant Value Proposition
- **Problem**: "I need different SSH keys for work and personal GitHub"
- **Solution**: `keycutter create` → done
- **Benefit visible in 2 minutes**: Can push to both accounts without configuration

### 2. Three-Zone Default
Instead of explaining complex keytags upfront, start with three intuitive zones:
- **Personal**: Your stuff (personal projects, home servers)
- **Work**: Company resources  
- **Public**: Open source contributions

### 3. One-Command Setup
```bash
# Install and setup in one line
curl -sSL https://keycutter.io/install | bash

# Creates:
# - ~/.ssh/keycutter/ structure
# - Three zone configs (personal, work, public)
# - Adds Include to ~/.ssh/config
# - Detects YubiKey and sets KEYCUTTER_ORIGIN
```

### 4. Simplified Commands
```bash
keycutter create              # Interactive setup for all three zones
keycutter create personal     # Create just personal key
keycutter create github       # Auto-detects zone from context
keycutter push <hostname>     # Deploy keys
keycutter zones              # Manage zone assignments
keycutter update             # Safe updates with GPG verification
```

## Quick Start Experience

### First 5 Minutes
```bash
# 1. Install (30 seconds)
curl -sSL https://keycutter.io/install | bash

# 2. Create your identity (2 minutes)
$ keycutter create
🔑 Welcome to Keycutter! Let's set up your SSH identity.
🔍 Detected YubiKey 5C Nano (Serial: 12345678)

Creating three security zones:
✓ Personal key (personal@yubikey-12345678)
✓ Work key (work@yubikey-12345678)  
✓ Public key (public@yubikey-12345678)

🎉 Setup complete! You can now:
- Clone with any GitHub URL - the right key is selected automatically
- SSH to any host - zone keys are applied based on your configuration

# 3. First success (30 seconds)
# Just copy and paste any GitHub URL!
$ git clone https://github.com/companyorg/internal-repo
Cloning into 'internal-repo'...
Hi alice-work! You've successfully authenticated with your work account.

$ git clone https://github.com/alice/personal-project  
Cloning into 'personal-project'...
Hi alice! You've successfully authenticated with your personal account.
```

## Architecture Simplifications

### 1. File Structure
```
~/.ssh/keycutter/
├── config           # Main SSH config (auto-generated)
├── zones/          # Zone definitions
│   ├── personal    # List of personal hosts/patterns
│   ├── work       # List of work hosts/patterns
│   └── public     # List of public hosts/patterns
├── keys/          # Your SSH keys
└── agents/        # Agent forwarding profiles
```

### 2. Zone Assignment
Instead of manual tagging in SSH config files, use simple text files with two sections:

`~/.ssh/keycutter/zones/personal`:
```
# SSH hosts - these hosts belong in this zone
*.home.lan
192.168.1.*
homeserver
nas

# Git services - these accounts/orgs belong in this zone
github.com/alice
github.com/alice-personal
gitlab.com/alice
```

`~/.ssh/keycutter/zones/work`:
```
# SSH hosts - these hosts belong in this zone
*.company.com
gitlab.internal
10.0.0.*
bastion.company.net

# Git services - these accounts/orgs belong in this zone
github.com/companyorg
github.com/company-devops
gitlab.com/company
bitbucket.org/companyteam
```

`~/.ssh/keycutter/zones/public`:
```
# SSH hosts - these hosts belong in this zone
# (usually empty for public zone)

# Git services - these accounts/orgs belong in this zone
github.com/alice-oss
github.com/opensource-project
gitlab.com/community-contrib
```

### 3. Auto-Detection
Keycutter intelligently detects context:
- Git remotes → determine if work/personal/public
- Current directory → check for .keycutter-zone file
- Hostname patterns → match against zone lists

### 4. Automatic Git URL Rewriting
Keycutter reads the Git service entries from zone files and generates appropriate Git URL rewrites:

```bash
# Keycutter parses zone files and generates ~/.gitconfig entries:

# From work zone file entry "github.com/companyorg"
[url "git@github.com_work:"]
    insteadOf = https://github.com/companyorg/
    insteadOf = git@github.com:companyorg/

# From personal zone file entry "github.com/alice"  
[url "git@github.com_personal:"]
    insteadOf = https://github.com/alice/
    insteadOf = git@github.com:alice/

# From work zone file entry "gitlab.com/company"
[url "git@gitlab.com_work:"]
    insteadOf = https://gitlab.com/company/
    insteadOf = git@gitlab.com:company/
```

This means users can:
- Define Git accounts in zone files, not gitconfig
- Copy any repository URL and it "just works"
- Never manually edit Git configuration
- Support any Git hosting service with the same pattern

## Documentation Strategy

### 1. Start with Why
Lead with problems it solves, not features:
- "Use multiple GitHub accounts without hassle"
- "Keep work and personal projects separate"
- "Hardware security without complexity"

### 2. Progressive Disclosure
- **README**: 5-minute quick start only
- **Guide**: Common workflows and patterns
- **Advanced**: Full keytag system, custom zones

### 3. Visual Examples
Include screenshots/asciinema of:
- The 5-minute setup
- Cloning from different accounts
- How zone selection works

## Implementation Plan

### Phase 1: Core Rewrite (Week 1-2)
- [ ] Simplified command parser
- [ ] Three-zone system
- [ ] Auto-detection logic
- [ ] GPG-signed updates

### Phase 2: Enhanced UX (Week 3)
- [ ] Interactive setup wizard
- [ ] Better error messages
- [ ] Progress indicators
- [ ] Success celebrations
- [ ] Git URL rewriting configuration
- [ ] GitHub org/username detection

### Phase 3: Migration Tools (Week 4)
- [ ] Import existing keys
- [ ] Convert old configs
- [ ] Compatibility layer

## Success Metrics

1. **Time to first success**: < 5 minutes
2. **Commands to remember**: ≤ 3
3. **Setup steps**: 1 (just install)
4. **User comprehension**: Immediate understanding of zones

## Marketing Improvements

### Tagline Options
- "Three keys to freedom: Personal, Work, Public"
- "Hardware SSH keys made simple"
- "Your digital identity, organized"

### Key Benefits (User Language)
1. **Multiple GitHub accounts** - Just copy URLs, no special syntax
2. **Uncopiable keys** - YubiKey security
3. **Zero configuration** - Automatic setup with Git integration
4. **Work/life separation** - Built-in boundaries
5. **No more github.com_work** - URLs work exactly as shown on GitHub

## Migration Path

For existing users:
```bash
keycutter migrate
# - Detects existing setup
# - Suggests zone assignments
# - Preserves all keys
# - Updates configuration
```

## Code Structure

### Simplified Architecture
```
keycutter
├── keycutter           # Main script (single file?)
├── lib/
│   ├── zones.sh       # Zone management
│   ├── keys.sh        # Key operations  
│   ├── config.sh      # SSH config generation
│   └── update.sh      # Self-update logic
└── templates/         # Config templates
```

### Design Principles
1. **Convention over configuration**
2. **Fail gracefully with helpful errors**
3. **Celebrate success** (emoji feedback)
4. **Progressive enhancement** (basic → advanced)

## Testing Strategy

### User Journey Tests
1. New user installs and creates first key
2. Existing SSH user adds keycutter
3. Multi-device setup flow
4. Zone reassignment workflow

### Technical Tests
- Zone detection accuracy
- SSH config generation
- Update security
- Key deployment

## Future Enhancements

Once core is solid:
1. **Git signing integration** - Auto-configure based on zones
2. **GPG key management** - Same zone model
3. **Cloud key backup** - Encrypted zone backups
4. **Team features** - Shared zone definitions

## Summary

This rewrite prioritizes:
- **Immediate usability** over feature completeness
- **Clear mental model** (three zones) over flexibility  
- **5-minute success** over documentation
- **Convention** over configuration

The goal: Make keycutter so simple that the README is almost unnecessary, yet powerful enough to handle complex enterprise setups.