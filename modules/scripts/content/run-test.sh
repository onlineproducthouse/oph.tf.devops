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

echo '[run-test]: changing to working directory - $WORKING_DIR'
cd $WORKING_DIR

run_test() {
  IFS=';'

  echo '[run-test]: starting test execution'

  for command in $1; do
    echo "[run-test]: executing command - $command"
    $command
  done

  echo '[run-test]: finish test execution'
}

run_test $RUN_TEST_COMMAND

echo '[run-test]: done.'
exit 0
