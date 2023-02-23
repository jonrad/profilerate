#!/usr/bin/env sh
#V3

# TODO handle failures
if [ -n "$PROFILERATE_DEBUG" ]; then
  profilerate_debug () {
    echo "PROFILERATE profilerate_debug: $1"
  }
else
  profilerate_debug () {
    :
  }
fi

if [ -z "$PROFILERATE_DIR" ]; then
  PROFILERATE_DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
  export PROFILERATE_DIR
fi

profilerate_debug "PROFILERATE_DIR=$PROFILERATE_DIR"

# TODO deal with no mktemp
_PROFILERATE_CREATE_DIR='_profilerate_create_dir () {
  if [ ! -d ~/.config ]
  then
    mkdir -m 700 -p ~/.config || true
  fi

  DEST=$(mkdir -m 700 -p ~/.config/profilerated >/dev/null 2>&1 && echo -n ~/.config/profilerated || echo "")
  if [ -n "$DEST" ]
  then
    RESULT=$(mktemp -qd "$DEST/profilerate.XXXXXX")
  fi

  if [ -z "$RESULT" ]
  then
    RESULT=$(mkdir -m 700 -p "/tmp/profilerated" >/dev/null 2>&1 && mktemp -qd "/tmp/profilerated/profilerate.XXXXXX")
  fi

  if [ -z "$RESULT" ]
  then
    RESULT=$(mktemp -qd)
  fi

  if [ -n "$RESULT" ]
  then
    chmod 700 "$RESULT" && echo "$RESULT" && return
  fi

  return 1
}; _profilerate_create_dir; unset _profilerate_create_dir'

### Docker
if [ -x "$(command -v docker)" ]; then
  profilerate_debug "Detected docker"

  # replicates our configuration to a container before running an interactive bash
  profilerate_docker_cp () {
    for CONTAINER; do true; done

    DEST=$(docker exec "$CONTAINER" sh -c "$_PROFILERATE_CREATE_DIR") && \
      docker cp "$PROFILERATE_DIR/." "$CONTAINER:$DEST" >/dev/null 2>&1 && \
      echo $DEST && \
      return

    return 1
  }

  profilerate_docker_exec () {
    for CONTAINER; do true; done

    DEST=$(profilerate_docker_cp "$CONTAINER") &&
      docker exec -it "$@" "$DEST/shell.sh"
  }

  profilerate_docker_run () {
    # TODO: This can be optimized by using docker run shell + docker attach using streaming input
    CONTAINER=$(docker run -it --detach --init --entrypoint sh "$@" -c 'sleep infinity')

    if [ -n "$CONTAINER" ]; then
      profilerate_docker_exec "$CONTAINER"
      echo Stopping container && docker stop "$CONTAINER"
    fi
  }
fi

### Kubernetes
if [ -x "$(command -v kubectl)" ]; then
  profilerate_debug "Detected kubectl"

  # replicates our configuration to a remote env before running an interactive shell
  profilerate_kubectl () {
    emulate -L sh > /dev/null 2>&1
    for POD; do true; done
    TOTAL_ARGS=$#
    ARGS=""
    if [ $# -gt 1 ]; then
      for i in $(seq 1 "$($TOTAL_ARGS - 1)")
      do
        ARG=$(eval "echo \" \$$i\"")
        ARGS="$ARGS $ARG"
      done
    fi

    # TODO fix for args having spaces
    DEST=$(kubectl exec $@ -- sh -c "$_PROFILERATE_CREATE_DIR") && \
      kubectl cp "$PROFILERATE_DIR/." $ARGS "$POD:$DEST" && \
      kubectl exec -it "$@" -- "$DEST/shell.sh"
  }
fi

### SSH
if [ -x "$(command -v ssh)" ]; then
  profilerate_debug "Detected ssh"
  # ssh [args] HOST to ssh to host and replicate our environment
  profilerate_ssh () {
    emulate -L sh > /dev/null 2>&1
    for HOST; do true; done
    TOTAL_ARGS=$#
    ARGS=""
    if [ $# -gt 1 ]; then
      for i in $(seq 1 "$($TOTAL_ARGS - 1)")
      do
        ARG=$(eval "echo \" \$$i\"")
        ARGS="$ARGS $ARG"
      done
    fi

    # TODO fix for args with spaces
    # Also... scp is annoying. because scp $DIR/. doesn't work in all systems, we need to delete
    # the directory and then hope it can get created again with scp
    DEST=$(ssh $ARGS "$HOST" "DIR=\$($_PROFILERATE_CREATE_DIR); test -d \$DIR && rmdir \$DIR && echo \$DIR" 2>/dev/null) && \
      scp -r $ARGS "$PROFILERATE_DIR" "$HOST:$DEST" >/dev/null 2>&1 && \
      ssh -t $ARGS "$HOST" "sh -lc \"chmod 700 '$DEST';'$DEST/shell.sh'\""
  }
fi

### VIM SETUP
if [ -f "$PROFILERATE_DIR/vimrc" ]; then
  export VIMINIT="source \"$PROFILERATE_DIR/vimrc\""
fi

### Personal rc file
if [ -f "$PROFILERATE_DIR/personal.sh" ]; then
  profilerate_debug "Loading personal settings"
  . "$PROFILERATE_DIR/personal.sh"
else
  profilerate_debug "No personal settings found in $PROFILERATE_DIR/personal.sh"
fi

### Cleanup
unset -f profilerate_debug
