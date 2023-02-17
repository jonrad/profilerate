### This is your file. Make modifications here

### Global - Applies to all shells ###
# alias ls="ls -l"
# alias dr="profilerate_docker_run"
# alias de="profilerate_docker_exec"

### Shell specific configurations ###
if [ "$PROFILERATE_SHELL" = "zsh" ]; then
  # Put your zsh specific configuration here
  echo "Profilerate: Logged into zsh"
elif [ "$PROFILERATE_SHELL" = "bash" ]; then
  # Put your bash specific configuration here
  echo "Profilerate: Logged into bash"
else
  # This is usually something like almquist shell
  # Put your most standard configuration here
  echo "Profilerate: Logged into an unknown shell"
fi
