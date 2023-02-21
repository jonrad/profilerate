# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

docker_run () {
  local CONTAINER=$1
  install /tmp/.my_profile
  run expect <<EOF
spawn sh -c "cd /tmp/.my_profile/;. /tmp/.my_profile/profilerate.sh; profilerate_docker_run --rm $CONTAINER"
send "alias TEST_ALIAS\r"
send "echo PROFILERATE_DIR: \\\$PROFILERATE_DIR\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "exit\r"
expect eof
EOF
  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /tmp/.my_profile"
}

@test "profilerate_docker_run bash" {
  docker_run "jonrad/profilerate-bash.latest"
}

@test "profilerate_docker_run sh" {
  docker_run "jonrad/profilerate-sh.latest"
}

@test "profilerate_docker_run zsh" {
  docker_run "jonrad/profilerate-zsh.latest"
}
