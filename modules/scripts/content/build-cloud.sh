#!/bin/bash

set -euo pipefail

#region required variables

# LOAD_ENV_VARS_SCRIPT_S3_URL: s3://[bucket-name]/path/to/script.sh
# AWS_REGION e.g. 'eu-west-1'
# AWS_SSM_PARAMETER_PATHS e.g. "path1;path2;..."
# ENV_VARS_S3_URL: s3://[bucket-name]/path/to/.env
# WORKING_DIR e.g. "./module"

#endregion

#region install terraform
apt-get update -y
apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update && apt-get install terraform
#endregion


#region validations

if [[ "$LOAD_ENV_VARS_SCRIPT_S3_URL" == "" ]];then
  echo "[build-cloud]: load-env-vars script AWS S3 URL not set. please set load-env-vars script AWS S3 URL"
  exit 1
fi

if [[ "$AWS_REGION" == "" ]];then
  echo "[build-cloud]: AWS Region not set. please set AWS Region"
  exit 1
fi

if [[ "$ENV_VARS_S3_URL" == "" ]];then
  echo "[build-cloud]: .env file AWS S3 URL not set. please set .env file AWS S3 URL"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  echo "[build-cloud]: terraform child directory is not set, using default: $(pwd)"
  WORKING_DIR=$(pwd)
fi

#endregion

echo '[build-cloud]: starting'

if [[ "$AWS_SSM_PARAMETER_PATHS" != "" ]];then
  LOAD_ENV_VARS_SCRIPT_PATH=./ci/load-env-vars.sh
  aws s3 cp $LOAD_ENV_VARS_SCRIPT_S3_URL $LOAD_ENV_VARS_SCRIPT_PATH
  source $LOAD_ENV_VARS_SCRIPT_PATH $AWS_REGION $AWS_SSM_PARAMETER_PATHS $ENV_VARS_S3_URL $WORKING_DIR
fi

terraform -chdir=$WORKING_DIR init
terraform -chdir=$WORKING_DIR validate
terraform -chdir=$WORKING_DIR plan -input=false -out=tfplan

echo '[build-cloud]: done.'
exit 0
