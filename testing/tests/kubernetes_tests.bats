# called for each test
setup () {
  load 'common.bash'
  common_setup

  local CURRENT_CONTAINER_ID=$(docker ps -qf "name=profilerate-test-run")
  local CLUSTER_NAME="profilerate-tests"
  # Setup kind here, but only if it doesn't exist
  # also add ourselves to the kind network
  # and update the kubeconfig accordingly
  # Note this will only work if run once, so don't go deleting the kind cluster until this specific container gets deleted
  # I don't see any need to harden this 
  kind get clusters 2>&1 | grep $CLUSTER_NAME || \
    (kind create cluster --name $CLUSTER_NAME && \
    (docker network connect kind $CURRENT_CONTAINER_ID || echo 'already networked') && \
    kind get kubeconfig --name profilerate-tests --internal > ~/.kube/config)

  # Wait until the service account is up
  for i in {1..10}
  do
    kubectl get sa default && break
    sleep 1
  done
}

teardown () {
  common_teardown
}

@test "profilerate_kubectl bash" {
  install /tmp/.my_profile

  kind load docker-image --name profilerate-tests jonrad/profilerate-bash.v1
  # It feels so wrong to start pods from the command line...
  # this is a bit silly, but it gets the job done
  # checkoing for running isn't enough here since we don't have a readiness probe
  kubectl run --image-pull-policy IfNotPresent --image=jonrad/profilerate-bash.v1 bash
  echo there

  # this is a bit silly, but it gets the job done
  # checkoing for running isn't enough here since we don't have a readiness probe
  for i in {1..5}
  do
    local RESULT=$(kubectl exec -it bash -- echo OK 2>&1)
    if [[ "$RESULT" == *"OK"* ]]; then
      break
    fi
    sleep 1
  done

  run expect <<EOF
spawn sh -c "cd /tmp/.my_profile/; . /tmp/.my_profile/profilerate.sh; profilerate_kubectl bash"
expect "READY: "
send "alias TEST_ALIAS\r"
send "echo PROFILERATE_DIR: \\\$PROFILERATE_DIR\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "exit\r"
expect eof
EOF

  kubectl delete po bash

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /tmp/.my_profile"
}

# TODO: test the command line args, like -i and -p/-P (ugh)
# Testing the other shells would be redundant. Check the docker tests

