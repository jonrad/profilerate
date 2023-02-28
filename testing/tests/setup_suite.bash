export INSTALL_DIR="/tmp/.my_profile"

setup_suite() {
  install
}

teardown_suite() {
  # Don't delete cluster in interactive mode, since we may run tests multiple times
  # of course, this means we have to handle tearing it down somewhere else... 
  if [ -z "$INTERACTIVE" ]
  then
    CLUSTER_NAME="profilerate-tests"
    kind get clusters 2>&1 | grep $CLUSTER_NAME && kind delete cluster --name $CLUSTER_NAME || echo 'No cluster found'
  fi

  rm -rf "$INSTALL_DIR"
}

install () {
  if [ -d "$INSTALL_DIR" ]
  then
    return
  fi

  mkdir -p "$INSTALL_DIR"
  sh ./build.sh >/dev/null
  tar -xz -C "$INSTALL_DIR" -f profilerate.latest.tar.gz
  echo export PS1=\"READY: \" > $INSTALL_DIR/personal.sh
  echo export TEST_ENV=env-good >> $INSTALL_DIR/personal.sh
  echo alias TEST_ALIAS=\"alias-good\" >> $INSTALL_DIR/personal.sh
  echo "TEST_FUNCTION() { echo function-good; }" >> $INSTALL_DIR/personal.sh
}

