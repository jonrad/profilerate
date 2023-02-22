#!/usr/bin/env sh
docker run -it -e --privileged --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/code/" \
  --entrypoint sh \
  --name "profilerate-test-runner" \
  jonrad/profilerate-test-runner.latest \
  -c "export INTERACTIVE=1; bash; unset INTERACTIVE; . ./testing/tests/setup_suite.bash; teardown_suite"

# TODO get this to work
#profilerate_docker_run -e PROFILERATE_DEBUG=1 --privileged --rm \
#  -v /var/run/docker.sock:/var/run/docker.sock \
#  -v "$PWD:/code/" \
#  jonrad/profilerate-test-runner.latest
