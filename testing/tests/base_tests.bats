setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

run_profilerate_from_dir () {
  local DIR=$1
  install $DIR
  export PROFILERATE_DIR=$DIR
  source "$DIR/profilerate.sh"
}

@test "does not leave unnecessary env variables" {
  local PRE_ENV=$(env)
  source profilerate.sh
  unset PROFILERATE_DIR
  local POST_ENV=$(env)

  assert_equal "$POST_ENV" "$PRE_ENV"
}
