# SSH Host Configurations

NOTE: This file is named .README.md (with a leading dot) to prevent SSH from attempting
to parse it as configuration. SSH ignores hidden files when using Include directives.

The hosts directory contains custom SSH configuration files that are included into
the main SSH configuration. These files allow for host-specific settings that override
or supplement the default keycutter SSH configuration.

## PURPOSE

Host configuration files provide a modular way to define SSH behavior for specific hosts
or patterns of hosts. This separation allows for:

- Per-host authentication settings
- Custom proxy configurations
- Service-specific parameters
- Override of default keycutter behaviors

## STRUCTURE

Files in this directory are loaded via the Include directive in keycutter.conf:

    Include keycutter/hosts/*

Each file can contain standard SSH configuration directives for one or more Host patterns:

    hosts/
    ├── personal     # Personal servers and services
    └── work        # Work-related hosts

## CONFIGURATION

Example host configuration file content:

    # work
    Host *.corp.example.com
        User alice
        ForwardAgent yes
        IdentityAgent ~/.ssh/keycutter/agents/work/ssh-agent.socket
        ProxyJump bastion.corp.example.com

    Host gitlab.internal
        Port 2222
        IdentityFile ~/.ssh/keycutter/keys/gitlab.internal_alice@workstation
        IdentityAgent ~/.ssh/keycutter/agents/work/ssh-agent.socket

    # personal
    Host homelab-*
        User admin
        ForwardAgent yes
        IdentityAgent ~/.ssh/keycutter/agents/personal/ssh-agent.socket
        StrictHostKeyChecking no

## SECURITY BEST PRACTICES

### Using ProxyJump Instead of Agent Forwarding

When connecting through bastion hosts, prefer ProxyJump over SSH agent forwarding:

    # Secure connection through bastion (recommended)
    Host production-*.internal
        HostName %h
        User deploy
        ProxyJump bastion.example.com
        ForwardAgent no  # Keys aren't exposed to bastion

    # Less secure: bastion with agent forwarding
    Host bastion.example.com
        ForwardAgent yes  # Avoid when possible
        IdentityAgent ~/.ssh/keycutter/agents/work/ssh-agent.socket

    Host legacy-*.internal
        ProxyCommand ssh -W %h:%p bastion.example.com
        ForwardAgent yes  # Required for Git operations

ProxyJump benefits:

- Direct authentication to the final destination
- No key exposure to intermediate hosts
- Simpler configuration and better security isolation

Only use agent forwarding when necessary (e.g., Git operations on remote hosts).

## FILE NAMING

- Files are included in alphabetical order
- Hidden files (starting with '.') are excluded
- Symlinks are followed and included
- Only regular files are processed (directories are ignored)

## PRECEDENCE

SSH configuration follows a first-match-wins policy. Settings in host files loaded earlier take precedence over those loaded later, and all host files take precedence over the general settings in keycutter.conf.

Common patterns:

- Use numeric prefixes (00-global, 10-work, 20-personal) to control load order
- Group related hosts in single files
- Keep service-specific settings together

See ssh_config(5) for complete documentation of available configuration options.

