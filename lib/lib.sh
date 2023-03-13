
#
# Shared library for all.
#

set -e

# Tuned tunnel options we can consider common for all.
SSH_TUNNEL_OPTS=(
  -N    # No shell.

  # Disable known interactive prompts.
  -o "StrictHostKeyChecking no"

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

# Exit script with an optional message ($1) and line number ($2).
#
#   abort
#   abort "Some error"
#   abort "Some error" ${LINENO}
abort() {
  if [ -n "${1:-}" -a -n "${2:-}" ]; then
    echo "Abort at line ${2}: ${1}" >&2
  else
    echo "Abort: ${1:-(no message)}" >&2
  fi
  exit 1
}

# Return 0 if the specified command can be run. Works for: alias, executable file, function.
# $1: Command.
command_exists() {
  type -t "${1}" >/dev/null
}

# $1: Function name.
function_exists() {
  declare -F | egrep -q "declare -f ${1}$"
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
# NOTE: Hook `get_pid` is used.
is_pid_alive() {
  local PID=`get_pid`
  test -n "${PID}" || return 1    # If empty, that's a "missing PID" anyway.
  kill -s 0 ${PID} 2>/dev/null
}

# Read input, prepend the prefix ($1) to each line.
ppipe() {
  while read LINE; do
    echo "${1}${LINE}"
  done
}

require_p() {
  if [ -z "${P:-}" ]; then
    echo "Error: P is not defined" >&2
    return 1
  fi
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
  while true; do
    [ "${BREAK:-}" = "!" ] && break
    date +%S | egrep -q "$1" && break
    sleep 0.1
  done
}

#--------------------------------------- Hooks

if ! function_exists "is_already_running"; then
  require_p || exit 1

  is_already_running() {
    if is_pid_alive; then
      echo "${P} is already running, PID `get_pid`"
      return 0
    fi
    false
  }
fi

# NOTE: Technically it's a hook which we may want to redefine.
if ! function_exists "print_ts"; then
  # Print a uniform timestamp prefix.
  print_ts() {
    echo -n "[`date +"%Y-%m-%d %H:%M:%S"`]"
  }
fi

set +e
