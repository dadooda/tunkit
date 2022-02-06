#!/usr/bin/env bash

#
# "Control 1" framework. Actual script is expected source this file as is.
#

# Get script name & path.
SN=${0##*/}
SP=${0%/*}

# "Main" script name.
MN=${SN%-*}

# Set strict mode.
set -u -o pipefail

# WARNING! Cd to script directory and stay there.
cd "${SP}" || exit 1

# Get the library.
. lib.sh || exit 1

# Compute data path.
DATA="${MN}.d"

#--------------------------------------- Functions

sleep_n_status() {
  sleep 0.5
  cmd_status
}

#--------------------------------------- Commands

cmd_log() {
  set -x
  tail -f "${DATA}/autossh.log"
}

cmd_start() {
  BG=! "./${MN}"
  [ $? = 0 ] && sleep_n_status
}

# Print status. Return 0 if running, 1 otherwise.
cmd_status() {
  if is_running; then
    echo "${P} is running, PID `get_pid`"
  else
    echo "${P} is not running"
    false
  fi
}

cmd_stop() {
  if ! is_running; then
    echo "${P} is not running"
    return 1
  fi

  echo "Stopping ${P}, PID `get_pid`"
  kill `get_pid`

  sleep_n_status
  true
}

cmd_usage() {
  echo "USAGE: ${SN} <log|start|status|stop>"
}

#--------------------------------------- Main

CMD="${1:-}"

case "$CMD" in
"log"|"start"|"status"|"stop")
  cmd_${CMD}
  ;;
*)
  cmd_usage
  exit 1
  ;;
esac

# No more commands after this line -- retain command result.
