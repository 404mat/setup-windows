# Autolaunch ssh agent

SSH_ENV="$HOME/.ssh/agent.env"

start_agent() {
  echo "Starting new SSH agent..."
  (umask 077; ssh-agent > "$SSH_ENV")
  . "$SSH_ENV" > /dev/null
  add_ssh_keys
}

add_ssh_keys() {
  shopt -s nullglob
  for key in ~/.ssh/*; do
    if [[ -f "$key" && "$key" != *.pub ]]; then
      ssh-add "$key" >/dev/null 2>&1
    fi
  done
  shopt -u nullglob
}

# Load existing agent if alive, else start a new one
if [ -f "$SSH_ENV" ]; then
  . "$SSH_ENV" > /dev/null
  ps -p $SSH_AGENT_PID > /dev/null 2>&1 || start_agent
else
  start_agent
fi


fastfetch

if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi