#!/usr/bin/env bash

#
# "Monitor 1" framework. Actual script is expected source this file as is.
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

# Data path.
DATA="${SN}.d"

#--------------------------------------- Configuration

if [ -r "${DATA}/conf.sh" ]; then
  . "${DATA}/conf.sh" || exit 1
fi

#--------------------------------------- Functions

require_c_ctl() {
  if [ -z "${C_CTL:-}" ]; then
    echo "Error: C_CTL is not defined" >&2
    return 1
  fi

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

#--------------------------------------- Hooks

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
      echo "Error: Unknown Curl result: $?" >&2
      return 2
    esac
  }
fi

if ! function_exists "handle_start"; then
  handle_start() {
    ${C_CTL} start
  }
fi

if ! function_exists "handle_stop"; then
  handle_stop() {
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
  print_status

  echo "Entering main loop"

  while true; do
    get_sema_status
    local SEMA_STATUS=$?
    is_debug && echo "-- SEMA_STATUS:${SEMA_STATUS}"
    is_debug && resx "is_running"
    is_debug && resx "is_stopped"

    if [ $SEMA_STATUS = 0 ]; then
      if is_running; then
        is_debug && echo "-- Semaphore is up, jobs are running -- nothing to do"
      else
        echo "Semaphore is up, triggering START"
        handle_start
        sleep_settle
      fi
    elif [ $SEMA_STATUS = 1 ]; then
      if is_stopped; then
        is_debug && echo "-- Semaphore is down, jobs are stopped -- nothing to do"
      else
        echo "Semaphore is down, triggering STOP"
        handle_stop
        sleep_settle
      fi
    else
      # This is an important branch. If there's trouble getting the semaphore, refrain from any kind of action.
      echo "Error: Unknown semaphore status: ${SEMA_STATUS}"
      sleep_settle
    fi

    sleep_idle
  done
}

main 2>&1 | tpipe

#
# Implementation notes:
#
# * Main loop behaves like an interactive program. All generated output goes to stdout.
