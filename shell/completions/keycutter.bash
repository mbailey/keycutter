#!/usr/bin/env bash

_keycutter_completion() {
  local cur prev words cword
  _init_completion || return

  local commands="create authorized-keys update config check-requirements"

  case $prev in
  keycutter)
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return
    ;;
  create)
    # Add completion for create subcommand options
    COMPREPLY=($(compgen -W "--resident --type" -- "$cur"))
    return
    ;;
  --type)
    COMPREPLY=($(compgen -W "ecdsa-sk ed25519-sk rsa ecdsa ed25519" -- "$cur"))
    return
    ;;
  esac

  # Default to filename completion
  COMPREPLY=($(compgen -f -- "$cur"))
}

complete -F _keycutter_completion keycutter
