#!/usr/bin/env sh
FILENAME="profilerate.latest.tar.gz"
if [ -f "$FILENAME" ]
then
  rm profilerate.latest.tar.gz
fi

tar cfvz profilerate.latest.tar.gz profilerate.sh shell.sh shells personal.sh
