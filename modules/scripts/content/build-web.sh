#!/bin/bash

set -euo pipefail

#region required variables

# AWS_REGION e.g. 'eu-west-1'
# LOAD_ENV_VARS_SCRIPT_S3_URL: s3://[bucket-name]/path/to/script.sh
# AWS_SSM_PARAMETER_PATHS e.g. "path1;path2;..."

#endregion

#region validations

if [[ "$AWS_REGION" == "" ]];then
  echo "[build-container]: AWS Region not set. please set AWS Region"
  exit 1
fi

if [[ "$LOAD_ENV_VARS_SCRIPT_S3_URL" == "" ]];then
  echo "[build-container]: load-env-vars script AWS S3 URL not set. please set load-env-vars script AWS S3 URL"
  exit 1
fi

if [[ "$AWS_SSM_PARAMETER_PATHS" == "" ]];then
  echo "[build-container]: AWS SSM Parameter Store path(s) not set. please set AWS SSM Parameter Store path(s)"
  exit 1
fi

#endregion

LOAD_ENV_VARS_SCRIPT_PATH=./ci/load-env-vars.sh

aws s3 cp $LOAD_ENV_VARS_SCRIPT_S3_URL $LOAD_ENV_VARS_SCRIPT_PATH

source $LOAD_ENV_VARS_SCRIPT_PATH $AWS_REGION $AWS_SSM_PARAMETER_PATHS $(pwd) \
  && npm run build

echo "[build-web]: done."
