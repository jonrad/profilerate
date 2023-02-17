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

DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

# Load the default bashrc as well (TODO: Why?)
if [ -f "$HOME/.bashrc" ]; then
  profilerate_debug "Loading $HOME/.bashrc"
  . "$HOME/.bashrc"
fi
 
# Try to generate the profilerate id based on the current dir
if [ -z "$PROFILERATE_ID" ]; then
  export PROFILERATE_ID=$(basename $DIR)
  if [ "$PROFILERATE_ID" = "profilerate" ]; then
    export PROFILERATE_ID=
    echo "This script must exist in a uniquely named directory. Please rename dir to something other than 'profilerate'"
    return
  fi
fi

profilerate_debug "PROFILERATE_ID=$PROFILERATE_ID"


# PROFILERATE_DIR is where the config files are located in this install
# Sometimes looking at the script dir doesn't work when using bash with the --init-file flag
# so we have to do some digging
if [ ! -z "$PROFILERATE_DIR" ]; then
  : # already set, no need to recompute - useful for debugging
elif [ -f "$DIR/profilerate.sh" ]; then
  export PROFILERATE_DIR=$DIR
elif [ -d "$HOME/$PROFILERATE_ID" ]; then
  export PROFILERATE_DIR="$HOME/$PROFILERATE_ID"
elif [ -d "/tmp/$PROFILERATE_ID" ]; then
  export PROFILERATE_DIR="/tmp/$PROFILERATE_ID"
elif [ -d "/$PROFILERATE_ID" ]; then
  export PROFILERATE_DIR="/$PROFILERATE_ID" #docker hacks
else
  export PROFILERATE_DIR="/tmp/$PROFILERATE_ID"
fi

profilerate_debug "PROFILERATE_DIR=$PROFILERATE_DIR"

### Docker
if [ -x "$(command -v docker)" ]; then
  profilerate_debug "Detected docker"

  # replicates our configuration to a container before running an interactive bash
  profilerate_docker_cp () {
    CONTAINER="${@: -1}"

    docker exec $CONTAINER rm -rf "$PROFILERATE_ID" && \
      docker cp "$PROFILERATE_DIR" "$CONTAINER:$PROFILERATE_ID"
  }

  profilerate_docker_exec () {
    CONTAINER="${@: -1}"

    profilerate_docker_cp $CONTAINER && 
      docker exec -it -e ENV="/$PROFILERATE_ID/profilerate.sh" $@ "/$PROFILERATE_ID/shell.sh"
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
    for i in $(seq 1 $(($TOTAL_ARGS - 1)))
    do
      local ARG=$(eval "echo \" \$$i\"")
      ARGS="$ARGS $ARG"
    done

    kubectl exec $@ -- rm -rf "/tmp/$PROFILERATE_ID" && \
    kubectl cp $PROFILERATE_DIR $ARGS "$POD:/tmp/$PROFILERATE_ID" && \
    kubectl exec -it $@ -- "/tmp/$PROFILERATE_ID/shell.sh"
  }
fi

### su
# Use su to switch to root and use our configuration. Stop using sudo su!
if [ -x "$(command -v sudo)" ]; then
  alias profilerate_su="sudo -H -s bash $PROFILERATE_DIR/shell.sh"
fi

### SSH
# Use su to switch to root and use our configuration. Stop using sudo su!
if [ -x "$(command -v sudo)" ]; then
  alias profilerate_su="sudo -H -s bash $PROFILERATE_DIR/shell.sh"
fi

if [ -x "$(command -v ssh)" ]; then
  profilerate_debug "Detected ssh"
  # s HOST [args] to ssh to host and replicate our environment
  profilerate_ssh () {
    HOST=$1
    shift
    ARGS=$@

    rsync -r $PROFILERATE_DIR $HOST:/tmp/ -e "ssh $ARGS" && \
    ssh -t $HOST /tmp/$PROFILERATE_ID/shell.sh
  }
fi

### VIM SETUP
if [ -f $PROFILERATE_DIR/vimrc ]; then
  export VIMINIT="source $PROFILERATE_DIR/vimrc"
fi

if [ "$(command -v shopt)" ]; then #where did this go?
  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi
  fi
else
  profilerate_debug "No shopt found"
fi

if [ -f "$PROFILERATE_DIR/personal.sh" ]; then
  profilerate_debug "Loading personal settings"
  . "$PROFILERATE_DIR/personal.sh"
else
  profilerate_debug "No personal settings found in $PROFILERATE_DIR/personal.sh"
fi

unset -f profilerate_debug
