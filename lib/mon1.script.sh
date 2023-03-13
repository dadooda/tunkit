#!/usr/bin/env bash

#
# "Monitor 1" framework.
#
# The actual script is expected to redefine the hook(s) below
# and then source this file as is.
#

# NOTE: Monitors don't YET support subcommands like `start`, `stop` etc.
#   Kill the process by knowing its PID.

# Get script name & path.
SN=${0##*/}
SP=${0%/*}

# "Main" script name. `ra-mon` yields `ra`.
MN=${SN%-mon}

# Set strict mode.
set -u -o pipefail

# WARNING! Cd to script directory and stay there.
cd "${SP}" || exit 1

# Get the library.
. lib/lib.sh; [ $? = 0 ] || exit 1

# Paths and filenames.
DATA="${SN}.d"

#--------------------------------------- Configuration

. "${DATA}/conf.sh"; [ $? = 0 ] || exit 1

#--------------------------------------- Setup

# Signal handler.
# $1: Signal name.
break_on() {
  techo "Got SIG${1:-?}"
  BREAK="!"
}

trap 'break_on INT' INT
trap 'break_on TERM' TERM

#--------------------------------------- Functions

require_c_ctl() {
  C_CTL=${C_CTL:-./${MN}-ctl}

  if ! command_exists "${C_CTL}"; then
    echo "Error: \$C_CTL can't be run: ${C_CTL}" >&2
    return 1
  fi
}

require_c_sema_url() {
  if [ -z "${C_SEMA_URL:-}" ]; then
    echo "Error: C_SEMA_URL is not defined" >&2
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

if ! function_exists "is_running"; then
  require_c_ctl || exit 1

  # Return 0 if the controlled script(s) are all running.
  # Uses `${C_CTL} status` to do the job.
  is_running() {
    if is_debug; then
      ${C_CTL} status
    else
      ${C_CTL} status > /dev/null
    fi
  }
fi

if ! function_exists "is_stopped"; then
  require_c_ctl || exit 1

  # Return 0 if the controlled script(s) are all stopped.
  # Uses `${C_CTL} status` to do the job.
  is_stopped() {
    if is_debug; then
      ${C_CTL} status
    else
      ${C_CTL} status > /dev/null
    fi

    test $? = 1
  }
fi

if ! function_exists "get_sema_status"; then
  require_c_sema_url || exit 1

  # Return semaphore status. 0 -- on, 1 -- off, 2 -- error.
  get_sema_status() {
    if is_debug; then
      (set -x; curl -fk "${C_SEMA_URL}")
    else
      curl -fks "${C_SEMA_URL}"
    fi

    case $? in
    0) return 0 ;;
    22) return 1 ;;
    *)
      techo "Error: Unknown Curl result: $?" >&2
      return 2
    esac
  }
fi

if ! function_exists "do_start"; then
  do_start() {
    ${C_CTL} start
  }
fi

if ! function_exists "do_stop"; then
  do_stop() {
    ${C_CTL} stop
  }
fi

if ! function_exists "print_status"; then
  print_status() {
    ${C_CTL} status
  }
fi

if ! function_exists "sleep_idle"; then
  # Sleep in the main loop.
  sleep_idle() {
    waitsec ".(0|5)"
  }
fi

if ! function_exists "sleep_settle"; then
  # Sleep after a state change to let things settle.
  sleep_settle() {
    sleep 1
  }
fi

#--------------------------------------- Main

main() {
  local PID_FN

  require_pid_bn || return 1

  PID_FN="${DATA}/${PID_BN}"

  if is_pid_alive; then
    techo "${P} is already running, PID `get_pid`"
    return 0
  fi

  # Create pidfile.
  echo $$ > ${PID_FN}

  techo "${P} started, PID `cat ${PID_FN}`"

  if [ -n "${SLEEP:-}" ]; then
    techo "Sleeping for ${SLEEP} seconds"
    sleep ${SLEEP}
  fi

  print_status

  while true; do
    if [ "${BREAK:-}" = "!" ]; then
      techo "Signal received, exiting main loop"
      break
    fi

    get_sema_status
    local SEMA_STATUS=$?
    is_debug && techo "-- SEMA_STATUS:${SEMA_STATUS}"
    is_debug && { is_running; techo "-- is_running:$?"; }
    is_debug && { is_stopped; techo "-- is_stopped:$?"; }

    if [ $SEMA_STATUS = 0 ]; then
      if is_running; then
        is_debug && techo "-- Semaphore is up, jobs are running. Nothing to do"
      else
        techo "Semaphore is up, triggering START"
        do_start
        sleep_settle
      fi
    elif [ $SEMA_STATUS = 1 ]; then
      if is_stopped; then
        is_debug && techo "-- Semaphore is down, jobs are stopped. Nothing to do"
      else
        techo "Semaphore is down, triggering STOP"
        do_stop
        sleep_settle
      fi
    else
      # This is an important branch. If there's trouble getting the semaphore, refrain from any kind of action.
      techo "Error: Unknown semaphore status: ${SEMA_STATUS}"
      sleep_settle
    fi

    sleep_idle
  done

  rm "${PID_FN}"

  techo "${P} exiting"
}

main 2>&1


#
# Implementation notes:
#
# * Main loop behaves like an interactive program. All generated output goes to stdout.
# * We use `techo` for message output, because of Bash signal handling limitations.
#   We can't do `main | tpipe` as we want a way to gracefully exit from the main loop.
#   Thus, messages emitted by the control script don't have a timestamp.
