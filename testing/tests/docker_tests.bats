# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

docker_run () {
  if [ -z "$IMAGE" ]; then return 1; fi

  ADDITIONAL_ARGS=${ADDITIONAL_ARGS:-}
  echo "spawn sh -c 'cd $INSTALL_DIR;. $INSTALL_DIR/profilerate.sh; profilerate_docker_run --rm $ADDITIONAL_ARGS $IMAGE'"

  EXPECT=$(cat <<EOF
spawn sh -c "cd $INSTALL_DIR;. $INSTALL_DIR/profilerate.sh; profilerate_docker_run --rm $ADDITIONAL_ARGS $IMAGE"
expect "READY: "
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
$(printf "%s\r\n" "${ADDITIONAL_COMMANDS[@]}")
send "exit\r"
expect eof
EOF
  )

  echo "Expect is:"
  echo "$EXPECT"
  run expect -c "$EXPECT"
  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
}

@test "profilerate_docker_run bash" {
  export IMAGE="jonrad/profilerate-bash:v1"
  export ADDITIONAL_COMMANDS=( \
    "send \"echo ETC_PROFILE IS \\\$ETC_PROFILE\r\"" \
    "send \"echo HOME_BASH_PROFILE IS \\\$HOME_BASH_PROFILE\r\"" \
  )

  docker_run 

  assert_output --partial "ETC_PROFILE IS 1"
  assert_output --partial "HOME_BASH_PROFILE IS 1"
}

@test "profilerate_docker_run sh" {
  export IMAGE="jonrad/profilerate-sh:latest"
  export ADDITIONAL_COMMANDS=( \
    "send \"echo ETC_PROFILE IS \\\$ETC_PROFILE\r\"" \
    "send \"echo HOME_PROFILE IS \\\$HOME_PROFILE\r\"" \
  )

  docker_run 

  assert_output --partial "ETC_PROFILE IS 1"
  assert_output --partial "HOME_PROFILE IS 1"
}

@test "profilerate_docker_run zsh" {
  #TODO did I forget to check that other files are processed?
  export IMAGE="jonrad/profilerate-zsh:latest"
  docker_run
}

@test "profilerate_docker_run with spaces" {
  export IMAGE="jonrad/profilerate-bash:v1"
  export ADDITIONAL_ARGS="-e 'FOO=BAR SPACES'"
  export ADDITIONAL_COMMANDS=( \
    "send \"echo FOO IS \\\$FOO\r\"" \
  )

  docker_run

  assert_output --partial "FOO IS BAR SPACES"
}

# TODO add HOME dir has spaces
