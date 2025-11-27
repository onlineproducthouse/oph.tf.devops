terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.23.0"
    }
  }
}

module "tech_stack" {
  source = "./modules/stack"
}

resource "aws_codestarconnections_connection" "githook" {
  name          = "${var.name}-${var.githook_provider}"
  provider_type = var.githook_provider
}

module "store" {
  source = "./modules/store"
  name   = var.name
}

module "scripts" {
  source    = "./modules/scripts"
  bucket_id = module.store.id
}

module "docker" {
  source = "./modules/docker"

  name       = var.name
  account_id = var.account_id
  region     = var.region
}

module "role" {
  source = "./modules/role"
  name   = var.name
}

module "pipeline" {
  source = "./modules/pipeline"

  for_each = {
    for v in var.projects : v.name => v
  }

  name         = each.value.name
  git_repo     = each.value.git_repo
  is_container = each.value.is_container
  stages       = each.value.stages
  pipeline     = each.value.pipelines

  role_arn                 = module.role.arn
  artifact_store_bucket_id = module.store.id
  githook_arn              = aws_codestarconnections_connection.githook.arn

  job = [for job in each.value.jobs : {
    name    = "${job.branch_name}-${job.environment_name}"
    timeout = job.timeout

    vpc_id      = each.value.vpc_id
    vpc_subnets = each.value.vpc_subnets

    role_arn  = module.role.arn
    buildspec = module.scripts.content["codebuild_job"].arn

    env_variables = [
      { key = "JOB_SCRIPT_STORE_URL", value = module.scripts.content["${job.action}_${job.action_item}"].url },
      { key = "ENVIRONMENT_NAME", value = job.environment_name },

      { key = "LOAD_ENV_VARS_SCRIPT_S3_URL", value = module.scripts.content["load_env_vars"].url },

      { key = "AWS_REGION", value = var.region },
      { key = "AWS_SSM_PARAMETER_PATHS", value = job.ssm_param_paths },
      { key = "ENV_VARS_S3_URL", value = "s3://${module.store.id}/configs/${var.name}/${each.value.name}/${job.branch_name}-${job.environment_name}/.env" },
      { key = "ENV_VARS_S3_ARN", value = "arn:aws:s3:::${module.store.id}/configs/${var.name}/${each.value.name}/${job.branch_name}-${job.environment_name}/.env" },
      { key = "WORKING_DIR", value = job.working_dir },

      { key = "RELEASE_MANIFEST", value = "release_manifest.txt" },
      { key = "GIT_BRANCH", value = job.branch_name },
      { key = "IMAGE_REGISTRY_BASE_URL", value = module.docker.base_url },
      { key = "DOCKERFILE", value = each.value.dockerfile },

      { key = "TASK_FAMILY", value = job.task_family },
      { key = "TASK_ROLE_ARN", value = job.task_role },
      { key = "CONTAINER_PORT", value = job.container_port },
      { key = "CONTAINER_CPU", value = job.container_cpu },
      { key = "CONTAINER_MEMORY_RESERVATION", value = job.container_memory_reservation },
      { key = "CLUSTER_NAME", value = job.cluster_name },
      { key = "SERVICE_NAME", value = job.service_name },
    ]
  }]
}
