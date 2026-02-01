#!/bin/bash

set -euo pipefail

#region required variables
# TARGET_RUNTIME e.g. go, node
# RUN_TEST_COMMAND e.g. "npm run test"
# WORKING_DIR e.g. "module/project"
# AWS_REGION e.g. 'eu-west-1'
# LOAD_ENV_VARS_SCRIPT_S3_URL: s3://[bucket-name]/path/to/script.sh
# ENV_VARS_S3_URL: s3://[bucket-name]/path/to/.env
# AWS_SSM_PARAMETER_PATHS e.g. "path1;path2;..."

if [[ "$LOAD_ENV_VARS_SCRIPT_S3_URL" == "" ]];then
  echo "[build-web]: load-env-vars script AWS S3 URL not set. please set load-env-vars script AWS S3 URL"
  exit 1
fi

if [[ "$AWS_REGION" == "" ]];then
  echo "[build-web]: AWS Region not set. please set AWS Region"
  exit 1
fi

if [[ "$ENV_VARS_S3_URL" == "" ]];then
  echo "[build-web]: .env file AWS S3 URL not set. please set .env file AWS S3 URL"
  exit 1
fi

if [[ "$TARGET_RUNTIME" == "" ]]; then
  echo "[run-test]: target runtime not set, please set TARGET_RUNTIME"
  exit 1
fi

if [[ "$RUN_TEST_COMMAND" == "" ]]; then
  echo "[run-test]: tests command not set, please set RUN_TEST_COMMAND"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  WORKING_DIR=$(pwd)
else
  WORKING_DIR="$(pwd)/$WORKING_DIR"
fi

echo "[run-test]: working directory set to: $WORKING_DIR"
#endregion

load_env_vars() {
  if [[ "$AWS_SSM_PARAMETER_PATHS" != "" ]];then
    LOAD_ENV_VARS_SCRIPT_PATH=./ci/load-env-vars.sh
    aws s3 cp $LOAD_ENV_VARS_SCRIPT_S3_URL $LOAD_ENV_VARS_SCRIPT_PATH
    source $LOAD_ENV_VARS_SCRIPT_PATH $AWS_REGION $AWS_SSM_PARAMETER_PATHS $ENV_VARS_S3_URL $WORKING_DIR
  fi
}

setup_runtime() {
  echo "[run-test]: setting up runtime"

  if [[ "$TARGET_RUNTIME" == "node" ]]; then
    echo "[run-test]: installing nodejs version 25.2.1"

    n 25.2.1
    node -v
  fi

  if [[ "$TARGET_RUNTIME" == "go" ]]; then
    echo "[run-test]: installing go version 1.25.5"

    cd $HOME/.goenv && git pull --ff-only && cd -
    goenv install 1.25.5
    goenv local 1.25.5
    go version
  fi
}

setup_runtime

echo "[run-test]: changing directory to - $WORKING_DIR"
cd $WORKING_DIR

echo "[run-test]: executing test command - $RUN_TEST_COMMAND"
load_env_vars && $RUN_TEST_COMMAND

echo '[run-test]: done.'
exit 0
