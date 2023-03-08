### This is your file. Make modifications here

# Warning: make sure to use the most portable code in this file. If
# you want to use something that is shell specific, source it in the if statement below

### Global - Applies to all shells ###
# Examples:
# alias ls="ls -l"
# alias dr="profilerate_docker_run"
# alias de="profilerate_docker_exec"

### Shell specific configurations ###
if [ "$PROFILERATE_SHELL" = "zsh" ]; then
  # Put your zsh specific configuration here
  :
  # You can also create other filea to source and they'll run in the appropriate context
  # (eg you can use zsh specific formatting/functions/etc)
  # . $PROFILERATE_DIR/personal.zsh.sh
elif [ "$PROFILERATE_SHELL" = "bash" ]; then
  # Put your bash specific configuration here
  :
else
  # This is usually something like dash/almquist shell
  # Put your most portable configuration here
  :
fi
