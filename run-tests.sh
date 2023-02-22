#!/usr/bin/env sh
docker run -it -e --privileged --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/code/" \
  --name "profilerate-test-runner" \
  jonrad/profilerate-test-runner.latest \
  $@
