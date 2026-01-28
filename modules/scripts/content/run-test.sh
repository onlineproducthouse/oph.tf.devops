#!/bin/bash

set -euo pipefail

#region required variables
# WORKING_DIR e.g. "./"
# RUN_TEST_COMMAND e.g. "npm run test"

if [[ "$WORKING_DIR" == "" ]]; then
  echo "[run-unit-test]: unit tests working directory not set, using default: $(pwd)"
  WORKING_DIR=$(pwd)
fi

if [[ "$RUN_TEST_COMMAND" == "" ]]; then
  echo "[run-unit-test]: unit tests command not set, please set RUN_TEST_COMMAND"
  exit 1
fi
#endregion

echo '[run-unit-test]: starting'

cd $WORKING_DIR

$RUN_TEST_COMMAND

echo '[run-unit-test]: done.'
exit 0
