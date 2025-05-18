# SSH Agent Profiles

SSH Agent profiles enable fine-grained control over SSH Agent Forwarding. This implements the principle of least privilege by ensuring only necessary keys are made available to each remote system.

Each subdirectory under `~/.ssh/keycutter/agents/` represents a named profile containing symbolic links to SSH private keys.

If you enable an agent profile for a host, only the keys linked to that profile will be usable by the host.

## STRUCTURE

Each profile directory contains symbolic links to private keys from `~/.ssh/keycutter/keys/` directory:

    agents/
    ├── work/
    │   ├── gitlab.company.com@workstation -> ../../keys/gitlab.company.com@workstation
    │   └── deploy@workstation -> ../../keys/deploy@workstation
    └── personal/
        └── github.com@laptop -> ../../keys/github.com@laptop

## CONFIGURATION

Agent profiles are activated through the IdentityAgent directive in SSH configuration:

    Host *.company.com
        IdentityAgent ~/.ssh/keycutter/agents/work/ssh-agent.socket

    Host pather leopard cheetah
        IdentityAgent ~/.ssh/keycutter/agents/personal/ssh-agent.socket

When IdentityAgent specifies a directory containing SSH keys or symlinks, ssh-agent loads only those keys for the duration of the connection.

## SECURITY CONSIDERATIONS

SSH Agent Forwarding introduces security risks as it allows remote hosts to use your SSH keys. When connecting through bastion hosts, prefer SSH ProxyJump over agent forwarding.

For detailed examples and best practices, see [Security Best Practices](../hosts/README.md#security-best-practices) in the hosts documentation.

Agent forwarding should primarily be used when you need to:

- Clone or push to Git repositories from remote hosts
- Access services that require your SSH key from the remote host

Most other use cases can be handled more securely with ProxyJump.

## OPERATION

The keycutter SSH configuration uses a ProxyCommand that ensures the specified agent profile is loaded before establishing the connection. Keys are loaded into a separate agent instance to maintain isolation between different security contexts.

The agent writes a socket file to the agent profile directory which is referenced in ssh config for hosts that are configured to use this agent profile.

IMPORTANT: Keys specified in IdentityAgent are used only for SSH agent forwarding, not for the initial authentication from KEYCUTTER_ORIGIN. The initial connection uses keys specified via IdentityFile directives as defined in the main keycutter.conf:

- Initial authentication: Uses IdentityFile keys based on Match rules
- Agent forwarding: Uses IdentityAgent keys loaded into forwarded agent

This separation ensures that authentication keys and forwarded keys can be managed independently for enhanced security.

See ssh_config(5) for additional details on IdentityAgent behavior.
