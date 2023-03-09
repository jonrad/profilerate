#!/usr/bin/env sh
profilerate_cleanup() {
  if [ -n "${PROFILERATE_DIR}" ]
  then
    rm -rf "${PROFILERATE_DIR}"
  fi
}

trap profilerate_cleanup EXIT

if [ -f /etc/profile ]; then
  . /etc/profile
fi

if [ -f ~/.profile ]; then
  . ~/.profile
fi

. "${PROFILERATE_DIR}/profilerate.sh"
