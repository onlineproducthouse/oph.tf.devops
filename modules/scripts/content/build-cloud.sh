#!/bin/bash

set -euo pipefail

#region required variables

# ENVIRONMENT_NAME e.g. "prod"
# MODULE_DIR e.g. "./module"

#endregion

echo '[build-cloud]: starting'

export TF_VAR_ENVIRONMENT_NAME=$ENVIRONMENT_NAME

if [[ "$MODULE_DIR" == "" ]]; then
  echo "[build-cloud]: terraform child directory is not set, using default: $(pwd)"
  MODULE_DIR=$(pwd)
fi

terraform -chdir=$MODULE_DIR init
terraform -chdir=$MODULE_DIR validate
terraform -chdir=$MODULE_DIR plan -input=false -out=tfplan

echo '[build-cloud]: done.'
exit 0
