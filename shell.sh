#!/usr/bin/env sh
profilerate_shell() {
  local DIR=$(dirname "$0")
  local PATH=$PATH

  # TODO fix dupe paths
  if [ -x "$SHELL" ]; then
    PATH="$(dirname "$SHELL"):$PATH"
  fi

  export PROFILERATE_ID=$(basename $DIR)
  if [ -x "$(command -v zsh)" ]; then
    export PROFILERATE_SHELL=zsh
    $DIR/zshi.sh $DIR/profilerate.sh -l
  elif [ -x "$(command -v bash)" ]; then
    export PROFILERATE_SHELL=bash
    bash --init-file $DIR/profilerate.sh
  else
    export PROFILERATE_SHELL=sh
    export ENV=$DIR/profilerate.sh
    sh
  fi
}

profilerate_shell
