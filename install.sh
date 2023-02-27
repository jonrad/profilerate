#!/usr/bin/env bash

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

SRC_DIR="$(mktemp -d)"
FILE="https://github.com/jonrad/profilerate/releases/download/main/profilerate.latest.tar.gz"

echo "Downloading and extracting to $SRC_DIR"
mkdir -p "$SRC_DIR"
curl -L "https://github.com/jonrad/profilerate/releases/download/main/profilerate.latest.tar.gz" | tar -xz -C "$SRC_DIR" -f -

if [ -n "$HOME" ]
then
  _HOME=$HOME
else
  _HOME=$(echo -n ~)
fi

mkdir -p -m 700 "$_HOME/.config"
mkdir -p -m 700 "$_HOME/.config/profilerate"
DEST_DIR="$_HOME/.config/profilerate"

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

# Todo stop assuming zsh is the preferred shell
if [ -f ~/.zshrc ]
then
  PROFILE=$(echo ~/.zshrc)
elif [ -f ~/.bashrc ]
then
  PROFILE=$(echo ~/.bashrc)
elif [ -f ~/.profile ]
then
  PROFILE=$(echo ~/.profile)
else
  touch ~/.profile
  PROFILE=$(echo ~/.profile)
fi

if ! grep -q ". ~/.config/profilerate/profilerate.sh" "$PROFILE"
then
  echo ". ~/.config/profilerate/profilerate.sh" >> "$PROFILE"
  echo "Installed to $PROFILE"
else
  echo "Already installed in $PROFILE!"
fi


echo
echo "All done!"
echo "To get the most use of profilerate, modify ~/.profilerate/personal.sh with your personal settings"
