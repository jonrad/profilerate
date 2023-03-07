#!/usr/bin/env bash
for DIR in $(find . -type d)
do
  if [ ! "$DIR" = "." ] && [ -f "$DIR/build.sh" ]
  then
    cd $DIR
    echo "Building in $DIR"
    sh ./build.sh
    cd -
  fi
done
