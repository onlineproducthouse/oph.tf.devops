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

echo "[run-test]: installing nodejs version 25.2.1"
n 25.2.1

echo "[run-test]: changing directory to - $WORKING_DIR"
cd $WORKING_DIR

echo "[run-test]: executing test command - $RUN_TEST_COMMAND"
$RUN_TEST_COMMAND

echo '[run-test]: done.'
exit 0
