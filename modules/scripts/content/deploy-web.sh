#!/bin/bash

set -euo pipefail

#region required variables

# S3_HOST_BUCKET_NAME
# WORKING_DIR
# CDN_ID

if [[ "$S3_HOST_BUCKET_NAME" == "" ]];then
  echo "[deploy-web]: AWS S3 Bucket name not set. please set AWS S3 Bucket name"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  WORKING_DIR=$(pwd)
else
  WORKING_DIR="$(pwd)/$WORKING_DIR"
fi

if [[ "$CDN_ID" == "" ]];then
  echo "[deploy-web]: AWS CloudFront CDN id not set. please set AWS CloudFront CDN id"
  exit 1
fi

#endregion

INVALIDATION_CONFIG_PATH=$(pwd)/inv-batch.json

echo '{
  "Paths": {
    "Quantity": 1,
    "Items": ["/*"]
  },
  "CallerReference": "'$CODEBUILD_BUILD_NUMBER'"
}' >$INVALIDATION_CONFIG_PATH

cat $INVALIDATION_CONFIG_PATH

aws s3 sync $WORKING_DIR "s3://$S3_HOST_BUCKET_NAME"
aws cloudfront create-invalidation \
  --distribution-id $CDN_ID \
  --invalidation-batch "file://$INVALIDATION_CONFIG_PATH"

echo "[deploy-web]: done."
