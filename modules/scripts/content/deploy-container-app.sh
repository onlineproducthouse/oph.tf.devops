#!/bin/bash

set -euo pipefail

#region required variables

# AWS_REGION e.g. 'eu-west-1'
# LOAD_ENV_VARS_SCRIPT_S3_URL: s3://[bucket-name]/path/to/script.sh
# AWS_SSM_PARAMETER_PATHS e.g. "path1;path2;..."
# ENV_VARS_S3_URL: s3://[bucket-name]/path/to/.env
# TASK_FAMILY
# TASK_ROLE_ARN
# CONTAINER_PORT
# CONTAINER_CPU
# CONTAINER_MEMORY_RESERVATION
# CLUSTER_NAME
# SERVICE_NAME

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

if [[ "$ENV_VARS_S3_URL" == "" ]];then
  echo "[build-container]: AWS S3 url for env variables not set. please set AWS S3 url for env variables"
  exit 1
fi

if [[ "$TASK_FAMILY" == "" ]];then
  echo "[build-container]: AWS ECS task family not set. please set AWS ECS task family"
  exit 1
fi

if [[ "$TASK_ROLE_ARN" == "" ]];then
  echo "[build-container]: AWS ECS task role arn not set. please set AWS ECS task role arn"
  exit 1
fi

if [[ "$CONTAINER_PORT" == "" ]];then
  echo "[build-container]: AWS ECS container port not set. please set AWS ECS container port"
  exit 1
fi

if [[ "$CONTAINER_CPU" == "" ]];then
  echo "[build-container]: AWS ECS container cpu not set. please set AWS ECS container cpu"
  exit 1
fi

if [[ "$CONTAINER_MEMORY_RESERVATION" == "" ]];then
  echo "[build-container]: AWS ECS container memory reservation not set. please set AWS ECS container memory reservation"
  exit 1
fi

if [[ "$CLUSTER_NAME" == "" ]];then
  echo "[build-container]: AWS ECS cluster name not set. please set AWS ECS cluster name"
  exit 1
fi

if [[ "$SERVICE_NAME" == "" ]];then
  echo "[build-container]: AWS ECS service name not set. please set AWS ECS cluster name"
  exit 1
fi

#endregion

LOAD_ENV_VARS_SCRIPT_PATH=./ci/load-env-vars.sh
aws s3 cp $LOAD_ENV_VARS_SCRIPT_S3_URL $LOAD_ENV_VARS_SCRIPT_PATH

# mkdir $CI_FOLDER
ECS_TASK=./ci/ecs/task-ecs.json
touch $ECS_TASK

LOCAL_PORT_MAPPING='[]'
if [[ "$CONTAINER_PORT" != "" && $CONTAINER_PORT != "0" ]]; then
  LOCAL_PORT_MAPPING='[
    {
      "name": "'$TASK_FAMILY'",
      "protocol": "tcp",
      "containerPort": '$CONTAINER_PORT',
      "hostPort": '$CONTAINER_PORT'
    }
  ]'
fi

# populate ecs json files
source release-manifest \
  && echo '{
    "family": "'$TASK_FAMILY'",
    "taskRoleArn": "'$TASK_ROLE_ARN'",
    "executionRoleArn": "'$TASK_ROLE_ARN'",
    "networkMode": "host",
    "requiresCompatibilities": ["EC2"],
    "cpu": "'$CONTAINER_CPU'",
    "memory": "'$CONTAINER_MEMORY_RESERVATION'",
    "containerDefinitions": [
      {
        "name": "'$TASK_FAMILY'",
        "essential": true,
        "image": "'$DKR_IMAGE'",
        "cpu": '$CONTAINER_CPU',
        "memory": '$CONTAINER_MEMORY_RESERVATION',
        "portMappings": '$LOCAL_PORT_MAPPING',
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "'$TASK_FAMILY'",
            "awslogs-region": "'$AWS_REGION'",
            "awslogs-stream-prefix": "'$TASK_FAMILY'"
          }
        },
        "environmentFiles": [
          {
            "value": "arn:aws:s3:::'$ENV_VARS_S3_URL'",
            "type": "s3"
          }
        ]
      }
    ]
  }' >$ECS_TASK

aws ecs register-task-definition --family $TASK_FAMILY --cli-input-json file://$ECS_TASK
TASK_REVISION=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY | jq '.taskDefinition.revision')

aws ecs update-service --force-new-deployment \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --task-definition $TASK_FAMILY:$TASK_REVISION

echo "[deploy-container]: done."
