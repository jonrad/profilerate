# profilerate

Take your dotfiles with you when you log in to remote systems using ssh/kubectl exec/docker exec, without impacting other people on the system

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
| profilerate_ssh | SSH into remote box and copy your dotfiles with you | `profilerate_ssh user@host <OTHER SSH ARGS>` | `user@host` must be the first arg |
| profilerate_kubernetes | Exec into kubernetes pod | `profilerate_kubernetes POD <OTHER KUBECTL ARGS>` | Host must be the first arg. Make sure things like -n come after. Also works with `profilerate_kns` and `profilerate_kctx` |
| profilerate_docker | Exec into docker container | `profilerate_docker CONTAINER_ID` | You must start the docker container first |
| profilerate_su | Get root access and still use your dotfiles | `profilerate_su` | Don't you hate losing your `PS1`? |
| profilerate_kubectl | An alias to kubectl that passes in `$PROFILERATE_KNS` as the namespace and `$PROFILERATE_KCTX` as the context | `profilerate_kubectl get po` | see the two helper functions below to take advantage of this |
| profilerate_kns | Sets `$PROFILERATE_KNS` to the kubernetes namespace | `profilerate_kns kube_system` | To be used with `profilerate_kubectl` |
| profilerate_kctx | Sets `$PROFILERATE_KCTX` to the kubernetes context | `profilerate_kctx remote_context` | To be used with `profilerate_kubectl` |

## Personalizing

profilerate is pretty useless by itself. What we need to do is make it our own. 

### personal.sh

Modify this file with all your shell scripting goodness. For example:

```
export PS1="PROFILERATE PROMPT \\$ "
alias db="profilerate_docker"
alias kb="profilerate_kubernetes"
alias s="profilerate_ssh"
alias iamroot="profilerate_su"

alias k="profilerate_kubectl"
alias kns="profilerate_kns"
alias kctx="profilerate_kctx"
```

With the above, whenever you ssh into a different machine, you'll have the same exact (useless) prompt. Additionally, some helpful aliases are generated so you don't have to type so much. 

### vimrc
Create a vimrc file in the main profilerate directory. 

## Kubernetes Example

Imagine I have two contexts `minikube` and `kind`

```
# First I set up my aliases to make things easier. You can add these to your personal.sh if you'd like
~ $ alias k="profilerate_kubectl"
~ $ alias kns="profilerate_kns"
~ $ alias kctx="profilerate_kctx"

# Say I want to work on minikube now, I'll switch to that context
~ $ kctx minikube

# Let's see what namespaces I have
~ $ k get ns
NAME              STATUS   AGE
default           Active   12d
kube-node-lease   Active   12d
kube-public       Active   12d
kube-system       Active   12d

# Let's poke around in kube-system
~ $ kns kube-system
~ $ k get po
NAME                                       READY   STATUS    RESTARTS   AGE
coredns-fb8b8dccf-gsppp                    1/1     Running   5          12d
coredns-fb8b8dccf-lzfv5                    1/1     Running   5          12d
kube-apiserver-minikube                    1/1     Running   3          12d
--SNIP--

# Let's poke around the kube-apiserver-minikube (Note that this server only has `sh` so it will not bring in our profile)
~ $ profilerate_kubernetes kube-apiserver-minikube
# hostname
minikube


```

## TODO

The following are my high level plans for future work on this:

* Clean up the kubernetes bits. Yikes
* Installation script
* Make argument ordering for ssh/kubectl/docker not matter as much
* Add ability to share plugins

