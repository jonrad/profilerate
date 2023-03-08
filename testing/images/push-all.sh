docker image ls | grep profilerate | cut -w -f 1,2 | xargs -n 2 sh -c 'docker push "$0:$1"' 
