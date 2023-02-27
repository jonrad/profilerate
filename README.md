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
PS1='${USER=$(id -un)}@$HOSTNAME:$PWD\$ '

if ! ls -l --color=auto >/dev/null 2>&1
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

## Developing Profilerate
These directions are for people who want to add functionality to profilerate itself and share them with the world (Thank you!). This is *not* for your own personalization 

* First, clone this repo:
```
git clone git@github.com:jonrad/profilerate.git
```

* In a shell, change the environment variable `PROFILERATE_DIR` to the repo path:
```
cd ./profilerate
export PROFILERATE_DIR=$PWD
```

* Now make the changes, after which point you can source `profilerate.sh` in the same shell as above and validate
```
source profilerate.sh
# Do your validation
```

* Once everything works, make sure all the tests still work (See Testing below)
```
./run-tests.sh
```

## Testing
These directions are for people who want to add functionality to profilerate itself and share them with the world (Thank you!). This is *not* for your own personalization 

Finish me

## Security
Profilerate is installed with permissions only for the current user to be able to read/write/execute. The same goes for the destination directory for the files that are profilerated. That is, if you ssh into a different machine as user `jon`, then you'll see the following:

```
/home/jon # echo $PROFILERATE_DIR
/home/jon/.config/profilerated/profilerate.nBHogk

/home/jon # ls -ld /home/jon/.config/profilerated/profilerate.nBHogk
     4 drwx------    3 jon     jon          4096 Feb 26 11:33 /home/jon/.config/profilerated/profilerate.nBHogk
```

This should be sufficient in most cases. HOWEVER, if you are sharing an account with multiple others, they will be able to see inside your profilerated files. If this is a concern, I highly recommend not putting anything sensitive inside your profilerate directory (such as API keys). In addition, if you don't trust the other people sharing that account, they could potentially modify your profilerate files to cause you to run commands you don't want to. However, that's the case regardless of whether you use profilerate or not since they may modify any profile file and rename commands/variables. *tldr:* don't share an account. And if you must, hopefully you trust those people.

## TODO

* Handle readonly file systems by passing everything as a variable? Could this be used to be even more secure?
* Handle fallback when all else fails

## Caveats
* Doesn't work with readonly file systems (yet)
