terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.23.0"
    }
  }
}

module "store" {
  source = "./modules/store"
  name   = local.name
}

module "scripts" {
  source    = "./modules/scripts"
  bucket_id = module.store.id
}

module "docker" {
  source = "./modules/docker"

  name       = local.name
  account_id = var.account_id
  region     = var.region
}

module "role" {
  source = "./modules/role"

  for_each = {
    for v in local.iam.policy : v.name => {
      assume_role_policy = v.assume_role_content
      policy             = v.content
    }
  }

  name               = each.key
  region             = var.region
  account_id         = var.account_id
  assume_role_policy = each.value.assume_role_policy
  policy             = each.value.policy
}

module "pipeline" {
  source = "./modules/pipeline"

  for_each = {
    for v in var.repositories : v.name => v
  }

  name         = each.key
  account_id   = var.account_id
  region       = var.region
  git_provider = each.value.git_provider
  git_repo     = each.value.git_repo
  is_container = each.value.is_container
  stages       = each.value.stages
  pipeline     = each.value.pipelines

  role_arn                 = module.role["${local.name}-pipelines"].arn
  artifact_store_bucket_id = module.store.id

  job = [for job in each.value.jobs : {
    name    = "${each.key}-${job.branch_name}-${job.environment_name}"
    image   = job.image
    timeout = job.timeout

    vpc_id      = each.value.vpc_id
    vpc_subnets = each.value.vpc_subnets

    role_arn  = module.role[replace("${local.name}-${job.action}-${job.action_item}", "_", "-")].arn
    buildspec = module.scripts.content["codebuild-job"].arn

    env_variables = [
      { key = "JOB_SCRIPT_STORE_URL", value = module.scripts.content["${job.action}-${job.action_item}"].url },
      { key = "ENVIRONMENT_NAME", value = job.environment_name },

      { key = "LOAD_ENV_VARS_SCRIPT_S3_URL", value = module.scripts.content["load-env-vars"].url },

      { key = "AWS_REGION", value = var.region },
      { key = "AWS_SSM_PARAMETER_PATHS", value = job.ssm_param_paths },
      { key = "ENV_VARS_S3_URL", value = "s3://${module.store.id}/configs/${local.name}/${each.key}/${job.branch_name}-${job.environment_name}/.env" },
      { key = "ENV_VARS_S3_ARN", value = "arn:aws:s3:::${module.store.id}/configs/${local.name}/${each.key}/${job.branch_name}-${job.environment_name}/.env" },
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

locals {
  name = replace(var.name, "_", "-")

  iam = {
    policy = [
      {
        name = "${local.name}-pipelines"

        assume_role_content = jsonencode({
          Version = "2012-10-17"

          Statement = [
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "codepipeline.amazonaws.com"
              },
            },
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action   = local.action_list,
            },
          ]
        })
      },
      {
        name = "${local.name}-build-cloud"

        assume_role_content = jsonencode({
          Version = "2012-10-17"

          Statement = [
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "codebuild.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ec2.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs-tasks.amazonaws.com"
              },
            },
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action   = local.action_list,
            },
          ]
        })
      },
      {
        name = "${local.name}-deploy-cloud"

        assume_role_content = jsonencode({
          Version = "2012-10-17"

          Statement = [
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "codebuild.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ec2.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs-tasks.amazonaws.com"
              },
            },
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action   = local.action_list,
            },
          ]
        })
      },
      {
        name = "${local.name}-build-container"

        assume_role_content = jsonencode({
          Version = "2012-10-17"

          Statement = [
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "codebuild.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ec2.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs-tasks.amazonaws.com"
              },
            },
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action   = local.action_list,
            },
          ]
        })
      },
      {
        name = "${local.name}-deploy-container-app"

        assume_role_content = jsonencode({
          Version = "2012-10-17"

          Statement = [
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "codebuild.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ec2.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs-tasks.amazonaws.com"
              },
            },
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action   = local.action_list,
            },
          ]
        })
      },
      {
        name = "${local.name}-deploy-container-db"

        assume_role_content = jsonencode({
          Version = "2012-10-17"

          Statement = [
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "codebuild.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ec2.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs-tasks.amazonaws.com"
              },
            },
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action   = local.action_list,
            },
          ]
        })
      },
      {
        name = "${local.name}-deploy-web"

        assume_role_content = jsonencode({
          Version = "2012-10-17"

          Statement = [
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "codebuild.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ec2.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs.amazonaws.com"
              },
            },
            {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal : {
                Service : "ecs-tasks.amazonaws.com"
              },
            },
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action   = local.action_list,
            },
          ]
        })
      },
    ]
  }

  action_list = [
    "autoscaling:*",
    "cloudformation:*",
    "cloudfront:*",
    "codebuild:*",
    "codeconnections:*",
    "codepipeline:*",
    "codestar-connections:*",
    "ec2:*",
    "ecr:*",
    "ecs:*",
    "elasticloadbalancing:*",
    "iam:*",
    "logs:*",
    "s3:*",
    "ssm:*",
  ]
}
