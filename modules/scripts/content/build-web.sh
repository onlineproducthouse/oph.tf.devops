#!/bin/bash

set -euo pipefail

#region required variables

# AWS_REGION e.g. 'eu-west-1'
# LOAD_ENV_VARS_SCRIPT_S3_URL: s3://[bucket-name]/path/to/script.sh
# ENV_VARS_S3_URL: s3://[bucket-name]/path/to/.env
# AWS_SSM_PARAMETER_PATHS e.g. "path1;path2;..."
# WORKING_DIR

#endregion

#region validations

if [[ "$LOAD_ENV_VARS_SCRIPT_S3_URL" == "" ]];then
  echo "[build-web]: load-env-vars script AWS S3 URL not set. please set load-env-vars script AWS S3 URL"
  exit 1
fi

if [[ "$AWS_REGION" == "" ]];then
  echo "[build-web]: AWS Region not set. please set AWS Region"
  exit 1
fi

if [[ "$AWS_SSM_PARAMETER_PATHS" == "" ]];then
  echo "[build-web]: AWS SSM Parameter Store path(s) not set. please set AWS SSM Parameter Store path(s)"
  exit 1
fi

if [[ "$ENV_VARS_S3_URL" == "" ]];then
  echo "[build-web]: .env file AWS S3 URL not set. please set .env file AWS S3 URL"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  echo "[build-web]: terraform child directory is not set, using default: $(pwd)"
  WORKING_DIR=$(pwd)
fi

#endregion

LOAD_ENV_VARS_SCRIPT_PATH=./ci/load-env-vars.sh

aws s3 cp $LOAD_ENV_VARS_SCRIPT_S3_URL $LOAD_ENV_VARS_SCRIPT_PATH

source $LOAD_ENV_VARS_SCRIPT_PATH $AWS_REGION $AWS_SSM_PARAMETER_PATHS $ENV_VARS_S3_URL $WORKING_DIR \
  && npm run build

echo "[build-web]: done."
