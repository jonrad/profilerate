#!/usr/bin/env false

# This should only be sourced hence the permissions and the shebang

# Set this var to see errors (verbose)
_PROFILERATE_STDERR=${_PROFILERATE_STDERR:-/dev/null}
#_PROFILERATE_TRANSFER_METHODS=${_PROFILERATE_TRANSFER_METHODS:-"hack
#tar
#cat"}
_PROFILERATE_TRANSFER_METHODS=${_PROFILERATE_TRANSFER_METHODS:-"hack tar"}

if [ -z "${PROFILERATE_DIR:-}" ]
then
  PROFILERATE_DIR="$( cd "$( dirname "$0" )" >"${_PROFILERATE_STDERR}" 2>&1 && pwd )"
  export PROFILERATE_DIR
fi

# This occurs when we use ". profilerate.sh". Identifying the shell can be complicated. So let's try the basic and then give up
if [ -z "${PROFILERATE_SHELL}" ]
then
  first_word () {
    # purposely taking only the first word, don't quote
    # shellcheck disable=SC2086
    echo $1
  }

  # Purposely not quoting here to get the first word
  # shellcheck disable=SC2046
  PROFILERATE_SHELL="$(first_word $(ps -p $$ -o command= 2>"${_PROFILERATE_STDERR}" || echo ''))"

  # Login shell sometimes starts with a dash
  if [ "$(echo "${PROFILERATE_SHELL}" | cut -c 1)" = "-" ]
  then
    PROFILERATE_SHELL="$(echo "${PROFILERATE_SHELL}" | cut -c 2-)"
  fi
  PROFILERATE_SHELL=$(basename "${PROFILERATE_SHELL}")
  PROFILERATE_SHELL=${PROFILERATE_SHELL:-"sh"}
fi

# TODO deal with no mktemp
# This is intentionally not expanding expressions, keep single quoted
# shellcheck disable=SC2016
_PROFILERATE_CREATE_DIR='_profilerate_create_dir () {
  if [ ! -d ~/.config ]
  then
    mkdir -m 700 -p ~/.config >&2 || true
  fi

  DEST=$(mkdir -m 700 -p ~/.config/profilerated >&2 && echo -n ~/.config/profilerated || echo "")
  if [ -n "${DEST}" ]
  then
    RESULT=$(mktemp -qd "${DEST}/profilerate.XXXXXX")
  fi

  if [ -z "${RESULT}" ]
  then
    RESULT=$(mktemp -qd "/tmp/.profilerated.XXXXXX")
  fi

  if [ -z "${RESULT}" ]
  then
    RESULT=$(mktemp -qd)
  fi

  if [ -n "${RESULT}" ]
  then
    chmod 700 "${RESULT}" && echo "${RESULT}" && return
  fi

  return 1
}; _profilerate_create_dir'

_profilerate_copy_tar () {
  NONINTERACTIVE_COMMAND="$1"
  INTERACTIVE_COMMAND="$2"

  shift 2
  DEST=$("${NONINTERACTIVE_COMMAND}" "$@" sh -c "${_PROFILERATE_CREATE_DIR}" 2>"${_PROFILERATE_STDERR}") || return 1

  # Try to use tar
  # TODO: how portable is --exclude? We need it to avoid changing perms on the directory we created
  if [ -x "$(command -v tar)" ]; then
    # someone explain to me why ssh skips the first command when calling sh -c or if i'm losing it
    if tar -c -f - -C "${PROFILERATE_DIR}/" --exclude '.git' --exclude '.github' --exclude '.gitignore' -h . 2>"${_PROFILERATE_STDERR}" | \
      "${NONINTERACTIVE_COMMAND}" "$@" sh -c ":; cd ${DEST} && tar --exclude ./ -o -x -f -" >"${_PROFILERATE_STDERR}" 2>&1
    then
      "${INTERACTIVE_COMMAND}" "$@" "${DEST}/shell.sh"
      return
    fi
  fi
  
  return 1
}

