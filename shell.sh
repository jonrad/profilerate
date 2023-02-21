#!/usr/bin/env sh
profilerate_shell() {
  export PROFILERATE_DIR=$(dirname "$0")
  local PATH=$PATH

  # TODO fix dupe paths
  if [ -x "$SHELL" ]; then
    PATH="$(dirname "$SHELL"):$PATH"
  fi

  export PROFILERATE_ID=$(basename $PROFILERATE_DIR)
  # todo can we remove printf (yes)
  while [ "$(printf %.1s "$PROFILERATE_ID")" = "." ]
  do
    PROFILERATE_ID=${PROFILERATE_ID#.}
  done

  if [ -x "$(command -v zsh)" ]; then
    export PROFILERATE_SHELL=zsh
    $PROFILERATE_DIR/shells/zsh.sh $PROFILERATE_DIR/profilerate.sh -l
  elif [ -x "$(command -v bash)" ]; then
    export PROFILERATE_SHELL=bash
    bash --init-file $PROFILERATE_DIR/shells/bash.sh
  else
    export PROFILERATE_SHELL=sh
    export ENV=$PROFILERATE_DIR/shells/sh.sh
    sh
  fi
}

profilerate_shell
