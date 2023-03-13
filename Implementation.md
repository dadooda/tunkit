
Implementation notes
====================

* When run in background mode AutoSSH requires absolute paths to the key and `AUTOSSH_PIDFILE`.
  Might be a glitch, but it doesn't work otherwise.
* Everywhere in the scripts the sourcing is performed explicitly like `. conf.sh`
  and never like `. conf.sh || exit 1`. This is to allow for `set -e` in the sourced file.
  `||` effectively disables `set -e` and makes error handling quite cumbersome.
* Semaphore URLS for monitor scripts must be HTTPS since many ISPs intercept
  404 pages with their ads, overwriting the original HTTP status.
