
#
# Shared library for all.
#

# Repetitive program name used in messages.
P="AutoSSH"

# Tuned tunnel options we can consider common for all.
SSH_TUNNEL_OPTS=(
  -N    # No shell.

  # Only use the provided key (indentity) file, let it fail if anything's wrong.
  -o "IdentitiesOnly yes"
  -o "PasswordAuthentication no"

  # Options.
  -o "Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr"
  -o "Compression no"
  -o "ServerAliveCountMax 2"
  -o "ServerAliveInterval 5"
)

#--------------------------------------- Functions

# Print PID from the file. Return 0 if pidfile exists.
get_pid() {
  cat "${DATA}/autossh.pid" 2>/dev/null
}

# Return 0 if requested to run in the background.
is_bg() {
  [ "${BG:-}" = "!" ]
}

# Return 0 if debugging is enabled.
is_debug() {
  [ "${DEBUG:-}" = "!" ]
}

# Return 0 if AutoSSH is running.
is_running() {
  local PID=`get_pid`
  test -n "${PID}" || return 1    # If empty, that's a "missing PID" anyway.
  kill -s 0 ${PID} 2>/dev/null
}

#--------------------------------------- DEBUG

# Print result.
# $1: (optional) Label.
#
#   cmd1; res "cmd1"
res() {
  local LABEL=${1:-}
  if [ -n "${LABEL}" ]; then
    echo "-- res(\"${LABEL}\"):$?"
  else
    echo "-- res:$?"
  fi
}
