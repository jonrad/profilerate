# 🐰 profilerate 🐰

Take your dotfiles with you when you log in to remote systems using ssh/kubectl/docker, without impacting other people on the system - even if they're using the same login

## Installation

One day I'll write a proper installation script, but in the meantime the manual way to do this:

```
~ $ git clone git@github.com:jonrad/profilerate.git
Cloning into 'profilerate'...
-- SNIP --
~ $ PROFILERATE_ID=".CHANGEME_profilerate" #change CHANGEME to something unique. Your name perhaps
~ $ mkdir $PROFILERATE_ID
~ $ cp profilerate/profilerate.sh profilerate/shell.sh $PROFILERATE_ID/
```

Great, now we need to actually use it.
Modify your `.zshrc` and add the following line (Change CHANGEME based on what you input above):

```
source ~/.CHANGEME_profilerate/profilerate.sh
```

All done! Now try it out by either opening a new terminal or reloading your zshrc:

```
~ $ source ~/.zshrc
Success! Next steps: add your personal preferences in ~/.CHANGEME_profilerate/personal.sh
```

## Try It Out!

Cheatsheet:

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
alias dr="profilerate_docker_run"
alias de="profilerate_docker_exec"
alias ke="profilerate_kubernetes"
alias s="profilerate_ssh"
```

With the above, whenever you ssh into a different machine, you'll have the same exact prompt. Additionally, some helpful aliases are generated so you don't have to type so much. 

### vimrc
Create a vimrc file in the main profilerate directory. 

## TODO

* Better directory handling
* update readme
* fallback
* rest of tests
* get rid of profilerate_id
* Installation script
* Handle readonly file systems by passing everything as a variable?

* `tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`

## Caveats
Doesn't work with readonly file systems
