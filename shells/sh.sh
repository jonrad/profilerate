#!/usr/bin/env sh
if [ -f /etc/profile ]; then
  . /etc/profile
fi

if [ -f ~/.profile ]; then
  . ~/.profile
fi

. "$PROFILERATE_DIR/profilerate.sh"
