#!/usr/bin/env bash
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

if [ -f ~/.bash_profile ]; then
  . ~/.bash_profile
elif [ -f ~/.bash_login ]; then
  . ~/.bash_login
elif [ -f ~/.profile ]; then
  . ~/.profile
fi

. "${PROFILERATE_DIR}/profilerate.sh"
