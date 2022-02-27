#!/usr/bin/env bash

#
# "Core 1" framework. Actual script is expected to redefine the hook(s) below
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
. lib.sh || exit 1

# Compute data paths. See `Implementation.md`.
DATA="${SN}.d"
ADATA=`realpath "${DATA}"`

#--------------------------------------- Configuration

. "${DATA}/conf.sh" || exit 1

#--------------------------------------- Hooks

if ! function_exists "set_ssh_mode" ; then
  # We basically require the parent script to define this hook in order to make SSH option set mode-meaningful.
  echo "Please define \`set_ssh_mode()\` in your script. Exiting now" >&2
  exit 1
fi

#--------------------------------------- Main

main() {
  if is_pid_alive; then
    echo "${P} is already running, PID `get_pid`"
    return 2    # Not strictly an error, but not 0 either.
  fi

  # AutoSSH options.
  AO=(
    -M 0    # No monitoring.
  )

  is_bg && AO+=( -f )

  # SSH options.
  O=()

  set_ssh_mode

  O+=(
    -i ${ADATA}/${C_KEY}            # See `Implementation.md` on absolute paths.
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
