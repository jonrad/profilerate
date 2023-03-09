#!/usr/bin/env sh
### Note, this will delete your PROFILERATE_DIR after running. So don't run this manually unless you know what you're doing

profilerate_shell() {
  PROFILERATE_DIR="$(dirname "$0")"
  export PROFILERATE_DIR

  # TODO fix dupe paths
  if [ -x "${SHELL}" ]; then
    PATH="$(dirname "${SHELL}"):${PATH}"
  fi

  if [ -x "$(command -v zsh || true)" ]; then
    PROFILERATE_SHELL="zsh" exec "${PROFILERATE_DIR}/shells/zsh.sh" "${PROFILERATE_DIR}/profilerate.sh" -l
  elif [ -x "$(command -v bash || true)" ]; then
    PROFILERATE_SHELL="bash" exec bash --init-file "${PROFILERATE_DIR}/shells/bash.sh"
  else
    ENV="${PROFILERATE_DIR}/shells/sh.sh" PROFILERATE_SHELL="sh" exec sh
  fi
}

profilerate_shell
