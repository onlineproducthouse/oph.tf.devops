#!/bin/bash

set -euo pipefail

#region required variables

# AWS_REGION e.g. 'eu-west-1'
# LOAD_ENV_VARS_SCRIPT_S3_URL: s3://[bucket-name]/path/to/script.sh
# ENV_VARS_S3_URL: s3://[bucket-name]/path/to/.env
# AWS_SSM_PARAMETER_PATHS e.g. "path1;path2;..."
# WORKING_DIR
# RELEASE_MANIFEST

if [[ "$AWS_REGION" == "" ]];then
  echo "[deploy-container-db]: AWS Region not set. please set AWS Region"
  exit 1
fi

if [[ "$LOAD_ENV_VARS_SCRIPT_S3_URL" == "" ]];then
  echo "[deploy-container-db]: load-env-vars script AWS S3 URL not set. please set load-env-vars script AWS S3 URL"
  exit 1
fi

if [[ "$ENV_VARS_S3_URL" == "" ]];then
  echo "[deploy-container-db]: .env file AWS S3 URL not set. please set .env file AWS S3 URL"
  exit 1
fi

if [[ "$AWS_SSM_PARAMETER_PATHS" == "" ]];then
  echo "[deploy-container-db]: AWS SSM Parameter Store path(s) not set. please set AWS SSM Parameter Store path(s)"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  echo "[deploy-container-db]: terraform child directory is not set, using default: $(pwd)"
  WORKING_DIR=$(pwd)
fi

if [[ "$RELEASE_MANIFEST" == "" ]];then
  echo "[deploy-container-db]: release manifest name not set. please set release manifest name"
  exit 1
fi

#endregion

ENV_FILE="$WORKING_DIR/.env"
LOAD_ENV_VARS_SCRIPT_PATH="$WORKING_DIR/ci/load-env-vars.sh"

aws s3 cp $LOAD_ENV_VARS_SCRIPT_S3_URL $LOAD_ENV_VARS_SCRIPT_PATH

source $LOAD_ENV_VARS_SCRIPT_PATH $AWS_REGION $AWS_SSM_PARAMETER_PATHS $ENV_VARS_S3_URL $WORKING_DIR

# Authenticate ECR
echo "ECR: Authenticating"
echo $(aws ecr get-login-password | docker login --username AWS --password-stdin $IMAGE_REGISTRY_BASE_URL)
echo "ECR: Authenticated"

source $RELEASE_MANIFEST && \
  docker pull $DKR_IMAGE && \
  docker run --env-file $ENV_FILE $DKR_IMAGE

echo "[deploy-container-db]: done."
