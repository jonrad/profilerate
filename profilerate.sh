#!/usr/bin/env sh
#V3

if [ -z "${PROFILERATE_DIR:-}" ]; then
  PROFILERATE_DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
  export PROFILERATE_DIR
fi

if [ -z "${PROFILERATE_SHELL:-}" ]; then
  PROFILERATE_SHELL=$(basename "$SHELL")
fi

# TODO deal with no mktemp
_PROFILERATE_CREATE_DIR='_profilerate_create_dir () {
  if [ ! -d ~/.config ]
  then
    mkdir -m 700 -p ~/.config >/dev/null 2>&1 || true
  fi

  DEST=$(mkdir -m 700 -p ~/.config/profilerated >/dev/null 2>&1 && echo -n ~/.config/profilerated || echo "")
  if [ -n "$DEST" ]
  then
    RESULT=$(mktemp -qd "$DEST/profilerate.XXXXXX")
  fi

  if [ -z "$RESULT" ]
  then
    RESULT=$(mktemp -qd "/tmp/.profilerated.XXXXXX")
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
}; _profilerate_create_dir'

_profilerate_copy () {
  RSH=$1
  DEST=$2

  # First let's try rsync, it's the most efficient
  if [ -x "$(command -v rsync)" ]; then
    rsync -e "$RSH" --rsync-path="$DEST/" -r "$PROFILERATE_DIR/." rsync:. >/dev/null 2>&1 && return
  fi

  # Try our implementation of tar
  if [ -x "$(command -v tar)" ]; then
    tar -c -f - -C "$PROFILERATE_DIR" . | eval "$RSH sh -c 'cd $DEST && tar -o -x -f -'" >/dev/null 2>&1 && return
  fi

  # Loop through all the files and transfer them via cat
  # note we're optimizing for connection count, so we do multiple loops
  # i wonder if we can do this as one command... (echo "Abc" > foo; echo "foo" > bar;)
  # certainly with something like base64 or od, but is that more efficient?
  cd $PROFILERATE_DIR
  FILES=$(find .)
  LAST_IFS=$IFS

  MKDIR=""
  echo "$FILES" | while IFS= read -r FILENAME 
  do 
    if [ -d "$FILENAME" ]
    then
      if [ "$FILENAME" != "." ]
      then
        MKDIR="${MKDIR}mkdir -m $(stat -f %Mp%Lp $FILENAME) -p $FILENAME;"
      fi
    fi
  done
  eval "$RSH sh -c 'cd $DEST;$MKDIR'"

  CHMOD=""
  echo "$FILES" | while IFS= read -r FILENAME 
  do 
    if [ -f "$FILENAME" ]
    then
      CHMOD="${CHMOD}chmod $(stat -f %Mp%Lp $FILENAME) $FILENAME;"
      cat $FILENAME | eval "$RSH sh -c 'cat > $DEST/$FILENAME'"
    fi
  done
  eval "$RSH sh -c 'cd $DEST;$CHMOD'"

  cd - >/dev/null
}

### Docker
if [ -x "$(command -v docker)" ]; then
  # replicates our configuration to a container before running an interactive bash
  profilerate_docker_cp () {
    #for CONTAINER; do true; done

    RSH="docker exec -i $@"
    DEST=$(docker exec "$@" sh -c "$_PROFILERATE_CREATE_DIR") && \
      _profilerate_copy "$RSH" "$DEST" >&2 && \
      echo $DEST && \
      return

    return 1
  }

  profilerate_docker_exec () {
    for CONTAINER; do true; done

    DEST=$(profilerate_docker_cp "$@")
    if [ -n "$DEST" ]
    then
      docker exec -it "$@" "$DEST/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      docker exec -it "$@" sh -c 'PROFILERATE_SHELL=$(command -v zsh || command -v bash || command -v sh) && "$PROFILERATE_SHELL"'
    fi
  }

  profilerate_docker_run () {
    # TODO: This can be optimized by using docker run shell + docker attach using streaming input
    CONTAINER=$(docker run -it --detach --init --entrypoint sh "$@" -c 'while true; do sleep 60; done')

    if [ -n "$CONTAINER" ]; then
      profilerate_docker_exec "$CONTAINER"
      echo Stopping container && docker stop "$CONTAINER"
    fi
  }
fi

### Kubernetes
if [ -x "$(command -v kubectl)" ]; then
  # replicates our configuration to a remote env before running an interactive shell
  profilerate_kubectl () {
    eval "POD=\"\${$#}\""
    __pop_n=$(($# - 1))
    __pop_index=0
    __pop_arguments=""
    while [ $__pop_index -lt $__pop_n ]; do
      __pop_index=$((__pop_index+1))
      __pop_arguments="$__pop_arguments \"\${$__pop_index}\""
    done
    eval "set -- $__pop_arguments"

    # TODO fix for args having spaces
    DEST=$(kubectl exec "$@" $POD -- sh -c "$_PROFILERATE_CREATE_DIR") && \
      _profilerate_copy "kubectl exec -i $ARGS $POD --" "$DEST" >&2 && \
      kubectl exec -it "$@" $POD -- "$DEST/shell.sh"
  }
fi

### SSH
if [ -x "$(command -v ssh)" ]; then
  # ssh [args] HOST to ssh to host and replicate our environment
  profilerate_ssh () {
    RSH="ssh $@"

    # TODO fix for args with spaces
    DEST=$(ssh "$@" "$_PROFILERATE_CREATE_DIR")

    if [ -n "$DEST" ]
    then
      _profilerate_copy "$RSH" "$DEST" >&2 && \
      ssh -t "$@" "$DEST/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      ssh -t "$@" 'PROFILERATE_SHELL=$(command -v zsh || command -v bash || command -v sh) && "$PROFILERATE_SHELL"'
    fi
  }
fi

### VIM SETUP (works with neovim as well)
if [ -f "$PROFILERATE_DIR/vimrc" ]; then
  export VIMINIT="source $PROFILERATE_DIR/vimrc"
fi

### Personal rc file
if [ -f "$PROFILERATE_DIR/personal.sh" ]; then
  . "$PROFILERATE_DIR/personal.sh"
fi
