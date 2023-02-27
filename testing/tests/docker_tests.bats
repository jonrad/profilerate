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
  shift
  install /tmp/.my_profile

  run expect <<EOF
spawn sh -c "cd /tmp/.my_profile/;. /tmp/.my_profile/profilerate.sh; profilerate_docker_run --rm $IMAGE"
expect "READY: "
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
$(printf "%s\r\n" "$@")
send "exit\r"
expect eof
EOF

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
}

@test "profilerate_docker_run bash" {
  docker_run "jonrad/profilerate-bash:v1" \
    "send \"echo ETC_PROFILE IS \\\$ETC_PROFILE\r\"" \
    "send \"echo HOME_BASH_PROFILE IS \\\$HOME_BASH_PROFILE\r\""

  assert_output --partial "ETC_PROFILE IS 1"
  assert_output --partial "HOME_BASH_PROFILE IS 1"
}

@test "profilerate_docker_run sh" {
  docker_run "jonrad/profilerate-sh:latest" \
    "send \"echo ETC_PROFILE IS \\\$ETC_PROFILE\r\"" \
    "send \"echo HOME_PROFILE IS \\\$HOME_PROFILE\r\""

  assert_output --partial "ETC_PROFILE IS 1"
  assert_output --partial "HOME_PROFILE IS 1"
}

@test "profilerate_docker_run zsh" {
  docker_run "jonrad/profilerate-zsh:latest"
}
