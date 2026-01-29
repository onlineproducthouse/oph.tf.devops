#!/bin/bash

set -euo pipefail

#region required variables
# RUN_TEST_COMMAND e.g. "npm run test"
# WORKING_DIR e.g. "./"

if [[ "$RUN_TEST_COMMAND" == "" ]]; then
  echo "[run-test]: tests command not set, please set RUN_TEST_COMMAND"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  echo "[run-test]: tests working directory not set, using default: $(pwd)"
  WORKING_DIR=$(pwd)
fi
#endregion

echo '[run-test]: starting'

cd $WORKING_DIR

run_test() {
  echo '[run-test]: executing command - $RUN_TEST_COMMAND'
  $RUN_TEST_COMMAND
}

run_test

echo '[run-test]: done.'
exit 0
