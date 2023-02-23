#!/usr/bin/env sh
### DO NOT CALL THIS FILE YOURSELF ###
### FOR SERIOUS ###

profilerate_shell() {
  PROFILERATE_DIR="$(dirname "$0")"
  export PROFILERATE_DIR

  # TODO fix dupe paths
  if [ -x "$SHELL" ]; then
    PATH="$(dirname "$SHELL"):$PATH"
  fi

  if [ -x "$(command -v zsh)" ]; then
    export PROFILERATE_SHELL="zsh"
    "$PROFILERATE_DIR/shells/zsh.sh" "$PROFILERATE_DIR/profilerate.sh" -l
  elif [ -x "$(command -v bash)" ]; then
    export PROFILERATE_SHELL="bash"
    bash --init-file "$PROFILERATE_DIR/shells/bash.sh"
  else
    export PROFILERATE_SHELL="sh"
    export ENV="$PROFILERATE_DIR/shells/sh.sh"
    sh
  fi
}

profilerate_shell
if [ -n "$PROFILERATE_DIR" ]
then
  rm -rf $PROFILERATE_DIR
fi
