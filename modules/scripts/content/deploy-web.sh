#!/bin/bash

set -euo pipefail

#region required variables

# S3_HOST_BUCKET_NAME
# ARTIFACT_PATH
# CDN_ID

#endregion

#region validations

if [[ "$S3_HOST_BUCKET_NAME" == "" ]];then
  echo "[build-container]: AWS S3 Bucket name not set. please set AWS S3 Bucket name"
  exit 1
fi

if [[ "$ARTIFACT_PATH" == "" ]];then
  echo "[build-container]: artifact path not set. please set artifact path"
  exit 1
fi

if [[ "$CDN_ID" == "" ]];then
  echo "[build-container]: AWS CloudFront CDN id not set. please set AWS CloudFront CDN id"
  exit 1
fi

#endregion

aws s3 sync $ARTIFACT_PATH "s3://$S3_HOST_BUCKET_NAME"

INVALIDATION_CONFIG_PATH=$(pwd)/ci/inv-batch.json

echo '{
  "Paths": {
    "Quantity": 1,
    "Items": ["/*"]
  },
  "CallerReference": "'$CODEBUILD_BUILD_NUMBER'"
}' >$INVALIDATION_CONFIG_PATH

aws cloudfront create-invalidation \
  --distribution-id $CDN_ID \
  --invalidation-batch "file://$INVALIDATION_CONFIG_PATH"

echo "[deploy-web]: done."
