#!/bin/bash

set -euo pipefail

#region required variables
# RUN_TEST_COMMAND e.g. "npm run test"
# WORKING_DIR e.g. "./"

if [[ "$RUN_TEST_COMMAND" == "" ]]; then
  echo "[run-nodejs-test]: tests command not set, please set RUN_TEST_COMMAND"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  echo "[run-nodejs-test]: tests working directory not set, using default: $(pwd)"
  WORKING_DIR=$(pwd)
fi
#endregion

echo "[run-nodejs-test]: changing directory to - $WORKING_DIR"
cd $WORKING_DIR

echo "[run-nodejs-test]: installing nodejs version 25.2.1"
n 25.2.1

run_test() {
  echo '[run-nodejs-test]: starting test execution'

  for command in $1; do
    echo "[run-nodejs-test]: executing command - $command"
    $command
  done

  echo '[run-nodejs-test]: finish test execution'
}

run_test $RUN_TEST_COMMAND

echo '[run-nodejs-test]: done.'
exit 0
