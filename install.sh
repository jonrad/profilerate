#!/usr/bin/env bash

# Usage: ./install [SRC_DIR] [DST_DIR]
# If called without args, downloads the latest version from github and installs
# If SRC_DIR is specified, will install from that directory
# IF DST_DIR is specified, will install to that directory

set -euo pipefail

cat<<'EOF'
                  _| _)  |                  |         
   _ \   _| _ \   _|  |  |   -_)   _| _` |   _|   -_) 
  .__/ _| \___/ _|   _| _| \___| _| \__,_| \__| \___| 
 _|                                                   
       \\      \\      \\      \\      \\      \\
      __()    __()    __()    __()    __()    __()
    o(_-\_  o(_-\_  o(_-\_  o(_-\_  o(_-\_  o(_-\_

https://github.com/jonrad/profilerate

===============================================================================
EOF

install () {
  local HOME=${HOME:-$(echo -n ~)}

  if [ ! -d "$HOME" ]
  then
    echo "HOME is '$HOME' which isn't a directory. That's kind of weird"
    exit 1
  fi

  local DEST_DIR="${2:-$HOME/.config/profilerate}"

  # I'm using -p to avoid doing a path check first
  # shellcheck disable=SC2174
  mkdir -p -m 700 "$HOME/.config"
  # shellcheck disable=SC2174
  mkdir -p -m 700 "$HOME/.config/profilerate"
  echo "Installing to $DEST_DIR"

  local UNTAR_COMMAND="tar -xz -C $DEST_DIR -f -"

  # Don't override the personal file if it exists
  if [ -f "$DEST_DIR/personal.sh" ]
  then
    UNTAR_COMMAND="$UNTAR_COMMAND --exclude personal.sh"
  fi

  echo "Downloading and extracting..."

  if [ -n "${1:-}" ]
  then
    echo "Installing from $1"
    "$1/build.sh" && $UNTAR_COMMAND < "$1/profilerate.latest.tar.gz" 
  else
    curl -L "https://github.com/jonrad/profilerate/releases/download/main/profilerate.latest.tar.gz" | $UNTAR_COMMAND
  fi

  local INSTALL_PATHS=( ~/.zshrc ~/.bashrc )
  for INSTALL_PATH in "${INSTALL_PATHS[@]}"
  do
    if [ ! -f "$INSTALL_PATH" ]
    then
      touch "$INSTALL_PATH"
    fi

    if ! grep -q ". ~/.config/profilerate/profilerate.sh" "$INSTALL_PATH"
    then
      echo ". ~/.config/profilerate/profilerate.sh" >> "$INSTALL_PATH"
      echo "Installed to $INSTALL_PATH"
    else
      echo "Already installed in $INSTALL_PATH"
    fi
  done
}

install "$@"
echo
echo "All done!"
echo "To get the most use of profilerate, modify ~/.config/profilerate/personal.sh with your personal settings"

# Users personal scripts may fail, so let's remove the flags
set +euo pipefail

# shellcheck disable=SC1090
. ~/.config/profilerate/profilerate.sh