_profilerate_copy_cat () {
  NONINTERACTIVE_COMMAND="$1"
  INTERACTIVE_COMMAND="$2"

  shift 2

  # If all else fails, transfer the files one at a time
  # Loop through all the files and transfer them via cat
  # note we're optimizing for connection count
  # i wonder if we can do this as one command... (echo "Abc" > foo; echo "foo" > bar;)
  # certainly with something like base64 or od, but is that more efficient? And is it more portable?
  cd "${PROFILERATE_DIR}" || return 1
  FILES=$(find . -not -path './.git/*' -not -path './.git' -not -path './.gitignore' -not -path './.github/*' -not -path './.github')

  # this is usually fast enough that we don't need to warn the user
  # except when there's a lot of files
  if [ "$(echo "${FILES}" | wc -l 1>/dev/null 2>&1)" -gt 20 ]
  then
    echo "profilerate failed to use tar to copy files. Using manual transfer, which may take some time since you have many files to transfer">&2
  fi

  MKDIR=""
  while read -r FILENAME
  do
    if [ -d "${FILENAME}" ]
    then
      if [ "${FILENAME}" != "." ]
      then
        # if you know a better, more portable and efficient way to check file perms, let me know
        MKDIR="${MKDIR}mkdir -m $(($([ -r "${FILENAME}" ] && echo 4) + $([ -w "${FILENAME}" ] && echo 2) + $([ -x "${FILENAME}" ] && echo 1) + 0))00 -p \"${FILENAME}\";"
      fi
    fi
  done<<EOF
${FILES}
EOF

  DEST=$($NONINTERACTIVE_COMMAND "$@" sh -c ":;DEST=\$\(${_PROFILERATE_CREATE_DIR}\);cd ${DEST};${MKDIR}") || return 1

  CHMOD=""
  while read -r FILENAME
  do
    if [ -f "${FILENAME}" ]
    then
      CHMOD="${CHMOD}chmod $(($(test -r "${FILENAME}" && echo 4) + $(test -w "${FILENAME}" && echo 2) + $(test -x "${FILENAME}" && echo 1) + 0))00 \"${FILENAME}\";"
      $NONINTERACTIVE_COMMAND "$@" sh -c ":;cat > ${DEST}/${FILENAME}" < "${FILENAME}"
    fi
  done<<EOF
${FILES}
EOF

  $NONINTERACTIVE_COMMAND "$@" sh -c ":;cd ${DEST};${CHMOD}"

  cd - >/dev/null || true
  "${INTERACTIVE_COMMAND}" "$@" "${DEST}/shell.sh"
}

_profilerate_copy () {
  NONINTERACTIVE_COMMAND="$1"
  INTERACTIVE_COMMAND="$2"

  shift 2
  setopt shwordsplit 2>/dev/null
  for COPY_METHOD in $_PROFILERATE_TRANSFER_METHODS
  do
    FUNCTION="_profilerate_copy_${COPY_METHOD}"
    if [ -n "$(command -v $FUNCTION)" ]; then
      echo "Using ${FUNCTION} to transfer">"${_PROFILERATE_STDERR}"
      $FUNCTION $NONINTERACTIVE_COMMAND $INTERACTIVE_COMMAND "$@" && return
    else
      echo "${FUNCTION} Not found">"${_PROFILERATE_STDERR}"
    fi
  done
  unsetopt shwordsplit 2>/dev/null

  echo Failed to profilerate, starting standard shell >&2 && 
      $INTERACTIVE_COMMAND "$@" sh -c '$(command -v "${SHELL:-zsh}" || command -v zsh || command -v bash || command -v sh) -l'

  return 1
}

