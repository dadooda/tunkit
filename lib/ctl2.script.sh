#!/usr/bin/env bash

#
# "Control 2" framework.
#
# The actual script is expected to redefine the hook(s) below
# and then source this file as is.
#

# Get script name & path.
SN=${0##*/}
SP=${0%/*}

# "Main" script name. `ra-ctl` yields `ra`. `ra-mon-ctl` yields `ra-mon`.
MN=${SN%-ctl}

# Set strict mode.
set -u -o pipefail

# WARNING! Cd to script directory and stay there.
cd "${SP}" || exit 1

# Get the library.
. lib/lib.sh; [ $? = 0 ] || exit 1

# Data path.
DATA="${MN}.d"

#--------------------------------------- Functions

require_log_bn() {
  if [ -z "${LOG_BN:-}" ]; then
    echo "Error: LOG_BN is not defined" >&2
    return 1
  fi
}

require_pid_bn() {
  if [ -z "${PID_BN:-}" ]; then
    echo "Error: PID_BN is not defined" >&2
    return 1
  fi
}

#--------------------------------------- Hooks

# We just need it here and there.
require_p || exit 1

if ! function_exists "get_pid"; then
  require_pid_bn || exit 1

  get_pid() {
    cat "${DATA}/${PID_BN}" 2>/dev/null
  }
fi

if ! function_exists "print_usage"; then
  print_usage() {
    echo "USAGE: ${SN} <log|start|status|stop>"
  }
fi

if ! function_exists "sleep_n_status" ; then
  sleep_n_status() {
    # OPTIMIZE: Wait for pidfile to vanish.
    sleep 1       # For Cygwin we need a bit longer pause.
    cmd_status
  }
fi

#--------------------------------------- Commands

if ! function_exists "cmd_log"; then
  require_log_bn || exit 1

  cmd_log() {
    set -x
    tail -f "${DATA}/${LOG_BN}"
  }
fi

if ! function_exists "cmd_start"; then
  # IMPORTANT! Define `cmd_start` depending on how MN supports background execution.
  # The mode when MN supports `BG=!` is called "native" and is the default.
  # The opposite is called "forced" and can be specified via `FORCED_BG=!`.

  if [ "${FORCED_BG:-}" = "!" ]; then
    # Forced mode.
    require_log_bn || exit 1

    cmd_start() {
      is_already_running && return 0
      "./${MN}" >>"${DATA}/${LOG_BN}" 2>&1 &
      [ $? = 0 ] && sleep_n_status
    }
  else
    # Native mode.
    cmd_start() {
      is_already_running && return 0
      BG=! "./${MN}"
      [ $? = 0 ] && sleep_n_status
    }
  fi
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
