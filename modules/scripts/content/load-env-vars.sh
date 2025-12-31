#!/bin/bash

set -euo pipefail

#region required variables
# $1 = $AWS_REGION
# $2 = $AWS_SSM_PARAMETER_PATHS
# $3 = $ENV_VARS_S3_URL
# $4 = $WORKING_DIR
#endregion

apt-get update -y
apt-get install -y jq

AWS_REGION=$1
AWS_SSM_PARAMETER_PATHS=$2 # e.g. "path1;path2;..."
ENV_VARS_S3_URL=$3
WORKING_DIR=$4

ENV_FILE="$WORKING_DIR/.env"

if [[ "$AWS_SSM_PARAMETER_PATHS" == "" ]]; then
  echo "AWS_SSM_PARAMETER_PATHS variable not set"
else
  rm -rf $ENV_FILE
  touch $ENV_FILE

  IFS=';'

  for i in $AWS_SSM_PARAMETER_PATHS; do
    echo "[load-env-vars]: Loading environment variables at path: $i"

    AWS_SSM_PARAMS_RESULT=$(echo $(aws ssm get-parameters-by-path --path "$i" --region "$AWS_REGION" --recursive --with-decryption --output "json") | jq '.Parameters')
    AWS_SSM_PARAMS_COUNT=$(echo $AWS_SSM_PARAMS_RESULT | jq '. | length')

    for ((j = 0; j < $((AWS_SSM_PARAMS_COUNT * 1)); j++)); do
      echo "[load-env-vars]: Current index: $j"

      PARAM_NAME=$(echo $AWS_SSM_PARAMS_RESULT | jq ".[$j].Name")
      PARAM_VALUE=$(echo $AWS_SSM_PARAMS_RESULT | jq ".[$j].Value")

      KEY=$(sed -e 's/^"//' -e 's/"$//' -e 's|'"$i"'/["]*||' <<<$(echo $PARAM_NAME))
      VALUE=$(sed -e 's/^"//' -e 's/"$//' <<<$(echo $PARAM_VALUE))

      PARAM=$(echo "$KEY"="$VALUE")

      echo $PARAM >>$ENV_FILE
    done

    echo "echo "[load-env-vars]: Total parameters retrieved from AWS SSM: $AWS_SSM_PARAMS_COUNT"

    echo "echo "[load-env-vars]: Done loading environment variables at path: $i"
  done

  aws s3 cp $ENV_FILE $ENV_VARS_S3_URL
fi
