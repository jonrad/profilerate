# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

docker_run () {
  local IMAGE=$1
  local PREP=$2
  shift
  CONTAINER=$(docker run --rm --detach $IMAGE sh -c "$PREP; sleep infinity")

  run expect <<EOF
spawn sh -c "cd $INSTALL_DIR;. $INSTALL_DIR/profilerate.sh; profilerate_docker_exec -u readonly $CONTAINER"
expect "READY: "
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "exit\r"
expect eof
EOF

  docker stop $CONTAINER
}

@test "no home dir" {
  docker_run "jonrad/profilerate-sh:latest" "adduser -D -H readonly"

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
}

@test "tmp dir readonly" {
  docker_run "jonrad/profilerate-sh:latest" "adduser -D -H readonly; chmod 700 /tmp"

  assert_output --partial "Failed to profilerate"
  assert_output --partial "/ $"
}
