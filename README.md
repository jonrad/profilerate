# 🐰 profilerate 🐰

Take your dotfiles with you when you log in to remote systems using ssh/kubectl/docker, without impacting other people on the system.

This is done by create commands to replace your standard `ssh`/`docker exec`/`kubectl exec` that automatically copy the `profilerate` directory, including all your personalizations, to the systems you log into.
The `profilerate_*` commands are automatically available to use in the remote system as well, for the use in jump hosts.

Pronunciation: Like proliferate, but with the `l` and the `r` exchanged.

# Table of Contents

- [tldr](#tldr)
- [Features](#features)
- [Installation/Upgrades](#installationupgrades)
  - [Using Curl - Quickest Setup](#using-curl---quickest-setup)
  - [With Version Control](#with-version-control)
  - [Manually](#manually)
- [Commands](#commands)
  - [SSH Examples](#ssh-examples)
  - [Docker examples](#docker-examples)
    - [Docker Run](#docker-run)
    - [Docker Exec](#docker-exec)
  - [Kubernetes](#kubernetes)
- [Personalizing](#personalizing)
  - [personal.sh](#personalsh)
  - [vimrc](#vimrc)
    - [neovim and vim](#neovim-and-vim)
    - [vi](#vi)
  - [inputrc](#inputrc)
  - [Testing your personal.sh](#testing-your-personalsh)
- [Security](#security)
- [Developing Profilerate](#developing-profilerate)
- [Automated Tests](#automated-tests)
- [TODO](#todo)
- [Debugging](#debugging)
- [Thank yous, prior art, and cool stuff:](#thank-yous-prior-art-and-cool-stuff)

## tldr
* [Install](#installationupgrades)
* Modify `~/.config/profilerate/personal.sh`, `~/.config/profilerate/init.[vim|lua]`, `~/.config/profilerate/vimrc`, `~/.config/profilerate/inputrc` and add any other files to your profilerate dir you want to take with you when you remote into another system
* Use `profilerate_ssh` instead of `ssh`, use `profilerate_docker_[run|exec]` instead of `docker [run|exec]`,  and `profilerate_kubectl_exec` instead of `kubectl exec` (aliases for the long command names are recommended)
* When you remote into another system, you'll notice your $PROFILERATE_DIR environment variable containing all the files you had on your local system. Your `personal.sh` is automatically sourced and your nvim/vim will use your init file or vimrc.

## Features

* Copy your startup scripts and anything else in your `$PROFILERATE_DIR` directory with you when you log into remote systems
* Does not impact any of the remote rc files (does not impact other people on the system, even if they share the same user)
* Supports `ssh`, `kubectl exec`, `docker run` and `docker exec`
* Uses most modern shell with fallbacks: `zsh`, then `bash`, then `sh`
* Transfers files to `HOME` directory first and falls back to `tmp` directory if `HOME` doesn't exist or is readonly
* Supports both neovim and vim (with limited support for vi. See Section on vim, below)
* Supports inputrc
* Is not limited to text files - Can transfer binary files if you feel they will be compatible with the remote system
* When all else fails, will fall back to using standard commands without profilerate (eg. when the remote file system is completely readonly)

## Installation/Upgrades

### Using Curl - Quickest Setup
```bash
bash <(curl https://raw.githubusercontent.com/jonrad/profilerate/main/install.sh)
```

Profilerate is installed in `~/.config/profilerate`

### With Version Control
* Create a project from [profilerate-template](https://github.com/jonrad/profilerate-template)
* Clone locally and change permissions:
```bash
git clone <REPO_URL> ~/.config/profilerate
chmod 700 ~/.config/profilerate
```
* Add the following line to your shell's rc file (`.zshrc` and/or `.bashrc`)
```bash
. ~/.config/profilerate/profilerate.sh
```

### Manually
* [Download the latest tarball](https://github.com/jonrad/profilerate/releases/download/main/profilerate.latest.tar.gz)
```bash
wget https://github.com/jonrad/profilerate/releases/download/main/profilerate.latest.tar.gz
```
* Extract and change permissions
```bash
DEST=~/.config/profilerate && \
  echo "$DEST" && \
  mkdir -p "$DEST" && \
  tar xfvz profilerate.latest.tar.gz -C "$DEST" && \
  chmod 700 "$DEST"
```
* Add the following line to your shell's rc file (`.zshrc` and/or `.bashrc`)
```bash
. ~/.config/profilerate/profilerate.sh
```

## Commands

| Command | Description | Example | Notes |
| - | - | - | - |
| profilerate_ssh | SSH into remote box and copy your dotfiles with you. Takes the same arguments as the standard `ssh` command | `profilerate_ssh [OTHER SSH ARGS] DESTINATION` | `DESTINATION` must be the last arg (does not take a command) |
| profilerate_kubectl_exec | Exec into kubernetes pod. Takes the same arguments as the `kubectl exec` command | `profilerate_kubectl_exec [OTHER KUBECTL ARGS] POD ` | POD must be the last arg. |
| profilerate_docker_exec | Exec into docker container. Takes the same arguments as the `docker exec` command | `profilerate_docker_exec [DOCKER EXEC ARGS] CONTAINER_ID` | You must start the docker container first |
| profilerate_docker_run | Start a docker container and exec into it. Takes the same arguments as the `docker run` command | `profilerate_docker_run [DOCKER RUN ARGS] IMAGE` | Shuts down the container when you exit. If you don't want the container to shut down, start it yourself and exec in using `profilerate_docker_exec` |

### SSH Examples

Basic example:
```console
# Show what I set up as my personal.sh file (see below for customizing)
jonrad@local$ cat $PROFILERATE_DIR/personal.sh
PS1='${USER:-$(whoami)}@$HOSTNAME$ ' # user@hostname prompt
alias ls="ls -la" # Show hidden files and use long format

# profilerate SSH into a remote machine
jonrad@local$ profilerate_ssh ubuntu@remote-machine
ubuntu@remote-machine$ echo $PS1 #Note that the PS1 followed me
${USER:-$(whoami)}@$HOSTNAME$

# show how ls uses the alias i defined in my personal.sh
ubuntu@remote-machine$ ls
total 20
drwx------    1 ubuntu   ubuntu        4096 Mar  1 12:06 .
drwxr-xr-x    1 ubuntu   ubuntu        4096 Mar  1 12:06 ..
-rw-r--r--    1 ubuntu   ubuntu          27 Feb 28 21:28 .bash_profile
drwx------    3 ubuntu   ubuntu        4096 Mar  1 12:06 .config
drwx------    2 ubuntu   ubuntu        4096 Feb 21 23:00 .ssh

# note that there is now a special $PROFILERATE_DIR variable that has the location of your profilerate files
ubuntu@remote-machine$ ls -ld $PROFILERATE_DIR/
drwx------    6 ubuntu   ubuntu        4096 Mar  1 12:06 /home/ubuntu/.config/profilerated/profilerate.aCohPC/

# This is the same as the one on your local machine
ubuntu@remote-machine$ cat $PROFILERATE_DIR/personal.sh
PS1='${USER:-$(whoami)}@$HOSTNAME$ '
alias ls="ls -la" # Show hidden files and use long format
```

More examples:
```console
# Equivalent to: ssh -t -i ~/.ssh/id_rsa 192.168.0.1
$ profilerate_ssh -i ~/.ssh/id_rsa 192.168.0.1

# profilerate_ssh passes all args to ssh, except for command. So it supports all args of ssh
$ profilerate_ssh # Your output may vary depending on your flavor of ssh
profilerate_ssh has the same args as ssh, except for [command]. See below
usage: ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface]
           [-b bind_address] [-c cipher_spec] [-D [bind_address:]port]
           [-E log_file] [-e escape_char] [-F configfile] [-I pkcs11]
           [-i identity_file] [-J [user@]host[:port]] [-L address]
           [-l login_name] [-m mac_spec] [-O ctl_cmd] [-o option] [-p port]
           [-Q query_option] [-R address] [-S ctl_path] [-W host:port]
           [-w local_tun[:remote_tun]] destination [command]
```

### Docker examples

#### Docker Run
**Note:** See ssh example, above, for full walk through.

`profilerate_docker_run` is used to start up a container, send the contents of your profilerate dir, start up a shell, and then cleanup once you exit the shell:

```console
jonrad@local$ profilerate_docker_run alpine
root@bdec5a2fb003$ cd ~
root@bdec5a2fb003$ ls
total 16
drwx------    1 root     root          4096 Mar  1 13:16 .
drwxr-xr-x    1 root     root          4096 Mar  1 13:16 ..
-rw-------    1 root     root             8 Mar  1 13:16 .ash_history
drwx------    3 root     root          4096 Mar  1 13:16 .config
root@bdec5a2fb003$

# you can pass all the same args as "docker run"
jonrad@local$ profilerate_docker_run -e "ENV_VAR=foo" -v /tmp/shared:/shared "alpine"
root@dd03ec236aee$ echo $ENV_VAR
foo
root@dd03ec236aee$ ls /shared
total 8
drwxr-xr-x    3 root     root            96 Mar  1 13:18 .
drwxr-xr-x    1 root     root          4096 Mar  1 13:19 ..
-rw-r--r--    1 root     root             6 Mar  1 13:18 hello
```

#### Docker Exec
**Note:** See ssh example, above, for full walk through.

`profilerate_docker_exec` is used to exec into a container that has already been started. First it sends the contents of the profilerate dir then it starts up a shell with your personal file executed.

```console
jonrad@local$ docker run --rm --detach --name "my-container" alpine sleep infinity
a6fbb0085c6feefeea043c3fe5aed2e019bb005e8808ca8513dc30462e77a213
jonrad@local$ docker ps
CONTAINER ID   IMAGE     COMMAND            CREATED         STATUS         PORTS     NAMES
a6fbb0085c6f   alpine    "sleep infinity"   2 seconds ago   Up 2 seconds             my-container

jonrad@local$ profilerate_docker_exec my-container
root@a6fbb0085c6f$

# You can pass in all the same args as "docker exec"
jonrad@local$ profilerate_docker_exec -e FOO=BAR my-container
root@a6fbb0085c6f$ echo $FOO
BAR
```

### Kubernetes
**Note:** See ssh example, above, for full walk through.

`profilerate_kubectl_exec` is used to exec into a kubernetes pod, just like `kubectl exec`
```console
jonrad@local$ kubectl get po -A
NAMESPACE            NAME                                                      READY   STATUS    RESTARTS   AGE
default              nginx                                                     1/1     Running   0          66s
kube-system          coredns-565d847f94-2kc97                                  1/1     Running   0          2m24s

jonrad@local$ profilerate_kubectl_exec -n default nginx
# Note that it brought our PS1 with us as well as our ls alias
root@nginx$ ls
total 96
drwxr-xr-x   1 root root 4096 Mar  1 21:26 .
drwxr-xr-x   1 root root 4096 Mar  1 21:26 ..
drwxr-xr-x   2 root root 4096 Feb 27 00:00 bin
```

## Personalizing

Profilerate is pretty useless by itself. What we need to do is make it our own.

### personal.sh

Modify this file with all your shell scripting goodness. For example:

```bash
# Make a consistent PS1 that helps us identify who and where we are
PS1='${USER:=$(id -un)}@$HOSTNAME:$PWD\$ '

# Add color to our ls command
if ! ls -l --color=auto >/dev/null 2>&1
then
  alias ls="ls -lG"
else
  alias ls="ls -l --color=auto"
fi

# helpful aliases to not have to type as much
alias dr="profilerate_docker_run"
alias de="profilerate_docker_exec"
alias ke="profilerate_kubectl_exec"
alias s="profilerate_ssh"
```

### vimrc

#### neovim and vim
Copy (or symlink) either a `init.lua`, `init.vim` or `vimrc` file to your profilerate directory. It will follow you to the remote machines and will use the appropriate file based on whether you're using nvim or vim. This takes advantage of the `VIMINIT` environment variable.

#### vi

vi isn't handled due to lack of standardization. For example, busybox vi doesn't have the `source` command, while `nvi` on ubuntu does. If you are frequently using busybox/alpine vi, I recommend setting the `EXINIT` environment variable in your `personal.sh` based on the version of vi you find yourself encountering. Or, copy a standalone version of vim into your profilerate directory :smile:

### inputrc
Create/copy/symlink a `inputrc` (no dot) file in the main profilerate directory. It will be loaded by setting the INPUTRC environment variable.

### Testing your personal.sh
I recommend using docker to test the different shells:
```bash
profilerate_docker_run --rm jonrad/profilerate-zsh:latest #Test zsh
profilerate_docker_run --rm jonrad/profilerate-bash:v1 #Test bash
profilerate_docker_run --rm jonrad/profilerate-sh:latest #Test sh (ash)
```
## Security
Profilerate is installed with permissions only for the current user to be able to read/write/execute. The same goes for the destination directory for the files that are profilerated. That is, if you ssh into a different machine as user `jon`, then you'll see the following:

```
/home/jon # echo $PROFILERATE_DIR
/home/jon/.config/profilerated/profilerate.nBHogk

/home/jon # ls -ld /home/jon/.config/profilerated/profilerate.nBHogk
     4 drwx------    3 jon     jon          4096 Feb 26 11:33 /home/jon/.config/profilerated/profilerate.nBHogk
```

This should be sufficient in most cases. HOWEVER, if you are sharing an account with multiple others, they will be able to see inside your profilerated files. If this is a concern, I highly recommend not putting anything sensitive inside your profilerate directory (such as API keys). In addition, if you don't trust the other people sharing that account, they could potentially modify your profilerate files to cause you to run commands you don't want to. However, that's the case regardless of whether you use profilerate or not since they may modify any profile file and rename commands/variables.

**tldr:** Don't share an account. And if you must, hopefully you trust those people. But keep yourself safe. Don't put sensitive information in profilerate

## Developing Profilerate
These directions are for people who want to add functionality to profilerate itself and share them with the world (Thank you!). This is **not** for your own personalization

* First, clone this repo:
```bash
git clone git@github.com:jonrad/profilerate.git
```

* In a shell, change the environment variable `PROFILERATE_DIR` to the repo path:
```bash
cd ./profilerate
export PROFILERATE_DIR=$PWD
```

* Now make the changes, after which point you can source `profilerate.sh` in the same shell as above and validate
```bash
source profilerate.sh
# Do your validation
```

* Once everything works, make sure all the tests still work (See Testing below)
```bash
./run-tests.sh
```

## Automated Tests
These directions are for people who want to add functionality to profilerate itself and share them with the world (Thank you!). This is **not** for your own personalization

Background: Tests use [bats-core](https://github.com/bats-core/bats-core) and must be run within a docker container (For reproducibility and to help with some networking goodness). All tests and docker images required for the tests can be found in the `./testing` directory.

The simplest way to run automated tests:
```bash
# Run all tests in a docker container and clean up
./run-tests.sh

# Run tests that match the word docker
./run-tests.sh --filter docker
```

You may notice that the kubernetes tests take the longest to run. That's because we spin up a kind cluster, which takes 30-60 seconds, then run the tests, then shut down the cluster. If you're iterating on kubernetes features, this is a pain. But fear not! You can run your tests in interactive mode which won't delete the cluster until you leave interactive mode:

```bash
# Run tests in interactive mode. This will put you inside a docker container with your tests
./run-tests-interactive.sh

# Run kubernetes tests. The first time will take a while as we create our kubernetes cluster
root@d059b59463e2:/code# bats testing/tests --filter kubectl

# Make some edits and then rerun your tests. This time the test should be much faster
root@d059b59463e2:/code# bats testing/tests --filter kubectl

# When you're done, exit will delete the kind cluster
root@d059b59463e2:/code# exit
Deleting cluster "profilerate-tests" ...
```

Docker images are not automatically built, so if you make changes to them, make sure to run the `build.sh` command in the specific directory.
However, you do not need to push the docker images to a remote repository when iterating on tests. However, before a PR is merged, the images need to be pushed so others can use them.

## TODO

* Move this TODO list to issues
* **Provide a file transfer method that doesn't connect multiple times (via encoded env variable?)**
* Handle readonly file systems by passing everything as a variable? Could this be used to be even more secure?
* add tar/manual tests for all
* Handle spaces in dirs/files
* Move files to logical directories
* Add settings file
* Make profilerate a single file

## Debugging
The following should help with debugging:

```bash
export _PROFILERATE_STDERR=/dev/stderr # Print out errors from calls made by profilerate
set -x # https://linuxhint.com/set-x-command-bash/
```

## Thank yous, prior art, and cool stuff:
* [zshi](https://github.com/romkatv/zshi) - Script to add init command to zsh
* [bats-core](https://github.com/bats-core/bats-core) - bats-core, used for testing
* [kyrat](https://github.com/fsquillace/kyrat) - SSH wrapper script that brings your dotfiles always with you on Linux and OSX
* [sshrc](https://github.com/cdown/sshrc) - Bring your .bashrc, .vimrc, etc. with you when you ssh