### Docker
if [ -x "$(command -v docker)" ]; then
  # replicates our configuration to a container before running an interactive bash
  _profilerate_docker_noninteractive_command () {
    docker exec -i "$@"
  }

  _profilerate_docker_interactive_command () {
    docker exec -it "$@"
  }

  profilerate_docker_exec () {
    if [ "$#" = 0 ]
    then
      echo 'profilerate_docker_exec has the same args as "docker exec", except for COMMAND. See below' >&2
      docker exec --help >&2
      return
    fi

    _profilerate_copy "_profilerate_docker_noninteractive_command" "_profilerate_docker_interactive_command" "$@"
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

    if [ -n "${CONTAINER}" ]; then
      profilerate_docker_exec "${CONTAINER}"
      echo Stopping container && docker stop "${CONTAINER}"
    fi
  }
fi

### Kubernetes
if [ -x "$(command -v kubectl)" ]; then
  # replicates our configuration to a remote env before running an interactive shell
  profilerate_kubectl_exec () {
    if [ "$#" = 0 ]
    then
      echo 'profilerate_kubectl_exec has the same args as "kubectl exec", except for COMMAND. See below' >&2
      kubectl exec --help >&2
      return
    fi
    DEST=$(kubectl exec -i "$@" -- sh -c "${_PROFILERATE_CREATE_DIR}" 2>"${_PROFILERATE_STDERR}")

    if [ -n "${DEST}" ]
    then
      _profilerate_copy "${DEST}" kubectl exec -i "$@" -- >"${_PROFILERATE_STDERR}" 2>&1 && \
        kubectl exec -it "$@" -- "${DEST}/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      # purposely using the remote systems $SHELL var
      # shellcheck disable=SC2016
      kubectl exec -it "$@" -- sh -c '$(command -v "${SHELL}" || command -v zsh || command -v bash || command -v sh) -l'
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
    DEST=$(ssh "$@" "${_PROFILERATE_CREATE_DIR}" 2>"${_PROFILERATE_STDERR}")

    if [ -n "${DEST}" ]
    then
      _profilerate_copy "${DEST}" ssh "$@" >"${_PROFILERATE_STDERR}" 2>&1 && \
        ssh -t "$@" "exec ${DEST}/shell.sh"
    else
      echo Failed to profilerate, starting standard shell >&2
      ssh -t "$@" '$(command -v "${SHELL}" || command -v zsh || command -v bash || command -v sh) -l'
    fi
  }
fi

### VIM SETUP (works with neovim as well)
# vim uses vimrc, but so does nvim
# nvim uses init.vim or init.lua, but vim does not

NVIM_FILE=""
VIM_FILE=""
if [ -f "${PROFILERATE_DIR}/init.lua" ]
then
  NVIM_FILE="init.lua"
elif [ -f "${PROFILERATE_DIR}/init.vim" ]
then
  NVIM_FILE="init.vim"
fi

if [ -f "${PROFILERATE_DIR}/vimrc" ]
then
  VIM_FILE="vimrc"
fi

if [ -n "${VIM_FILE}" ] && [ -n "${NVIM_FILE}" ]
then
  VIMINIT="
let is_nvim = has('nvim')
if is_nvim
  :source ${PROFILERATE_DIR}/${NVIM_FILE}
else
  :source ${PROFILERATE_DIR}/${VIM_FILE}
endif"
elif [ -n "${VIM_FILE}" ]
then
  VIMINIT=":source ${PROFILERATE_DIR}/${VIM_FILE}"
elif [ -n "${NVIM_FILE}" ]
then
  VIMINIT="
let is_nvim = has('nvim')
if is_nvim
  :source ${PROFILERATE_DIR}/${NVIM_FILE}
endif"
fi

if [ -n "${VIMINIT}" ]
then
  export VIMINIT
fi



### Inputrc setup
if [ -f "${PROFILERATE_DIR}/inputrc" ]
then
  export INPUTRC="${PROFILERATE_DIR}/inputrc"
fi

### Personal rc file
if [ -f "${PROFILERATE_DIR}/personal.sh" ]; then
  . "${PROFILERATE_DIR}/personal.sh"
fi

# If running a subshell, having a preset PROFILERATE_SHELL will confuse it, so unset
unset PROFILERATE_SHELL
