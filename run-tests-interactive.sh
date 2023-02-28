#!/usr/bin/env sh
CONTAINER_ID=$(docker run --detach --privileged --rm \
  --init \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/code/" \
  --entrypoint sh \
  --name "profilerate-test-runner" \
  jonrad/profilerate-test-runner:latest \
  -c "sleep infinity")

if [ -z "$(command -v "profilerate_docker_exec")" ]
then
  echo "Couldn't find profilerate_docker_exec. If you're using profilerate, you can source this file and we'll profilerate into the test runner. eg:"
  echo "source $0"
  docker exec -it -e 'INTERACTIVE=1' $CONTAINER_ID bash
else
  profilerate_docker_exec -e 'INTERACTIVE=1' $CONTAINER_ID
fi

echo Cleaning Up
docker exec -it $CONTAINER_ID sh -c ". ./testing/tests/setup_suite.bash; teardown_suite"
docker stop $CONTAINER_ID >/dev/null
echo Bye and thanks for all the fish
