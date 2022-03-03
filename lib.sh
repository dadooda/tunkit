
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

# Return 0 if the specified command can be run. Works for: alias, executable file, function.
# $1: Command.
command_exists() {
  type -t "${1}" >/dev/null
}

# $1: Function name.
function_exists() {
  declare -F | egrep -q "declare -f ${1}$"
}

# Print PID from the file. Return 0 if pidfile exists.
get_pid() {
  cat "${DATA}/autossh.pid" 2>/dev/null
}

# Return 0 if requested to run in the background.
is_bg() {
  [[ "${BG:-}" = "!" ]]
}

# Return 0 if debugging is enabled.
is_debug() {
  [[ "${DEBUG:-}" = "!" ]]
}

# Return 0 if PID from the pidfile is alive.
is_pid_alive() {
  local PID=`get_pid`
  test -n "${PID}" || return 1    # If empty, that's a "missing PID" anyway.
  kill -s 0 ${PID} 2>/dev/null
}

# Read input, prepend the $1 prefix to each line.
# $1: Prefix.
ppipe() {
  while read LINE; do
    echo "${1}${LINE}"
  done
}

# Print a timestamped message by invoking a `print_ts`.
techo() {
  echo `print_ts` "$@"
}

# Read input, prepend a timestamp to each line.
#
#   ls -1 | tpipe
tpipe() {
  while read LINE; do
    techo "${LINE}"
  done
}

# Pause until current time's seconds part becomes something that matches the egrep pattern.
#
# $1: Grep pattern.
#
#   waitsec ".(0|5)"    # Match 00, 05, 10, etc.
waitsec() {
  while true;
  do
    date +%S | egrep -q "$1" && break
    sleep 0.1
  done
}

#--------------------------------------- Hooks

if ! function_exists "print_ts"; then
  # Print a uniform timestamp prefix.
  print_ts() {
    echo -n "[`date +"%Y-%m-%d %H:%M:%S"`]"
  }
fi

#--------------------------------------- DEBUG

# Print result.
# $1: (optional) Label.
#
#   cmd1; res "cmd1"
res() {
  local RES=$?
  local LABEL=${1:-}
  if [ -n "${LABEL}" ]; then
    echo "-- res(\"${LABEL}\"):${RES}"
  else
    echo "-- res:${RES}"
  fi
}

# Execute the command and print result.
# $@: Command, arguments.
#
#   resx echo "1  23"
resx() {
  $@
  eval "res '$@'"
}
