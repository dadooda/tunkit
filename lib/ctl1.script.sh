#!/usr/bin/env bash

#
# "Control 1" framework.
#
# The actual script is expected to redefine the hook(s) below
# and then source this file as is.
#

# OPTIMIZE: Try to unify this with `ctl2.script.sh` some day.

# Get script name & path.
SN=${0##*/}
SP=${0%/*}

# "Main" script name. `ra-ctl` yields `ra`.
MN=${SN%-ctl}

# Set strict mode.
set -u -o pipefail

# WARNING! Cd to script directory and stay there.
cd "${SP}" || exit 1

# Get the library.
. lib/lib.sh; [ $? = 0 ] || exit 1

# Data path.
DATA="${MN}.d"

#--------------------------------------- Hooks

if ! function_exists "get_pid"; then
  get_pid() {
    cat "${DATA}/autossh.pid" 2>/dev/null
  }
fi

if ! function_exists "print_usage"; then
  print_usage() {
    echo "USAGE: ${SN} <log|start|status|stop>"
  }
fi

if ! function_exists "sleep_n_status" ; then
  sleep_n_status() {
    sleep 0.5
    cmd_status
  }
fi

#--------------------------------------- Commands

if ! function_exists "cmd_log"; then
  cmd_log() {
    set -x
    tail -f "${DATA}/autossh.log"
  }
fi

if ! function_exists "cmd_start"; then
  cmd_start() {
    BG=! "./${MN}"
    [ $? = 0 ] && sleep_n_status
  }
fi

if ! function_exists "cmd_status"; then
  # Print status. Return 0 if running, 1 otherwise.
  cmd_status() {
    if is_pid_alive; then
      echo "${P} is running, PID `get_pid`"
    else
      echo "${P} is not running"
      false
    fi
  }
fi

if ! function_exists "cmd_stop"; then
  cmd_stop() {
    if ! is_pid_alive; then
      echo "${P} is not running"
      return 1
    fi

    echo "Stopping ${P}, PID `get_pid`"
    kill `get_pid`

    sleep_n_status
    true
  }
fi

#--------------------------------------- Main

main() {
  CMD="${1:-}"

  if function_exists "cmd_${CMD}"; then
    cmd_${CMD}
  else
    print_usage
    false
  fi
}

main "$@"

# No more commands after this line -- retain command result.
