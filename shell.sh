#!/usr/bin/env sh
DIR=$(dirname "$0")
export PROFILERATE_ID=$(basename $DIR)
if [ -x "$(command -v zsh)" ]; then
  export PROFILERATE_SHELL=zsh
  $DIR/zshi.sh $DIR/profilerate.sh
elif [ -x "$(command -v bash)" ]; then
  export PROFILERATE_SHELL=bash
  bash --init-file $DIR/profilerate.sh
else
  export PROFILERATE_SHELL=sh
  sh
fi
