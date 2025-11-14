#!/bin/bash

set -euo pipefail

#region required variables

# ENVIRONMENT_NAME e.g. "prod"
# MODULE_DIR e.g. "./module"

#endregion

echo '[deploy-cloud]: starting'

export TF_VAR_ENVIRONMENT_NAME=$ENVIRONMENT_NAME

if [[ "$MODULE_DIR" == "" ]]; then
  echo "[build-cloud]: terraform child directory is not set, using default: $(pwd)"
  MODULE_DIR=$(pwd)
fi

terraform -chdir=$MODULE_DIR apply tfplan -input=false -auto-approve

echo '[build-cloud]: done.'
exit 0
