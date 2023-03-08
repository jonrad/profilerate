# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

ssh_run () {
  local PROMPT=${PROMPT:-"READY: "}

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

  EXPECT=$(cat <<EOF
spawn sh -c "export PS1='GO: '; ${SHELL_COMMAND:-bash --noprofile --norc}"
expect "GO: "
send "PROFILERATE_DIR=$INSTALL_DIR; source $INSTALL_DIR/profilerate.sh 2>/dev/null || true; export PS1='GO: '; \r"
send "$SSH_COMMAND\r"
expect "$PROMPT"
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "echo PROFILERATE_DIR: \\\${PROFILERATE_DIR:-'NONE'}\r"
send "exit\r"
expect "GO: "
send "exit\r"
expect eof
EOF
)
  echo "Expect is:"
  echo "$EXPECT"
  run expect -c "$EXPECT"

  docker stop $CONTAINER_ID
}

@test "profilerate_ssh bash" {
  IMAGE="jonrad/profilerate-bash:v1" ssh_run 

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /root"
}

@test "profilerate_ssh bash no tar" {
  IMAGE="jonrad/profilerate-bash:v1" \
    CONTAINER_PREPARE='rm -rf $(which tar)' \
    ssh_run 

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /root"
}

@test "profilerate_ssh bash no home dir" {
  IMAGE="jonrad/profilerate-bash:v1" \
    CONTAINER_PREPARE="adduser -D -H readonly; passwd -d readonly" \
    SSH_ARGS="-l readonly" \
    ssh_run 

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /tmp"
}

@test "profilerate_ssh bash readonly" {
  IMAGE="jonrad/profilerate-bash:v1" \
    CONTAINER_PREPARE="adduser -D -H readonly; passwd -d readonly; chmod 700 /tmp" \
    SSH_ARGS="-l readonly" \
    PROMPT="bash-" \
    ssh_run 

  assert_output --partial "PROFILERATE_DIR: NONE"
}

# TODO: test the command line args, like -i and -p/-P (ugh)
# Testing the other shells would be redundant. Check the docker tests

