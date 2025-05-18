# Keycutter Roadmap

A place to share what's planned.

### Enhancements

- Commands for listing and configuring?

  - Use skim-stdin so users can pipe output of listing commands into relational

  ```
  keycutter agents # list agents
  keycutter agent AGENT # Show keys, hosts
  keycutter agent-keys AGENT # List keys for agent
  keycutter agent-hosts
  keycutter hosts
  keycutter host-config HOST # Shows agent, key, config
  keycutter host-agent HOST [AGENT] # Get / set agent for host
  keycutter host-key HOST [KEY] # Get / set key for host
  ```

- [ ] keycutter dir optional: $keycutter_ssh_subdit template ssh_config
- [ ] **Check / set PIN on device:** During setup and at anytime
- [ ] Add example hosts entries for personal, work and public
- [ ] Add gitlab
- [x] Tab completion for functions
- [x] Create regular key if hardware key not found
