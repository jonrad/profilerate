#!/usr/bin/env sh
#V3

# TODO handle failures
if [ ! -z "$PROFILERATE_DEBUG" ]; then
  profilerate_debug () {
    echo "PROFILERATE profilerate_debug: $1"
  }
else
  profilerate_debug () {
    :
  }
fi

if [ -z "$PROFILERATE_DIR" ]; then
  export PROFILERATE_DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
fi

# Try to generate the profilerate id based on the current dir
if [ -z "$PROFILERATE_ID" ]; then
  export PROFILERATE_ID=$(basename $PROFILERATE_DIR)

  # todo can we remove printf (yes)
  while [ "$(printf %.1s "$PROFILERATE_ID")" = "." ]
  do
    PROFILERATE_ID=${PROFILERATE_ID#.}
  done

  if [ -z "$PROFILERATE_ID" ]; then
    echo "No PROFILERATE_ID set"
    return
  fi
fi

profilerate_debug "PROFILERATE_DIR=$PROFILERATE_DIR"
profilerate_debug "PROFILERATE_ID=$PROFILERATE_ID"

### Docker
if [ -x "$(command -v docker)" ]; then
  profilerate_debug "Detected docker"

  # replicates our configuration to a container before running an interactive bash
  profilerate_docker_cp () {
    local CONTAINER
    for CONTAINER; do true; done

    local DEST="/tmp/.$PROFILERATE_ID"
    docker exec $CONTAINER rm -rf "$DEST" && \
      docker cp "$PROFILERATE_DIR" "$CONTAINER:$DEST" >/dev/null 2>&1
  }

  profilerate_docker_exec () {
    local CONTAINER
    for CONTAINER; do true; done

    local DEST="/tmp/.$PROFILERATE_ID"
    profilerate_docker_cp $CONTAINER &&
      docker exec -it $@ "$DEST/shell.sh"
  }

  profilerate_docker_run () {
    # TODO: This can be optimized by using docker run shell + docker attach using streaming input
    CONTAINER=$(docker run -it --detach --entrypoint sh $@ -c 'trap "exit 0" 2 && sleep infinity')

    if [ -n "$CONTAINER" ]; then
      profilerate_docker_exec $CONTAINER
      echo Stopping container &&
        docker exec -it $CONTAINER killall sleep > /dev/null 2>&1 ||
        docker stop $CONTAINER
    fi
  }
fi

### Kubernetes
if [ -x "$(command -v kubectl)" ]; then
  profilerate_debug "Detected kubectl"

  # kb replicates our configuration to a remote env before running an interactive bash
  profilerate_kubernetes () {
    emulate -L sh > /dev/null 2>&1
    local POD="${@: -1}"
    local TOTAL_ARGS=$#
    local ARGS=""
    if [ $# -gt 1 ]; then
      for i in $(seq 1 $(($TOTAL_ARGS - 1)))
      do
        local ARG=$(eval "echo \" \$$i\"")
        ARGS="$ARGS $ARG"
      done
    fi

    #TODO we can use rsync for this
    DEST = "/tmp/.$PROFILERATE_ID"
    kubectl exec $@ -- rm -rf "$DEST" && \
    kubectl cp $PROFILERATE_DIR $ARGS "$POD:$DEST" && \
    kubectl exec -it $@ -- "$DEST/shell.sh"
  }
fi

### SSH
if [ -x "$(command -v ssh)" ]; then
  profilerate_debug "Detected ssh"
  # ssh [args] HOST to ssh to host and replicate our environment
  profilerate_ssh () {
    emulate -L sh > /dev/null 2>&1
    local HOST="${@: -1}"
    local TOTAL_ARGS=$#
    local ARGS=""
    if [ $# -gt 1 ]; then
      for i in $(seq 1 $(($TOTAL_ARGS - 1)))
      do
        echo $i
        local ARG=$(eval "echo \" \$$i\"")
        ARGS="$ARGS $ARG"
      done
    fi
    echo $HOST
    echo $ARGS

    DEST = "/tmp/.$PROFILERATE_ID"
    rsync -r --delete "$PROFILERATE_DIR/" "$HOST:$DEST/" -e "ssh $ARGS" && \
    ssh -t $HOST sh -lc "$DEST/shell.sh"
  }
fi

### VIM SETUP
if [ -f $PROFILERATE_DIR/vimrc ]; then
  export VIMINIT="source $PROFILERATE_DIR/vimrc"
fi

if [ -f "$PROFILERATE_DIR/personal.sh" ]; then
  profilerate_debug "Loading personal settings"
  . "$PROFILERATE_DIR/personal.sh"
else
  profilerate_debug "No personal settings found in $PROFILERATE_DIR/personal.sh"
fi

unset -f profilerate_debug
