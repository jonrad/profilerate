#!/usr/bin/env bash

# Usage: ./install [DIR]
# If called without args, downloads the latest version from github and installs
# If DIR is specified, will install from that directory

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
  local SRC_DIR="$(mktemp -d)"

  echo "Downloading and extracting to $SRC_DIR"
  mkdir -p "$SRC_DIR"

  if [ -n "${1:-}" ]
  then
    echo "Installing from $1"
    "$1/build.sh" && tar -xz -C "$SRC_DIR" -f - < "$1/profilerate.latest.tar.gz" 
  else
    curl -L "https://github.com/jonrad/profilerate/releases/download/main/profilerate.latest.tar.gz" | tar -xz -C "$SRC_DIR" -f -
  fi

  local HOME=${HOME:-$(echo -n ~)}

  mkdir -p -m 700 "$HOME/.config"
  mkdir -p -m 700 "$HOME/.config/profilerate"
  local DEST_DIR="$HOME/.config/profilerate"

  echo "Installing to $DEST_DIR"
  mkdir -p "$DEST_DIR"

  # Don't override the personal file if it exists
  if [ -f "$DEST_DIR/personal.sh" ]
  then
    rm "$SRC_DIR/personal.sh"
  fi

  cp -R "$SRC_DIR/" "$DEST_DIR/"

  # clean up
  rm -rf "$SRC_DIR"

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
. ~/.config/profilerate/profilerate.sh
