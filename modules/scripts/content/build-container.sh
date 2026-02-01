#!/bin/bash

set -euo pipefail

#region required variables

# GIT_BRANCH
# RELEASE_MANIFEST
# IMAGE_REGISTRY_BASE_URL
# IMAGE_REPOSITORY_NAME
# DOCKERFILE
# WORKING_DIR

if [[ "$GIT_BRANCH" == "" ]];then
  echo "[build-container]: git branch name not set. please set git branch name"
  exit 1
fi

if [[ "$RELEASE_MANIFEST" == "" ]];then
  echo "[build-container]: release manifest name not set. please set release manifest name"
  exit 1
fi

if [[ "$IMAGE_REGISTRY_BASE_URL" == "" ]];then
  echo "[build-container]: image registry base url not set. please set image registry base url"
  exit 1
fi

if [[ "$IMAGE_REPOSITORY_NAME" == "" ]];then
  echo "[build-container]: image registry not set. please set image registry name"
  exit 1
fi

if [[ "$DOCKERFILE" == "" ]];then
  echo "[build-container]: dockerfile not set. please set dockerfile name"
  exit 1
fi

if [[ "$WORKING_DIR" == "" ]]; then
  WORKING_DIR=$(pwd)
else
  WORKING_DIR="$(pwd)/$WORKING_DIR"
fi

echo "[run-test]: working directory set to: $WORKING_DIR"

#endregion

# if [[ "$GIT_BRANCH" == "develop" ]]; then
#   IMAGE_TAG="$IMAGE_REPOSITORY_NAME:latest"
# else
#   IMAGE_TAG="$IMAGE_REPOSITORY_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION"
# fi

# FULL_IMAGE_TAG=$IMAGE_REGISTRY_BASE_URL/$IMAGE_TAG

# echo $(aws ecr get-login-password | docker login --username AWS --password-stdin $IMAGE_REGISTRY_BASE_URL)

# export BUILDX_VERSION=$(curl --silent "https://api.github.com/repos/docker/buildx/releases/latest" | jq -r .tag_name)
# curl -JLO "https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-amd64"
# mkdir -p ~/.docker/cli-plugins
# mv "buildx-$BUILDX_VERSION.linux-amd64" ~/.docker/cli-plugins/docker-buildx
# chmod +x ~/.docker/cli-plugins/docker-buildx
# docker run --privileged --rm "$IMAGE_REGISTRY_BASE_URL/tonistiigi/binfmt:latest" --install arm64
# docker buildx create --use --name multiarch
# docker buildx build --push --force-rm \
#   --platform=linux/arm64,linux/amd64 \
#   --tag $FULL_IMAGE_TAG \
#   --build-arg IMAGE_REGISTRY_BASE_URL=$IMAGE_REGISTRY_BASE_URL \
#   --file $DOCKERFILE \
#   $WORKING_DIR

# if [[ "$GIT_BRANCH" != "develop" ]]; then
#   echo "DKR_IMAGE=$FULL_IMAGE_TAG" >$RELEASE_MANIFEST
# fi

echo "[build-container]: Done."
exit 0
