### This is your file. Make modifications here

### Global - Applies to all shells ###
# alias ls="ls -l"
# alias dr="profilerate_docker_run"
# alias de="profilerate_docker_exec"

alias k="profilerate_kubectl"
alias de="profilerate_docker_exec"
alias dr="profilerate_docker_run"
alias ke="profilerate_kubernetes"
alias s="profilerate_ssh"
alias kns="profilerate_kns"
alias kctx="profilerate_kctx"

if [ "$PROFILERATE_SHELL" = "zsh" ]; then
  alias ls="ls -lastrG"
else
  alias ls="ls -lastr --color=auto"
fi

export PAGER="less -XF"
alias less="less -XF"

# better search history
if [ -n "$(command -v bind)" ]; then
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
  bind '"\e[1;3C": forward-word'
  bind '"\e[1;3D": backward-word'
fi

if [ ! $PROFILERATE_SHELL = "zsh" ]; then
  export PS1="\[\033]0;\u|\h|\$PWD||\$PREPROMPT|\007\[\e[32m\]\$PWD\[\e[m\] \\$ "
fi

### Shell specific configurations ###
if [ "$PROFILERATE_SHELL" = "zsh" ]; then
  # Put your zsh specific configuration here
  . $PROFILERATE_DIR/personal.zsh
  echo "Profilerate: Logged into zsh"
elif [ "$PROFILERATE_SHELL" = "bash" ]; then
  # Put your bash specific configuration here
  echo "Profilerate: Logged into bash"
else
  # This is usually something like almquist shell
  # Put your most standard configuration here
  echo "Profilerate: Logged into an unknown shell"
fi
