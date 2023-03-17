# called for each test
setup () {
  load 'common.bash'
  common_setup
}

teardown () {
  common_teardown
}

run_test () {
  ADDITIONAL_ARGS=${ADDITIONAL_ARGS:-}
  COMMAND=${COMMAND:-"profilerate_docker_run --rm -e 'FOO=BAR SPACES' $IMAGE"}

  EXPECT=$(cat <<EOF
spawn sh -c "export PS1='GO: '; ${SHELL_COMMAND:-bash --noprofile --norc}"
expect "${FIRST_PROMPT:-GO: }"
send "PROFILERATE_DIR=$INSTALL_DIR; source $INSTALL_DIR/profilerate.sh 2>/dev/null || true; export PS1='GO: '; \r"
send "$COMMAND\r"
expect "READY: "
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "echo FOO IS \\\$FOO\r"
$(printf "%s\r\n" "${ADDITIONAL_COMMANDS[@]}")
send "exit\r"
expect "GO: "
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
  assert_output --partial "FOO IS BAR SPACES"
}

@test "profilerate_docker_run connect to bash" {
  ADDITIONAL_COMMANDS=( \
    "send \"echo ETC_PROFILE IS \\\$ETC_PROFILE\r\"" \
    "send \"echo HOME_BASH_PROFILE IS \\\$HOME_BASH_PROFILE\r\"" \
  )

  IMAGE="jonrad/profilerate-bash:v1" run_test

  assert_output --partial "ETC_PROFILE IS 1"
  assert_output --partial "HOME_BASH_PROFILE IS 1"
}

@test "profilerate_docker_run connect to sh" {
  export ADDITIONAL_COMMANDS=( \
    "send \"echo ETC_PROFILE IS \\\$ETC_PROFILE\r\"" \
    "send \"echo HOME_PROFILE IS \\\$HOME_PROFILE\r\"" \
  )

  IMAGE="jonrad/profilerate-sh:latest" run_test 

  assert_output --partial "ETC_PROFILE IS 1"
  assert_output --partial "HOME_PROFILE IS 1"
}

@test "profilerate_docker_run connect to zsh" {
  #TODO did I forget to check that other files are processed?
  IMAGE="jonrad/profilerate-zsh:latest" run_test
}

@test "profilerate_docker_exec all" {
  SHELLS=( "zsh" "bash" "dash" )
  COPY_METHODS=( "tar" "manual" "hashed" )
  for SHELL in "${SHELLS[@]}"
  do
    SHELL_COMMAND=$SHELL
    if [ "$SHELL" = "bash" ]
    then
      SHELL_COMMAND="bash --noprofile --norc"
    elif [ "$SHELL" = "dash" ]
    then
      SHELL_COMMAND="ENV=/tmp/.my_profile/profilerate.sh dash"
    fi

    if [ "$SHELL" = "dash" ]
    then
      FIRST_PROMPT="READY: "
    else
      FIRST_PROMPT="GO: "
    fi

    CONTAINER=$(docker_run -it --detach --init --entrypoint sh jonrad/profilerate-bash:v1 -c 'while true; do sleep 600; done')

    for COPY_METHOD in "${COPY_METHODS[@]}"
    do
      echo "${COPY_METHOD}: Running for $SHELL" >&3
      export _PROFILERATE_TRANSFER_METHODS=$COPY_METHOD
      SHELL_COMMAND="$SHELL_COMMAND" \
        FIRST_PROMPT="$FIRST_PROMPT" \
        COMMAND="profilerate_docker_exec -e 'FOO=BAR SPACES' $CONTAINER" \
        run_test
    done

    docker stop $CONTAINER || true
  done
}

# TODO add HOME dir has spaces
