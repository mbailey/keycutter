#compdef keycutter

# Zsh completion for keycutter
# Install: Copy to a directory in your $fpath and run: compinit

_keycutter_gpg_fingerprints() {
  local fingerprints
  fingerprints=(${(f)"$(gpg --list-keys --keyid-format long 2>/dev/null | grep -E '^      [A-F0-9]{40}$' | tr -d ' ')"})
  _describe 'fingerprint' fingerprints
}

_keycutter_gpg_yubikey_serials() {
  local registry_file="$HOME/.config/keycutter/gpg-yubikeys.json"
  if [[ -f "$registry_file" ]] && command -v jq &>/dev/null; then
    local serials
    serials=(${(f)"$(jq -r 'keys[]' "$registry_file" 2>/dev/null)"})
    _describe 'serial' serials
  fi
}

_keycutter_ssh_keys() {
  local key_dir="$HOME/.ssh/keycutter/keys"
  if [[ -d "$key_dir" ]]; then
    local keys
    keys=(${(f)"$(ls -1 "$key_dir" 2>/dev/null | grep -v '\\.pub$' | grep -v '^\\..*')"})
    _describe 'key' keys
  fi
}

_keycutter_ssh_agents() {
  local agent_dir="$HOME/.ssh/keycutter/agents"
  if [[ -d "$agent_dir" ]]; then
    local agents
    agents=(${(f)"$(ls -1 "$agent_dir" 2>/dev/null | grep -v '^\\..*')"})
    _describe 'agent' agents
  fi
}

_keycutter_ssh_hosts() {
  local hosts
  hosts=(${(f)"$(grep -h '^Host ' "$HOME/.ssh/config" "$HOME/.ssh/keycutter/keycutter.conf" "$HOME/.ssh/keycutter/hosts"/*.conf 2>/dev/null | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '\\*' | sort -u)"})
  _describe 'host' hosts
}

_keycutter_gpg_key() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$words[4]" in
    list)
      _arguments \
        '--all[Also show master keys from backup locations]'
      ;;
    create)
      _arguments \
        '--identity[User ID (Name <email>)]:identity:' \
        '--key-type[Algorithm]:type:(ed25519 rsa4096)' \
        '--expiration[Subkey expiration period]:expiration:(1y 2y 3y 5y)' \
        '--master-expiration[Master key expiration]:expiration:(0 1y 2y 5y)' \
        '--passphrase[Passphrase for key protection]:passphrase:' \
        '--master-only[Create only the Certify master key]' \
        '--subkeys[Add subkeys to existing master]' \
        '--fingerprint[Master key fingerprint]:fingerprint:_keycutter_gpg_fingerprints' \
        '(-y --yes)'{-y,--yes}'[Non-interactive mode]'
      ;;
    install)
      _arguments \
        '--backup[Path to encrypted backup]:file:_files -g "*.tar.gz.gpg"' \
        '--backup-pass[Passphrase for backup decryption]:passphrase:' \
        '--passphrase[Key passphrase for operations]:passphrase:' \
        '--admin-pin[YubiKey admin PIN]:pin:' \
        '--force[Overwrite existing keys on YubiKey]' \
        '--label[Label for the YubiKey]:label:' \
        '--all[Install to all connected YubiKeys]' \
        '(-y --yes)'{-y,--yes}'[Non-interactive mode]'
      ;;
    renew)
      _arguments \
        '--backup[Path to encrypted backup]:file:_files -g "*.tar.gz.gpg"' \
        '--backup-pass[Passphrase for backup decryption]:passphrase:' \
        '--passphrase[Key passphrase for operations]:passphrase:' \
        '--expiration[New expiration period]:expiration:(1y 2y 3y 5y)' \
        '--revoke[Revoke old subkeys before creating new]' \
        '--keyserver[Keyserver to update after renewal]:url:' \
        '--admin-pin[YubiKey admin PIN]:pin:' \
        '--force[Skip confirmation prompts]' \
        '(-y --yes)'{-y,--yes}'[Non-interactive mode]'
      ;;
    *)
      _values 'gpg key command' \
        'list[List GPG keys on YubiKey]' \
        'create[Create master key and subkeys]' \
        'install[Install subkeys to YubiKey]' \
        'renew[Renew subkeys with fresh expiration]' \
        'help[Show help for gpg key commands]'
      ;;
  esac
}

_keycutter_gpg_setup() {
  _arguments \
    '--enable-ssh[Enable SSH support in gpg-agent]' \
    '--skip-packages[Skip package installation]' \
    '--skip-config[Skip GPG configuration]' \
    '--skip-launchagent[Skip macOS LaunchAgent setup]' \
    '--skip-wsl-relay[Skip WSL relay setup]' \
    '(-y --yes)'{-y,--yes}'[Non-interactive mode]'
}

_keycutter_gpg_backup() {
  _arguments \
    '--fingerprint[Key fingerprint to backup]:fingerprint:_keycutter_gpg_fingerprints' \
    '--output-dir[Directory for backup file]:directory:_files -/' \
    '--passphrase[Key passphrase for export]:passphrase:' \
    '--backup-pass[Passphrase for backup encryption]:passphrase:' \
    '(-y --yes)'{-y,--yes}'[Non-interactive mode]'
}

