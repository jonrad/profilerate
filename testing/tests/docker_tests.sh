# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

install () {
  local DIR=$1
  mkdir -p $DIR
  cp -R profilerate.sh $DIR/
  cp -R shell.sh $DIR/
  cp -R zshi.sh $DIR/
  echo export TEST_ENV=env-good > $DIR/personal.sh
  echo alias TEST_ALIAS=\"alias-good\" >> $DIR/personal.sh
  echo "TEST_FUNCTION() { echo function-good; }" >> $DIR/personal.sh
}

run_profilerate_from_dir () {
  local DIR=$1
  install $DIR
  export PROFILERATE_DIR=$DIR
  source "$DIR/profilerate.sh"
}

@test "profilerate_docker_run " {
  install /tmp/.my_profile
  run expect <<EOF
spawn sh -c "cd /tmp/.my_profile/;. /tmp/.my_profile/profilerate.sh; profilerate_docker_run --rm bash"
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "exit\r"
expect eof
EOF
  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
}
