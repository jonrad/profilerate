#!/usr/bin/env sh
docker run -it -e --privileged --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/code/" \
  --entrypoint bash \
  jonrad/profilerate-test-runner.latest

# TODO get this to work
#profilerate_docker_run -e PROFILERATE_DEBUG=1 --privileged --rm \
#  -v /var/run/docker.sock:/var/run/docker.sock \
#  -v "$PWD:/code/" \
#  jonrad/profilerate-test-runner.latest