_keycutter_gpg_yubikeys() {
  _arguments \
    '--fingerprint[Filter by GPG key fingerprint]:fingerprint:_keycutter_gpg_fingerprints' \
    '--json[Output as JSON]' \
    '(-q --quiet)'{-q,--quiet}'[Output only serial numbers]' \
    '--connected[Show currently connected YubiKeys]' \
    '--remove[Remove a YubiKey from the registry]:serial:_keycutter_gpg_yubikey_serials'
}

_keycutter_gpg() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$words[3]" in
    key)
      _keycutter_gpg_key
      ;;
    setup)
      _keycutter_gpg_setup
      ;;
    backup)
      _keycutter_gpg_backup
      ;;
    yubikeys)
      _keycutter_gpg_yubikeys
      ;;
    *)
      _values 'gpg command' \
        'key[GPG key management]' \
        'setup[Configure host for GPG/YubiKey]' \
        'backup[Backup master key]' \
        'yubikeys[List registered YubiKey installations]' \
        'help[Show help for GPG commands]'
      ;;
  esac
}

_keycutter_agent() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$words[3]" in
    show|keys|hosts)
      _keycutter_ssh_agents
      ;;
    add-key|remove-key)
      case "$CURRENT" in
        4) _keycutter_ssh_agents ;;
        5) _keycutter_ssh_keys ;;
      esac
      ;;
    *)
      _values 'agent command' \
        'show[Show agent details]' \
        'keys[List keys for agent]' \
        'hosts[List hosts for agent]' \
        'add-key[Add key to agent]' \
        'remove-key[Remove key from agent]'
      ;;
  esac
}

_keycutter_host() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$words[3]" in
    show|agent|keys|config|edit)
      _keycutter_ssh_hosts
      ;;
    *)
      _values 'host command' \
        'show[Show host details]' \
        'agent[Show agent for host]' \
        'keys[List keys for host]' \
        'config[Show config for host]' \
        'edit[Edit host configuration]'
      ;;
  esac
}

_keycutter_key() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$words[3]" in
    show|agents|hosts)
      _keycutter_ssh_keys
      ;;
    *)
      _values 'key command' \
        'show[Show key details]' \
        'agents[List agents for key]' \
        'hosts[List hosts for key]'
      ;;
  esac
}

_keycutter_update() {
  _values 'update command' \
    'git[Pull from git]' \
    'config[Update SSH config]' \
    'requirements[Check requirements]' \
    'touch-detector[Update touch detector]'
}

_keycutter_ssh_known_hosts() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$words[3]" in
    remove|fix)
      _keycutter_ssh_hosts
      ;;
    restore)
      local backup_dir="$HOME/.ssh/known_hosts_backups"
      if [[ -d "$backup_dir" ]]; then
        local backups
        backups=(${(f)"$(ls -1 "$backup_dir" 2>/dev/null | grep '^known_hosts\\.')"})
        _describe 'backup' backups
      fi
      ;;
    *)
      _values 'ssh-known-hosts command' \
        'delete-line[Remove specific line]' \
        'remove[Remove host entries]' \
        'fix[Fix host key issues]' \
        'backup[Backup known_hosts]' \
        'list-backups[Show available backups]' \
        'restore[Restore from backup]'
      ;;
  esac
}

_keycutter_git_signing() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$words[3]" in
    enable)
      _arguments \
        '--global[Enable globally]' \
        ':key file:_files -g "*.pub"'
      ;;
    disable)
      _arguments \
        '--global[Disable globally]'
      ;;
    *)
      _values 'git-signing command' \
        'enable[Enable git signing]' \
        'disable[Disable git signing]' \
        'status[Show signing status]' \
        'help[Show help]'
      ;;
  esac
}

_keycutter_create() {
  _arguments \
    '--resident[Create resident key]' \
    '--type[Key type]:type:(ecdsa-sk ed25519-sk rsa ecdsa ed25519)' \
    ':keytag:'
}

_keycutter() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  local -a commands
  commands=(
    'create:Create a new SSH key'
    'authorized-keys:Manage authorized keys'
    'push-keys:Push keys to hosts'
    'update:Update keycutter'
    'install-touch-detector:Install touch detector'
    'config:Show configuration'
    'check-requirements:Check requirements'
    'agents:List all agents'
    'hosts:Host management'
    'keys:List all keys'
    'tokens:Manage tokens'
    'agent:Agent management'
    'host:Host management'
    'key:Key management'
    'ssh-known-hosts:Manage known_hosts'
    'git-signing:Configure git signing'
    'gpg:GPG key management'
  )

  _arguments -C \
    '1: :->command' \
    '*:: :->args'

  case $state in
    command)
      _describe 'command' commands
      ;;
    args)
      case $words[1] in
        gpg)
          _keycutter_gpg
          ;;
        agent)
          _keycutter_agent
          ;;
        host)
          _keycutter_host
          ;;
        key)
          _keycutter_key
          ;;
        update)
          _keycutter_update
          ;;
        ssh-known-hosts)
          _keycutter_ssh_known_hosts
          ;;
        git-signing)
          _keycutter_git_signing
          ;;
        create)
          _keycutter_create
          ;;
        authorized-keys|push-keys|config)
          _keycutter_ssh_hosts
          ;;
        hosts)
          _values 'hosts command' \
            'edit[Edit host configuration]'
          ;;
        *)
          ;;
      esac
      ;;
  esac
}

_keycutter "$@"
