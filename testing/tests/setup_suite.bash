setup_suite() {
  :
}

teardown_suite() {
  # Don't delete cluster in interactive mode, since we may run tests multiple times
  # of course, this means we have to handle tearing it down somewhere else... 
  if [ -z "$INTERACTIVE" ]
  then
    CLUSTER_NAME="profilerate-tests"
    kind get clusters 2>&1 | grep $CLUSTER_NAME && kind delete cluster --name $CLUSTER_NAME
  fi
}
