# Custom ssh-agent management

# SSH Agent Management: Define multiple agents for different purposes
#
# 1. SSH access to git: the only thing you'll need ssh-agent forwarding for.
# 2. Use SSH ProxyJump instead for bastion hopping
# 3. Same proxy is used locally and shared with remote hosts.
# 4. You don't need to use the SSH agent from local host
# 5. You probably only need git ssh keys on the your ssh-agent(s)
# 6. Hopping around from box to box can be fun. Feel free to add more keys!
