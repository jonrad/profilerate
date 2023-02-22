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
  shift
  install /tmp/.my_profile

  local CONTAINER_ID=$(docker run --init --detach --rm $IMAGE)
  local IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $CONTAINER_ID)

  # this is a bit silly, but it gets the job done
  for i in {1..5}
  do
    local RESULT=$(ssh $IP 'echo OK' 2>&1)
    if [[ "$RESULT" == *"OK"* ]]; then
      break
    fi
    sleep 1
  done

  run expect <<EOF
spawn sh -c "cd /tmp/.my_profile/; . /tmp/.my_profile/profilerate.sh; profilerate_ssh $IP"
expect "READY: "
send "alias TEST_ALIAS\r"
send "echo PROFILERATE_DIR: \\\$PROFILERATE_DIR\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
$(printf "%s\r\n" "$@")
send "exit\r"
expect eof
EOF

  docker stop $CONTAINER_ID

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /tmp/.my_profile"
}

@test "profilerate_ssh bash" {
  ssh_run "jonrad/profilerate-bash.v1" \
    "send \"echo ETC_PROFILE IS \\\$ETC_PROFILE\r\"" \
    "send \"echo HOME_BASH_PROFILE IS \\\$HOME_BASH_PROFILE\r\""

  assert_output --partial "ETC_PROFILE IS 1"
  assert_output --partial "HOME_BASH_PROFILE IS 1"
}

# TODO: test the command line args, like -i and -p/-P (ugh)
# Testing the other shells would be redundant. Check the docker tests

