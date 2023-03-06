#!/usr/bin/env false

# This should only be sourced hence the permissions and the shebang

if [ -z "${PROFILERATE_DIR:-}" ]
then
  PROFILERATE_DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
  export PROFILERATE_DIR
fi

if [ -z "$PROFILERATE_SHELL" ]
then
  first_word () {
    echo $1
  }

  # This occurs when we use ". profilerate.sh". Identifying the shell can be complicated. So let's try the basic and then give up
  PROFILERATE_SHELL=$(basename $(first_word $(ps -p $$ -o command= 2>/dev/null || echo '')))
  PROFILERATE_SHELL=${PROFILERATE_SHELL:-"sh"}
fi

# TODO deal with no mktemp
# This is intentionally not expanding expressions, keep single quoted
# shellcheck disable=SC2016
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
  DEST=$1
  shift

  # Try to use tar
  # TODO: how portable is --exclude? We need it to avoid changing perms on the directory we created
  if [ -x "$(command -v tar)" ]; then
    # someone explain to me why ssh skips the first command when calling sh -c or if i'm losing it
    tar -c -f - -C "$PROFILERATE_DIR/" -L . 2>/dev/null | "$@" sh -c ":; cd $DEST && tar --exclude ./ -o -x -f -" >/dev/null 2>&1 && return
  fi

  # If all else fails, transfer the files one at a time
  # Loop through all the files and transfer them via cat
  # note we're optimizing for connection count
  # i wonder if we can do this as one command... (echo "Abc" > foo; echo "foo" > bar;)
  # certainly with something like base64 or od, but is that more efficient? And is it more portable?
  cd "$PROFILERATE_DIR" || return 1
  FILES=$(find .)

  # this is usually fast enough that we don't need to warn the user
  # except when there's a lot of files
  if [ "$(echo "$FILES" | wc -l)" -gt 20 ]
  then
    echo "profilerate failed to use rsync or tar to copy files. Using manual transfer, which may take some time since you have many files to transfer"
  fi

  MKDIR=""
  while IFS= read -r FILENAME
  do
    if [ -d "$FILENAME" ]
    then
      if [ "$FILENAME" != "." ]
      then
        MKDIR="${MKDIR}mkdir -m $(stat -f %Mp%Lp "$FILENAME") -p \"$FILENAME\";"
      fi
    fi
  done<<EOF
$FILES
EOF

  "$@" sh -c ":;cd $DEST;$MKDIR"

  CHMOD=""
  while IFS= read -r FILENAME
  do
    if [ -f "$FILENAME" ]
    then
      CHMOD="${CHMOD}chmod $(stat -f %Mp%Lp "$FILENAME") \"$FILENAME\";"
      "$@" sh -c ":;cat > $DEST/$FILENAME" < "$FILENAME"
    fi
  done<<EOF
$FILES
EOF

  "$@" sh -c ":;cd $DEST;$CHMOD"

  cd - >/dev/null || true
}

### Docker
if [ -x "$(command -v docker)" ]; then
  # replicates our configuration to a container before running an interactive bash
  profilerate_docker_cp () {
    DEST=$(docker exec "$@" sh -c "$_PROFILERATE_CREATE_DIR") && \
      _profilerate_copy "$DEST" docker exec -i "$@" >&2 && \
      echo "$DEST" && \
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
      _profilerate_copy "$DEST" kubectl exec -i "$@" -- >&2 && \
        kubectl exec -it "$@" -- "$DEST/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      # purposely using the remote systems $SHELL var
      # shellcheck disable=SC2016
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

    # we want this to run on the client side
    # shellcheck disable=SC2029
    DEST=$(ssh "$@" "$_PROFILERATE_CREATE_DIR")

    if [ -n "$DEST" ]
    then
      _profilerate_copy "$DEST" ssh "$@" >&2 && \
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

# If running a subshell, having a preset PROFILERATE_SHELL will confuse it, so unset
unset PROFILERATE_SHELL
