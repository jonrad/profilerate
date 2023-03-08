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

kubectl_test () {
  PROMPT=${PROMPT:-"READY: "}
  kind load docker-image --name profilerate-tests "$IMAGE_NAME"
  kubectl apply -f "/code/testing/tests/assets/$YAML_FILE"

  # this is a bit silly, but it gets the job done
  # checkoing for running isn't enough here since we don't have a readiness probe
  for i in {1..5}
  do
    local RESULT=$(kubectl exec -it $POD_NAME -- echo OK 2>&1)
    if [[ "$RESULT" == *"OK"* ]]; then
      break
    fi
    sleep 1
  done

  run expect <<EOF
spawn sh -c "cd $INSTALL_DIR; . $INSTALL_DIR/profilerate.sh; profilerate_kubectl_exec $POD_NAME"
expect "$PROMPT"
send "alias TEST_ALIAS\r"
send "echo \\\$TEST_ENV\r"
send "TEST_FUNCTION\r"
send "echo PROFILERATE_DIR: \\\$PROFILERATE_DIR\r"
send "exit\r"
expect eof
EOF

  kubectl delete po $POD_NAME
}

@test "profilerate_kubectl_exec bash" {
  export POD_NAME="bash-root"
  export YAML_FILE="pod-bash-root.yaml"
  export IMAGE_NAME="jonrad/profilerate-bash:v1"

  kubectl_test

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /root"
}

@test "profilerate_kubectl_exec bash no home dir" {
  export POD_NAME="bash-no-home"
  export YAML_FILE="pod-bash-no-home.yaml"
  export IMAGE_NAME="jonrad/profilerate-bash-no-home:v1"

  kubectl_test

  assert_output --partial "env-good"
  assert_output --partial "alias-good"
  assert_output --partial "function-good"
  assert_output --partial "PROFILERATE_DIR: /tmp"
}

@test "profilerate_kubectl_exec bash readonly" {
  export POD_NAME="bash-readonly"
  export YAML_FILE="pod-bash-readonly.yaml"
  export IMAGE_NAME="jonrad/profilerate-bash-readonly:v1"
  export PROMPT="DEFAULTPROMPT:"

  kubectl_test

  assert_output --partial "DEFAULTPROMPT:"
  assert_output --partial "TEST_FUNCTION: command not found"
}

# Testing the other shells would be redundant. Check the docker tests

