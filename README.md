# 🐰 profilerate 🐰

Take your dotfiles with you when you log in to remote systems using ssh/kubectl/docker, without impacting other people on the system - even if they're using the same login

## Installation/Upgrades


```
bash <(curl https://raw.githubusercontent.com/jonrad/profilerate/main/install.sh)
```

## Commands

| Command | Description | Example | Notes |
| - | - | - | - |
| profilerate_ssh | SSH into remote box and copy your dotfiles with you | `profilerate_ssh [OTHER SSH ARGS] user@host` | `user@host` must be the last arg (does not take a command) |
| profilerate_kubernetes | Exec into kubernetes pod | `profilerate_kubernetes [OTHER KUBECTL ARGS] POD ` | Host must be the last arg. |
| profilerate_docker_exec | Exec into docker container | `profilerate_docker_exec [DOCKER EXEC ARGS] CONTAINER_ID` | You must start the docker container first |
| profilerate_docker_run | Start a docker container and exec into it | `profilerate_docker_run [DOCKER RUN ARGS] IMAGE` | Shuts down the container when you exit. If you don't want the container to shut down, start it yourself and exec in using `profilerate_docker_exec` |

## Personalizing

Profilerate is pretty useless by itself. What we need to do is make it our own. 

### personal.sh

Modify this file with all your shell scripting goodness. For example:

```
PS1='$(whoami)@$HOSTNAME:$PWD\$ '

if ! ls -lastr --color=auto >/dev/null 2>&1
then
  alias ls="ls -lG"
else
  alias ls="ls -l --color=auto"
fi

alias dr="profilerate_docker_run"
alias de="profilerate_docker_exec"
alias ke="profilerate_kubernetes"
alias s="profilerate_ssh"
```

With the above, whenever you ssh into a different machine, you'll have the same exact prompt. Additionally, some helpful aliases are generated so you don't have to type so much. 

### vimrc
Create a vimrc file in the main profilerate directory. 

### Testing your personal.sh
I recommend using docker to test the different shells:
```
profilerate_docker_run --rm jonrad/profilerate-zsh:latest #Test zsh
profilerate_docker_run --rm jonrad/profilerate-bash:v1 #Test bash
profilerate_docker_run --rm jonrad/profilerate-sh:latest #Test sh (ash)
```

## TODO

* Handle readonly file systems by passing everything as a variable?
* Handle fallback when all else fails

## Caveats
* Doesn't work with readonly file systems (yet)
