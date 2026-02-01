#!/bin/bash

set -euo pipefail

#region required variables

# AWS_REGION e.g. 'eu-west-1'
# LOAD_ENV_VARS_SCRIPT_S3_URL: s3://[bucket-name]/path/to/script.sh
# ENV_VARS_S3_URL: s3://[bucket-name]/path/to/.env
# AWS_SSM_PARAMETER_PATHS e.g. "path1;path2;..."
# WORKING_DIR
# RUN_TEST_COMMAND e.g. "npm run test"

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

if [[ "$WORKING_DIR" == "" ]]; then
  WORKING_DIR=$(pwd)
else
  WORKING_DIR="$(pwd)/$WORKING_DIR"
fi

echo "[build-web]: working directory set to: $WORKING_DIR"

#endregion

load_env_vars() {
  if [[ "$AWS_SSM_PARAMETER_PATHS" != "" ]];then
    LOAD_ENV_VARS_SCRIPT_PATH=./ci/load-env-vars.sh
    aws s3 cp $LOAD_ENV_VARS_SCRIPT_S3_URL $LOAD_ENV_VARS_SCRIPT_PATH
    source $LOAD_ENV_VARS_SCRIPT_PATH $AWS_REGION $AWS_SSM_PARAMETER_PATHS $ENV_VARS_S3_URL $WORKING_DIR
  fi
}

n 25.2.1

echo "[build-web]: changing directory to - $WORKING_DIR"
cd $WORKING_DIR

npm i

load_env_vars && npm run build

echo "[build-web]: done."
