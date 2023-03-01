#!/usr/bin/env sh

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

  # Try to use tar
  # TODO: how portable is --exclude? We need it to avoid changing perms on the directory we created
  if [ -x "$(command -v tar)" ]; then
    tar -c -f - -C "$PROFILERATE_DIR/" . | eval "$RSH sh -c 'cd $DEST && tar --exclude ./ -o -x -f -'" >/dev/null >&2 && return
  fi

  # If all else fails, transfer the files one at a time
  # Loop through all the files and transfer them via cat
  # note we're optimizing for connection count
  # i wonder if we can do this as one command... (echo "Abc" > foo; echo "foo" > bar;)
  # certainly with something like base64 or od, but is that more efficient? And is it more portable?
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
    RSH="docker exec -i $@"
    DEST=$(docker exec "$@" sh -c "$_PROFILERATE_CREATE_DIR") && \
      _profilerate_copy "$RSH" "$DEST" >&2 && \
      echo $DEST && \
      return

    return 1
  }

  profilerate_docker_exec () {
    if [ "$#" = 0 ]
    then
      echo 'profilerate_docker_exec has the same args as "docker exec", except for COMMAND. See below' >&2
      docker exec --help >&2
      return
    fi

    DEST=$(profilerate_docker_cp "$@")
    if [ -n "$DEST" ]
    then
      docker exec -it "$@" "$DEST/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      docker exec -it "$@" sh -c '$(command -v "$SHELL" || command -v zsh || command -v bash || command -v sh) -l'
    fi
  }

  profilerate_docker_run () {
    if [ "$#" = 0 ]
    then
      echo 'profilerate_docker_run has the same args as "docker run", except for COMMAND. See below' >&2
      docker run --help >&2
      return
    fi

    # TODO: This may be optimized by using docker run shell + docker attach using streaming input
    CONTAINER=$(docker run -it --detach --init --entrypoint sh "$@" -c 'while true; do sleep 600; done')

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
    if [ "$#" = 0 ]
    then
      echo 'profilerate_kubectl has the same args as "kubectl exec", except for COMMAND. See below' >&2
      kubectl exec --help >&2
      return
    fi
    DEST=$(kubectl exec -i "$@" -- sh -c "$_PROFILERATE_CREATE_DIR")

    if [ -n "$DEST" ]
    then
      RSH="kubectl exec -i $@ --"
      _profilerate_copy "$RSH" "$DEST" >&2 && \
        kubectl exec -it "$@" -- "$DEST/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      kubectl exec -it "$@" -- sh -c '$(command -v "$SHELL" || command -v zsh || command -v bash || command -v sh) -l'
    fi
  }
fi

### SSH
if [ -x "$(command -v ssh)" ]; then
  # ssh [args] HOST to ssh to host and replicate our environment
  profilerate_ssh () {
    if [ "$#" = 0 ]
    then
      echo 'profilerate_ssh has the same args as ssh, except for [command]. See below' >&2
      ssh >&2
      return
    fi
    RSH="ssh $@"

    # TODO fix for args with spaces
    DEST=$(ssh "$@" "$_PROFILERATE_CREATE_DIR")

    if [ -n "$DEST" ]
    then
      _profilerate_copy "$RSH" "$DEST" >&2 && \
      ssh -t "$@" "$DEST/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      ssh -t "$@" '$(command -v "$SHELL" || command -v zsh || command -v bash || command -v sh) -l'
    fi
  }
fi

### VIM SETUP (works with neovim as well)
if [ -f "$PROFILERATE_DIR/vimrc" ]; then
  export VIMINIT="source $PROFILERATE_DIR/vimrc"
fi

### Inputrc setup
if [ -f "$PROFILERATE_DIR/inputrc" ]; then
  export INPUTRC="$PROFILERATE_DIR/inputrc"
fi

### Personal rc file
if [ -f "$PROFILERATE_DIR/personal.sh" ]; then
  . "$PROFILERATE_DIR/personal.sh"
fi
