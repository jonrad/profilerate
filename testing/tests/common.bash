# called for each test
common_setup() {
  load '/test_helper/bats-support/load'
  load '/test_helper/bats-assert/load'
  export PROFILERATE_ID_PREVIOUS=$PROFILERATE_ID
  export PROFILERATE_DIR_PREVIOUS=$PROFILERATE_DIR
  unset PROFILERATE_ID
  unset PROFILERATE_DIR
}

common_teardown() {
  export PROFILERATE_ID=$PROFILERATE_ID_PREVIOUS
  export PROFILERATE_DIR=$PROFILERATE_DIR_PREVIOUS
  unset PROFILERATE_ID_PREVIOUS
  unset PROFILERATE_DIR_PREVIOUS
}

install () {
  local DIR=$1
  mkdir -p $DIR
  cp -R profilerate.sh $DIR/
  cp -R shell.sh $DIR/
  cp -R shells $DIR/
  echo export PS1=\"READY: \" > $DIR/personal.sh
  echo export TEST_ENV=env-good >> $DIR/personal.sh
  echo alias TEST_ALIAS=\"alias-good\" >> $DIR/personal.sh
  echo "TEST_FUNCTION() { echo function-good; }" >> $DIR/personal.sh
}
