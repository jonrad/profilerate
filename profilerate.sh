#V2

profilerate_debug () {
  if [ ! -z "$PROFILERATE_DEBUG" ]; then
    echo "PROFILERATE profilerate_debug: $1"
  fi
}

DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

shell=$(ps -p $$ | awk '$1 != "PID" {print $(NF)}')

profilerate_debug "Shell set to $shell"

if [ -f "$HOME/.bashrc" ]; then
  profilerate_debug "Loading $HOME/.bashrc"
  . "$HOME/.bashrc"
fi
 
if [ -z "$PROFILERATE_ID" ]; then
  export PROFILERATE_ID=$(basename $DIR)
  if [[ "$PROFILERATE_ID" == "profilerate" ]]; then
    export PROFILERATE_ID=
    echo "This script must exist in a uniquely named directory. Please rename dir to something other than 'profilerate'"
    return
  fi
fi

profilerate_debug "PROFILERATE_ID=$PROFILERATE_ID"


# PROFILERATE_DIR is where the config files are located in this install
# Sometimes looking at the script dir doesn't work when using bash with the --init-file flag
# so we have to do some digging
if [ -f "$DIR/profilerate.sh" ]; then
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
  profilerate_docker () {
    CONTAINER=$1
    shift

    eval "docker exec $CONTAINER $@ rm -rf $PROFILERATE_ID" && \
    eval "docker cp $PROFILERATE_DIR $CONTAINER:$PROFILERATE_ID $@" && \
    eval "docker exec -it $CONTAINER $@ sh -c /$PROFILERATE_ID/shell.sh"
  }
fi

### Kubernetes
if [ -x "$(command -v kubectl)" ]; then
  profilerate_debug "Detected kubectl"
  alias profilerate_kubectl="kubectl"
  profilerate_kubectl="kubectl"

  # kb replicates our configuration to a remote env before running an interactive bash
  function profilerate_kubernetes {
    POD=$1
    shift

    if [[ $POD == -* ]]; then
      echo "pod id must be the first argument"
      return
    fi

    eval "$profilerate_kubectl exec $POD $@ -- rm -rf /tmp/$PROFILERATE_ID" && \
    eval "$profilerate_kubectl cp $PROFILERATE_DIR $POD:/tmp/$PROFILERATE_ID $@" && \
    eval "$profilerate_kubectl exec -it $POD $@ -- sh -c /tmp/$PROFILERATE_ID/shell.sh"
  }

  # helper function to build our kubectl command to use namespace and context
  function profilerate_build_kubectl {
    profilerate_kubectl="kubectl"
    if [ -n "$PROFILERATE_KUBE_CONTEXT" ]; then
      profilerate_kubectl="$profilerate_kubectl --context=$PROFILERATE_KUBE_CONTEXT"
    fi
    if [ -n "$PROFILERATE_KUBE_NAMESPACE" ]; then
      profilerate_kubectl="$profilerate_kubectl --namespace=$PROFILERATE_KUBE_NAMESPACE"
    fi

    alias profilerate_kubectl="$profilerate_kubectl"

    __kubectl_parse_get()
    {
        curr_arg=${COMP_WORDS[COMP_CWORD]}
        local template
        template="${2:-"{{ range .items  }}{{ .metadata.name }} {{ end }}"}"
        local kubectl_out
        if kubectl_out=$($profilerate_kubectl get $(__kubectl_override_flags) -o template --template="${template}" "$1" 2>/dev/null);
then
            COMPREPLY+=( $( compgen -W "${kubectl_out[*]}" -- "$curr_arg" ) )
        fi
    }
  }

  # set kubectl context for the environment
  function profilerate_kctx {
    if [ $# -eq 0 ]; then
      kubectl config get-contexts
      return
    fi

    export PROFILERATE_KUBE_CONTEXT=$1
    profilerate_build_kubectl
  }

  # set kubectl namespace for the environment
  function profilerate_kns {
    if [ $# -eq 0 ]; then
      kubectl get ns
      return
    else
      export PROFILERATE_KUBE_NAMESPACE=$1
    fi
    profilerate_build_kubectl
  }

  # attempt to get completions to work
  source <(kubectl completion $shell)

  if [[ ! "$shell" == "zsh" ]]; then

    complete -F __kubectl_get_resource_namespace profilerate_kns
    complete -F __kubectl_config_get_contexts profilerate_kctx

    if [[ $(type -t compopt) = "builtin" ]]; then
        complete -o default -F __start_kubectl k
    else
        complete -o default -o nospace -F __start_kubectl k
    fi
  fi

  complete -F __kubectl_get_resource_namespace profilerate_kns
  complete -F __kubectl_config_get_contexts profilerate_kctx
  complete -F __kubectl_get_resource_pod kb

fi

### SSH
# Use su to switch to root and use our configuration. Stop using sudo su!
alias profilerate_su="sudo -H -s bash $PROFILERATE_DIR/shell.sh"

# s HOST [args] to ssh to host and replicate our environment
function profilerate_ssh {
  HOST=$1
  shift
  ARGS=$@

  rsync -r $PROFILERATE_DIR $HOST:/tmp/ -e "ssh $ARGS" && \
  ssh -t $HOST /tmp/$PROFILERATE_ID/shell.sh
}

### VIM SETUP
if [ -f $PROFILERATE_DIR/vimrc ]; then
  export VIMINIT="source $PROFILERATE_DIR/vimrc"
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f "$PROFILERATE_DIR/personal.sh" ]; then
  profilerate_debug "Loading personal settings"
  source "$PROFILERATE_DIR/personal.sh"
else
  profilerate_debug "No personal settings found in $PROFILERATE_DIR/personal.sh"
fi

unset -f profilerate_debug
