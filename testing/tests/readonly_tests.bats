# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

run_test () {
  PROMPT=${PROMPT:-"READY:"}
  PREP=${PREP:-"echo"}
  CONTAINER=$(docker run --rm --detach $IMAGE sh -c "$PREP; sleep infinity")

  run expect <<EOF
spawn sh -c "cd $INSTALL_DIR;. $INSTALL_DIR/profilerate.sh; profilerate_docker_exec -u readonly $CONTAINER"
expect "$PROMPT"
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "exit\r"
expect eof
EOF

  docker stop $CONTAINER
}

@test "no home dir" {
  export IMAGE="jonrad/profilerate-sh:latest" 
  export PREP="adduser -D -H readonly"
  run_test 

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
}

@test "tmp dir readonly" {
  export IMAGE="jonrad/profilerate-bash-readonly:v1"
  export PROMPT="DEFAULTPROMPT:"
  run_test 

  assert_output --partial "Failed to profilerate"
  assert_output --partial "DEFAULTPROMPT:"
}
