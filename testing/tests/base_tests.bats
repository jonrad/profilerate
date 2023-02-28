setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

@test "does not leave unnecessary env variables" {
  local PRE_ENV=$(env)
  source profilerate.sh
  unset PROFILERATE_DIR
  local POST_ENV=$(env)

  assert_equal "$POST_ENV" "$PRE_ENV"
}
