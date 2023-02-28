# 🐰 profilerate 🐰

Take your dotfiles with you when you log in to remote systems using ssh/kubectl/docker, without impacting other people on the system.

This is done by create special commands that automatically copy the `profilerate` directory, including all your personalizations, to the systems you log into.

Pronunciation: Like proliferate, but with the `l` and the `r` exchanged.

# Table of Contents

- [Features](#features)
- [Installation/Upgrades](#installationupgrades)
- [Commands](#commands)
- [Personalizing](#personalizing)
  - [personal.sh](#personalsh)
  - [vimrc](#vimrc)
  - [inputrc](#inputrc)
  - [Testing your personal.sh](#testing-your-personalsh)
- [Security](#security)
- [Developing Profilerate](#developing-profilerate)
- [Automated Tests](#automated-tests)
- [TODO](#todo)
- [Caveats](#caveats)
- [Standing on the Shoulders of Giants](#standing-on-the-shoulders-of-giants)


## Features

* Copy your startup scripts (dotfiles) with you when you log into remote systems
* Does not impact any of the remote rc files (does not impact other people on the system, even if they share the same user)
* Supports `ssh`, `kubectl exec`, `docker run` and `docker exec`
* Uses fastest file transfer, with fallbacks: `rsync`, followed by `tar`, and finally falling back to manual single file transfer (no requirements for anything to be installed on remote system)
* Uses most modern shell with fallbacks: `zsh`, then `bash`, then `sh`
* Transfers files to `HOME` directory first and falls back to `tmp` directory if `HOME` doesn't exist or is readonly
* Supports both neovim and vim (with limited support for vi. See Section on vim, below)
* Supports inputrc
* Is not limited to text files - Can transfer binary files if you feel they will be compatible with the remote system
* When all else fails, will fall back to using standard commands without profilerate (eg. when the remote file system is completely readonly)

## Installation/Upgrades

```bash
bash <(curl https://raw.githubusercontent.com/jonrad/profilerate/main/install.sh)
```

Profilerate is installed in `~/.config/profilerate`

## Commands

| Command | Description | Example | Notes |
| - | - | - | - |
| profilerate_ssh | SSH into remote box and copy your dotfiles with you | `profilerate_ssh [OTHER SSH ARGS] DESTINATION` | `DESTINATION` must be the last arg (does not take a command) |
| profilerate_kubectl | Exec into kubernetes pod | `profilerate_kubectl [OTHER KUBECTL ARGS] POD ` | POD must be the last arg. |
| profilerate_docker_exec | Exec into docker container | `profilerate_docker_exec [DOCKER EXEC ARGS] CONTAINER_ID` | You must start the docker container first |
| profilerate_docker_run | Start a docker container and exec into it | `profilerate_docker_run [DOCKER RUN ARGS] IMAGE` | Shuts down the container when you exit. If you don't want the container to shut down, start it yourself and exec in using `profilerate_docker_exec` |

## Personalizing

Profilerate is pretty useless by itself. What we need to do is make it our own.

### personal.sh

Modify this file with all your shell scripting goodness. For example:

```bash
# Make a consistent PS1 that helps us identify who and where we are
PS1='${USER=$(id -un)}@$HOSTNAME:$PWD\$ '

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
alias ke="profilerate_kubectl"
alias s="profilerate_ssh"
```

### vimrc
Create a `vimrc` (no dot) file in the main profilerate directory. It will automatically be loaded using the VIMINIT environment variable, which is supported by both neovim and vim. Note that vi isn't handled due to lack of standardization. For example, busybox vi doesn't have the `source` command, while installing `nvi` on ubuntu does. If you are frequently using busybox/alpine vi, I recommend setting the `EXINIT` environment variable in your `personal.sh`

### inputrc
Create a `inputrc` (no dot) file in the main profilerate directory. It will be loaded by setting the INPUTRC environment variable.

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
* Handle readonly file systems by passing everything as a variable? Could this be used to be even more secure?
* Handle fallback when all else fails
* Refactor and speed up tests
* Follow symlinks (especially for things like vimrc)

## Caveats
* Doesn't work with readonly file systems (yet)

## Standing on the Shoulders of Giants
* [zshi](https://github.com/romkatv/zshi) - Script to add init command to zsh
* [bats-core](https://github.com/bats-core/bats-core) - bats-core, used for testing
* [kyrat](https://github.com/fsquillace/kyrat) - A simple ssh wrapper script that brings your dotfiles always with you on Linux and OSX
