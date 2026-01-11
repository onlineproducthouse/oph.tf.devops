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
              Action = [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",

                "codestar-connections:UseConnection",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:PutObject",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogGroup",
              ],
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
              Action = [
                "codebuild:BatchGetProjects",
                "codebuild:UpdateProject",

                "codeconnections:GetConnection",
                "codeconnections:ListTagsForResource",

                "codepipeline:GetPipeline",
                "codepipeline:ListTagsForResource",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:DeleteObject",
                "s3:Describe*",
                "s3:Get*",
                "s3:List*",
                "s3:PutObject",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecr:GetAuthorizationToken",
                "ecr:GetLifecyclePolicy",
                "ecr:ListTagsForResource",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetRole",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
              ]
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
              Action = [
                "codebuild:BatchGetProjects",
                "codebuild:CreateProject",
                "codebuild:DeleteProject",
                "codebuild:UpdateProject",

                "codeconnections:CreateConnection",
                "codeconnections:GetConnection",
                "codeconnections:ListTagsForResource",

                "codepipeline:GetPipeline",
                "codepipeline:ListTagsForResource",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:CreateBucket",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:Describe*",
                "s3:Get*",
                "s3:List*",
                "s3:PutBucketVersioning",
                "s3:PutEncryptionConfiguration",
                "s3:PutObject",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecr:GetAuthorizationToken",
                "ecr:GetLifecyclePolicy",
                "ecr:ListTagsForResource",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetRole",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicyVersions",
                "iam:ListRolePolicies",
              ]
            },
          ]
        })
      },
    ]
  }

  _iam = {
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
              Action = [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",

                "codeconnections:Get*",
                "codeconnections:List*",

                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary",

                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:PollForJobs",
                "codepipeline:TagResource",
                "codepipeline:UntagResource",

                "codestar-connections:PassConnection",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "iam:AttachRolePolicy",
                "iam:DeletePolicyVersion",
                "iam:DetachRolePolicy",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "iam:PassRole",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
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
              Action = [
                "codebuild:CreateProject",
                "codebuild:CreateWebhook",
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*",
                "codebuild:UpdateProject",
                "codebuild:UpdateWebhook",
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "autoscaling:CreateOrUpdateTags"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codepipeline:CreatePipeline",
                "codepipeline:DisableStageTransition",
                "codepipeline:EnableStageTransition",
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:PutWebhook",
                "codepipeline:TagResource",
                "codepipeline:UntagResource",
                "codepipeline:UpdateActionType",
                "codepipeline:UpdatePipeline",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:Describe*",
              ],
              Condition = {
                StringEquals = {
                  "ec2:AuthorizedService" = "codebuild.amazonaws.com"
                }
              }
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudfront:CreateDistribution",
                "cloudfront:CreateInvalidation",
                "cloudfront:GetDistribution",
                "cloudfront:ListDistributions",
                "cloudfront:TagResource",
                "cloudfront:UntagResource",
                "cloudfront:UpdateDistribution",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DeleteLogDelivery",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:DescribeDestinations",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:UpdateLogDelivery"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecr:BatchGetImage",
                "ecr:CreateRepository",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:ListImages",
                "ecr:ListTagsForResource",
                "ecr:PutImage",
                "ecr:PutLifecyclePolicy",
                "ecr:StartImageScan",
                "ecr:TagResource",
                "ecr:UntagResource",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecs:CreateCapacityProvider",
                "ecs:CreateCluster",
                "ecs:CreateService",
                "ecs:CreateTaskSet",
                "ecs:DeleteCapacityProvider",
                "ecs:DeregisterContainerInstance",
                "ecs:DeregisterTaskDefinition",
                "ecs:DescribeCapacityProviders",
                "ecs:DescribeClusters",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeTaskSets",
                "ecs:DescribeTasks",
                "ecs:ListAttributes",
                "ecs:ListClusters",
                "ecs:ListContainerInstances",
                "ecs:ListServices",
                "ecs:ListTaskDefinitionFamilies",
                "ecs:ListTaskDefinitions",
                "ecs:ListTasks",
                "ecs:PutAttributes",
                "ecs:RegisterTaskDefinition",
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask",
                "ecs:TagResource",
                "ecs:UntagResource",
                "ecs:UpdateCapacityProvider",
                "ecs:UpdateCluster",
                "ecs:UpdateContainerInstancesState",
                "ecs:UpdateService",
                "ecs:UpdateTaskSet"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:Get*",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:ModifyRule",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RegisterListenerCertificates",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Condition = {
                StringLike = {
                  "iam:AWSServiceName" = "ecs.amazonaws.com"
                }
              },
              Action = [
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:DetachRolePolicy",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "iam:PutRolePolicy",
                "iam:PassRole",

                "iam:CreateServiceLinkedRole",
                "iam:UpdateRoleDescription",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ssm:GetParametersByPath"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary"
              ],
            }
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
              Action = [
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:TagResource",
                "codepipeline:UntagResource"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:Describe*",
              ],
              Condition = {
                StringEquals = {
                  "ec2:AuthorizedService" = "codebuild.amazonaws.com"
                }
              }
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DeleteLogDelivery",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:DescribeDestinations",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:UpdateLogDelivery"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecr:BatchGetImage",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:ListImages",
                "ecr:ListTagsForResource",
                "ecr:PutImage",
                "ecr:StartImageScan",
                "ecr:TagResource",
                "ecr:UntagResource",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecs:CreateCapacityProvider",
                "ecs:CreateService",
                "ecs:CreateTaskSet",
                "ecs:DeleteCapacityProvider",
                "ecs:DeregisterContainerInstance",
                "ecs:DeregisterTaskDefinition",
                "ecs:DescribeCapacityProviders",
                "ecs:DescribeClusters",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeTaskSets",
                "ecs:DescribeTasks",
                "ecs:ListAttributes",
                "ecs:ListClusters",
                "ecs:ListContainerInstances",
                "ecs:ListServices",
                "ecs:ListTaskDefinitionFamilies",
                "ecs:ListTaskDefinitions",
                "ecs:ListTasks",
                "ecs:PutAttributes",
                "ecs:RegisterTaskDefinition",
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask",
                "ecs:TagResource",
                "ecs:UntagResource",
                "ecs:UpdateCapacityProvider",
                "ecs:UpdateContainerInstancesState",
                "ecs:UpdateService",
                "ecs:UpdateTaskSet"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Condition = {
                StringLike = {
                  "iam:AWSServiceName" = "ecs.amazonaws.com"
                }
              },
              Action = [
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "iam:PassRole"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ssm:GetParametersByPath"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary"
              ],
            }
          ]
        })
      },
      {
        name = "${local.name}-build-web"

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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:TagResource",
                "codepipeline:UntagResource"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:Describe*",
              ],
              Condition = {
                StringEquals = {
                  "ec2:AuthorizedService" = "codebuild.amazonaws.com"
                }
              }
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudfront:CreateInvalidation",
                "cloudfront:GetDistribution",
                "cloudfront:ListDistributions",
                "cloudfront:TagResource",
                "cloudfront:UntagResource",
                "cloudfront:UpdateDistribution"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DeleteLogDelivery",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:DescribeDestinations",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:UpdateLogDelivery"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ssm:GetParametersByPath"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary"
              ],
            }
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
              Action = [
                "codebuild:CreateProject",
                "codebuild:CreateWebhook",
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*",
                "codebuild:UpdateProject",
                "codebuild:UpdateWebhook"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "autoscaling:CreateOrUpdateTags"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codepipeline:CreatePipeline",
                "codepipeline:DisableStageTransition",
                "codepipeline:EnableStageTransition",
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:PutWebhook",
                "codepipeline:TagResource",
                "codepipeline:UntagResource",
                "codepipeline:UpdateActionType",
                "codepipeline:UpdatePipeline",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:Describe*",
              ],
              Condition = {
                StringEquals = {
                  "ec2:AuthorizedService" = "codebuild.amazonaws.com"
                }
              }
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudfront:CreateDistribution",
                "cloudfront:CreateInvalidation",
                "cloudfront:GetDistribution",
                "cloudfront:ListDistributions",
                "cloudfront:TagResource",
                "cloudfront:UntagResource",
                "cloudfront:UpdateDistribution",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DeleteLogDelivery",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:DescribeDestinations",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:UpdateLogDelivery"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecr:BatchGetImage",
                "ecr:CreateRepository",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:ListImages",
                "ecr:ListTagsForResource",
                "ecr:PutImage",
                "ecr:PutLifecyclePolicy",
                "ecr:StartImageScan",
                "ecr:TagResource",
                "ecr:UntagResource",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecs:CreateCapacityProvider",
                "ecs:CreateCluster",
                "ecs:CreateService",
                "ecs:CreateTaskSet",
                "ecs:DeleteCapacityProvider",
                "ecs:DeregisterContainerInstance",
                "ecs:DeregisterTaskDefinition",
                "ecs:DescribeCapacityProviders",
                "ecs:DescribeClusters",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeTaskSets",
                "ecs:DescribeTasks",
                "ecs:ListAttributes",
                "ecs:ListClusters",
                "ecs:ListContainerInstances",
                "ecs:ListServices",
                "ecs:ListTaskDefinitionFamilies",
                "ecs:ListTaskDefinitions",
                "ecs:ListTasks",
                "ecs:PutAttributes",
                "ecs:RegisterTaskDefinition",
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask",
                "ecs:TagResource",
                "ecs:UntagResource",
                "ecs:UpdateCapacityProvider",
                "ecs:UpdateCluster",
                "ecs:UpdateContainerInstancesState",
                "ecs:UpdateService",
                "ecs:UpdateTaskSet"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:Get*",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:ModifyRule",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RegisterListenerCertificates",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Condition = {
                StringLike = {
                  "iam:AWSServiceName" = "ecs.amazonaws.com"
                }
              },
              Action = [
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:DetachRolePolicy",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "iam:PutRolePolicy",
                "iam:PassRole",

                "iam:CreateServiceLinkedRole",
                "iam:UpdateRoleDescription",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ssm:GetParametersByPath"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary"
              ],
            }
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
              Action = [
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:TagResource",
                "codepipeline:UntagResource"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:Describe*",
              ],
              Condition = {
                StringEquals = {
                  "ec2:AuthorizedService" = "codebuild.amazonaws.com"
                }
              }
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DeleteLogDelivery",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:DescribeDestinations",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:UpdateLogDelivery"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecr:BatchGetImage",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:ListImages",
                "ecr:ListTagsForResource",
                "ecr:TagResource",
                "ecr:UntagResource",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecs:CreateCapacityProvider",
                "ecs:CreateService",
                "ecs:CreateTaskSet",
                "ecs:DeleteCapacityProvider",
                "ecs:DeregisterContainerInstance",
                "ecs:DeregisterTaskDefinition",
                "ecs:DescribeCapacityProviders",
                "ecs:DescribeClusters",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeTaskSets",
                "ecs:DescribeTasks",
                "ecs:ListAttributes",
                "ecs:ListClusters",
                "ecs:ListContainerInstances",
                "ecs:ListServices",
                "ecs:ListTaskDefinitionFamilies",
                "ecs:ListTaskDefinitions",
                "ecs:ListTasks",
                "ecs:PutAttributes",
                "ecs:RegisterTaskDefinition",
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask",
                "ecs:TagResource",
                "ecs:UntagResource",
                "ecs:UpdateCapacityProvider",
                "ecs:UpdateContainerInstancesState",
                "ecs:UpdateService",
                "ecs:UpdateTaskSet"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Condition = {
                StringLike = {
                  "iam:AWSServiceName" = "ecs.amazonaws.com"
                }
              },
              Action = [
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "iam:PassRole"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ssm:GetParametersByPath"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary"
              ],
            }
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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:TagResource",
                "codepipeline:UntagResource"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:Describe*",
              ],
              Condition = {
                StringEquals = {
                  "ec2:AuthorizedService" = "codebuild.amazonaws.com"
                }
              }
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DeleteLogDelivery",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:DescribeDestinations",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:UpdateLogDelivery"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ecr:BatchGetImage",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:ListImages",
                "ecr:ListTagsForResource",
                "ecr:StartImageScan",
                "ecr:TagResource",
                "ecr:UntagResource",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Condition = {
                StringLike = {
                  "iam:AWSServiceName" = "ecs.amazonaws.com"
                }
              },
              Action = [
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListPolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "iam:PassRole"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ssm:GetParametersByPath"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary"
              ],
            }
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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*"
              ]
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:TagResource",
                "codepipeline:UntagResource"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:Describe*",
              ],
              Condition = {
                StringEquals = {
                  "ec2:AuthorizedService" = "codebuild.amazonaws.com"
                }
              }
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudfront:CreateInvalidation",
                "cloudfront:GetDistribution",
                "cloudfront:ListDistributions",
                "cloudfront:TagResource",
                "cloudfront:UntagResource",
                "cloudfront:UpdateDistribution"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DeleteLogDelivery",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:DescribeDestinations",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:UpdateLogDelivery"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "ssm:GetParametersByPath"
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "s3:Get*",
                "s3:PutObject",
                "s3:List*",
              ],
            },
            {
              Effect   = "Allow",
              Resource = "*",
              Action = [
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplateSummary"
              ],
            }
          ]
        })
      },
    ]
  }
}
