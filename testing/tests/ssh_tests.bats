# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

ssh_run () {
  local IMAGE=$1
  local CONTAINER_PREPARE=$2
  local SSH_ARGS=$3
  local PROMPT=${4:-"READY: "}
  shift
  install /tmp/.my_profile

  local CONTAINER_ID=$(docker run --init --detach --rm $IMAGE)
  local IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $CONTAINER_ID)
  if [ -n "$CONTAINER_PREPARE" ]
  then
    docker exec -it $CONTAINER_ID sh -c "$CONTAINER_PREPARE"
  fi

  # this is a bit silly, but it gets the job done
  for i in {1..5}
  do
    local RESULT=$(ssh $IP 'echo OK' 2>&1)
    if [[ "$RESULT" == *"OK"* ]]; then
      break
    fi
    sleep 1
  done

  if [ -n "$SSH_ARGS" ]
  then
    SSH_COMMAND="profilerate_ssh $SSH_ARGS $IP"
  else
    SSH_COMMAND="profilerate_ssh $IP"
  fi

  run expect <<EOF
spawn sh -c "cd /tmp/.my_profile/; . /tmp/.my_profile/profilerate.sh; $SSH_COMMAND"
expect "$PROMPT"
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "echo PROFILERATE_DIR: \\\${PROFILERATE_DIR:-'NONE'}\r"
send "exit\r"
expect eof
EOF

  docker stop $CONTAINER_ID
}

@test "profilerate_ssh bash" {
  ssh_run "jonrad/profilerate-bash:v1"

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /root"
}

@test "profilerate_ssh no home dir" {
  ssh_run "jonrad/profilerate-bash:v1" "adduser -D -H readonly; passwd -d readonly" "-l readonly"

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /tmp"
}

@test "profilerate_ssh readonly" {
  ssh_run "jonrad/profilerate-bash:v1" "adduser -D -H readonly; passwd -d readonly; chmod 700 /tmp" "-l readonly" "bash-"

  assert_output --partial "PROFILERATE_DIR: NONE"
}

# TODO: test the command line args, like -i and -p/-P (ugh)
# Testing the other shells would be redundant. Check the docker tests

