#!/usr/bin/env bash

#
# "Core 1" framework.
#
# The actual script is expected to redefine the hook(s) below
# and then source this file as is.
#

# Get script name & path.
SN=${0##*/}
SP=${0%/*}

# Set strict mode.
set -u -o pipefail

# WARNING! Cd to script directory and stay there.
cd "${SP}" || exit 1

# Get the library.
. lib/lib.sh; [ $? = 0 ] || exit 1

# Paths and filenames. See `Implementation.md`.
DATA="${SN}.d"
ADATA=`realpath "${DATA}"`
KEYS="keys"
AKEYS=`realpath "${KEYS}"`

#--------------------------------------- Configuration

. "${DATA}/conf.sh"; [ $? = 0 ] || exit 1

#--------------------------------------- Hooks

if ! function_exists "get_pid"; then
  get_pid() {
    cat "${DATA}/autossh.pid" 2>/dev/null
  }
fi

if ! function_exists "set_ssh_mode" ; then
  # We basically require the parent script to define this hook in order to make SSH option set mode-meaningful.
  echo "Please define \`set_ssh_mode()\` in your script. Exiting now" >&2
  exit 1
fi

#--------------------------------------- Main

main() {
  # See `Implementation.md` on absolute paths.
  local KEY_AFN="${AKEYS}/${C_KEY}"

  # Make step-by-step configuration a little more explicit. If the key file is missing, SSH messages are fairly blunt.
  # NOTE: If the key file has bad permissions, SSH messages are very clear.
  if [ ! -r "${KEY_AFN}" ]; then
    echo "Error: Key file is not readable: ${KEY_AFN}" >&2
    return 1
  fi

  is_already_running && return 0

  # AutoSSH options.
  AO=(
    -M 0    # No monitoring.
  )

  is_bg && AO+=( -f )

  # SSH options.
  O=()

  set_ssh_mode

  O+=(
    -i ${KEY_AFN}
  )

  [ -n "${C_PORT:-}" ] && O+=( -p ${C_PORT} )

  O+=( "${SSH_TUNNEL_OPTS[@]}" )

  is_debug && O+=( -v )

  export AUTOSSH_PIDFILE="${ADATA}/autossh.pid"

  # Do a bit smarter debug output.
  if is_bg; then
    echo "Starting ${P}"
    is_debug && set -x
    export AUTOSSH_LOGFILE="${ADATA}/autossh.log"
  else
    echo "Running ${P} in the foreground"
    is_debug && set -x
  fi

  autossh "${AO[@]}" ${C_USER}@${C_HOST} "${O[@]}"
}

main
