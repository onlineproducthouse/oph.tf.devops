#!/bin/bash

set -euo pipefail

#
# -----------------------------------------------------
# Script parameters
# -----------------------------------------------------
#
# $1 = $AWS_REGION
# $2 = $AWS_SSM_PARAMETER_PATHS
# $3 = $WORKING_DIR
#

AWS_REGION=$1
AWS_SSM_PARAMETER_PATHS=$2 # e.g. "path1;path2;..."
WORKING_DIR=$3
ENV_FILE="$WORKING_DIR/.env"

if [[ "$AWS_SSM_PARAMETER_PATHS" == "-1" ]]; then
  echo "AWS_SSM_PARAMETER_PATHS variable not set"
else
  rm -rf $ENV_FILE
  touch $ENV_FILE

  IFS=';'

  for i in $AWS_SSM_PARAMETER_PATHS; do
    echo "Loading environment variables at path: $i"

    AWS_SSM_PARAMS_RESULT=$(echo $(aws ssm get-parameters-by-path --path "$i" --region "$AWS_REGION" --recursive --with-decryption --output "json") | jq '.Parameters')
    AWS_SSM_PARAMS_COUNT=$(echo $AWS_SSM_PARAMS_RESULT | jq '. | length')

    echo "Total parameters retrieved from AWS SSM: $AWS_SSM_PARAMS_COUNT"

    for ((j = 0; j < $((AWS_SSM_PARAMS_COUNT * 1)); j++)); do
      PARAM_NAME=$(echo $AWS_SSM_PARAMS_RESULT | jq ".[$j].Name")
      PARAM_VALUE=$(echo $AWS_SSM_PARAMS_RESULT | jq ".[$j].Value")

      KEY=$(sed -e 's/^"//' -e 's/"$//' -e 's|'"$i"'/["]*||' <<<$(echo $PARAM_NAME))
      VALUE=$(sed -e 's/^"//' -e 's/"$//' <<<$(echo $PARAM_VALUE))

      export PARAM=$(echo "$KEY"="$VALUE")

      echo $PARAM >>$ENV_FILE
    done

    echo "Done loading environment variables at path: $i"
  done

  # Authenticate ECR
  echo "ECR: Authenticating"
  source $ENV_FILE && echo $(aws ecr get-login-password | docker login --username AWS --password-stdin $IMAGE_REGISTRY_BASE_URL)
  echo "ECR: Authenticated"
fi
