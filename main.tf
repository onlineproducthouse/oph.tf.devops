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
  name   = "${local.name}-devops-store"
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
    name          = "${each.key}-${job.branch_name}-${job.environment_name}"
    image         = job.image
    timeout       = job.timeout
    test_commands = job.test_commands

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
                "codebuild:BatchGet*",
                "codebuild:StartBuild",
                "codebuild:StopBuild",

                "codeconnections:PassConnection",
                "codeconnections:UseConnection",

                "codepipeline:StartPipelineExecution",

                "codestar-connections:UseConnection",

                "iam:PassRole",

                "s3:Describe*",
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
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
              Effect   = "Allow"
              Resource = "*"
              Action = [
                "acm:Add*",
                "acm:Delete*",
                "acm:Describe*",
                "acm:Get*",
                "acm:List*",
                "acm:RemoveTagsFrom*",
                "acm:Renew*",
                "acm:Request*",
                "acm:Revoke*",

                "codebuild:BatchGet*",
                "codebuild:CreateProject",
                "codebuild:Delete*",
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*",
                "codebuild:StartBuild",
                "codebuild:StopBuild",
                "codebuild:UpdateProject",

                "codeconnections:CreateConnection",
                "codeconnections:Delete*",
                "codeconnections:Get*",
                "codeconnections:List*",
                "codeconnections:PassConnection",
                "codeconnections:UseConnection",

                "cloudformation:Describe*",
                "cloudformation:Get*",
                "cloudformation:List*",
                "cloudformation:Tag*",
                "cloudformation:Untag*",

                "codepipeline:CreatePipeline",
                "codepipeline:Delete*",
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:Put*",
                "codepipeline:StartPipelineExecution",
                "codepipeline:StopPipelineExecution",
                "codepipeline:Tag*",
                "codepipeline:Untag*",
                "codepipeline:Update*",

                "codestar:CreateProject",
                "codestar:Delete*",
                "codestar:Describe*",
                "codestar:List*",
                "codestar:Tag*",
                "codestar:Untag*",
                "codestar:Update*",

                "codestar-connections:CreateConnection",
                "codestar-connections:DeleteConnection",
                "codestar-connections:Get*",
                "codestar-connections:List*",
                "codestar-connections:PassConnection",
                "codestar-connections:Tag*",
                "codestar-connections:Untag*",
                "codestar-connections:UseConnection",

                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGet*",
                "ecr:BatchImportUpstreamImage",
                "ecr:CompleteLayerUpload",
                "ecr:CreateRepository",
                "ecr:Delete*",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:InitiateLayerUpload",
                "ecr:List*",
                "ecr:Put*",
                "ecr:Replicate*",
                "ecr:Set*",
                "ecr:Tag*",
                "ecr:Untag*",
                "ecr:Upload*",

                "ecs:CreateCapacityProvider",
                "ecs:CreateCluster",
                "ecs:CreateService",
                "ecs:CreateTaskSet",
                "ecs:DeleteCapacityProvider",
                "ecs:DeleteCluster",
                "ecs:DeleteService",
                "ecs:DeleteTaskDefinitions",
                "ecs:DeleteTaskSet",
                "ecs:DeregisterContainerInstance",
                "ecs:DeregisterTaskDefinition",
                "ecs:Describe*",
                "ecs:List*",
                "ecs:PutClusterCapacityProviders",
                "ecs:Register*",
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask",
                "ecs:Tag*",
                "ecs:Untag*",
                "ecs:Update*",

                "cloudfront:AssociateAlias",
                "cloudfront:Create*",
                "cloudfront:DeleteDistribution",
                "cloudfront:Describe*",
                "cloudfront:Get*",
                "cloudfront:List*",
                "cloudfront:Tag*",
                "cloudfront:Untag*",
                "cloudfront:UpdateDistribution",

                "iam:AddRoleToInstanceProfile",
                "iam:AttachRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:CreateLoginProfile",
                "iam:CreatePolicyVersion",
                "iam:CreateRole",
                "iam:CreateServiceLinkedRole",
                "iam:CreateUser",
                "iam:DeleteInstanceProfile",
                "iam:DeleteLoginProfile",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:DeleteRole",
                "iam:DeleteRolePermissionsBoundary",
                "iam:DeleteRolePolicy",
                "iam:DeleteServiceLinkedRole",
                "iam:DeleteUser",
                "iam:DetachRolePolicy",
                "iam:Get*",
                "iam:List*",
                "iam:PassRole",
                "iam:PutRolePolicy",
                "iam:PutUserPolicy",
                "iam:TagInstanceProfile",
                "iam:TagPolicy",
                "iam:TagRole",
                "iam:Untag*",
                "iam:Update*",

                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:DeleteBucketPolicy",
                "s3:DeleteBucketWebsite",
                "s3:DeleteObject",
                "s3:DeleteObjectTagging",
                "s3:DeleteObjectVersion",
                "s3:DeleteObjectVersionTagging",
                "s3:Describe*",
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
                "s3:Tag*",
                "s3:Untag*",

                "logs:CreateDelivery",
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:Delete*",
                "logs:Describe*",
                "logs:Get*",
                "logs:List*",
                "logs:Tag*",
                "logs:Untag*",
                "logs:Put*",

                "route53:ChangeTagsForResource",
                "route53:CreateHostedZone",
                "route53:Get*",
                "route53:list*",
                "route53:UpdateHosted*",
                "route53:ChangeTagsForResource",

                "ssm:AddTagsToResource",
                "ssm:Delete*",
                "ssm:Describe*",
                "ssm:Get*",
                "ssm:List*",
                "ssm:PutParameter",
                "ssm:Tag*",
                "ssm:Untag*",

                "autoscaling:AttachInstances",
                "autoscaling:AttachLoadBalancers",
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:CreateLaunchConfiguration",
                "autoscaling:CreateOrUpdateTags",
                "autoscaling:DeleteAutoScalingGroup",
                "autoscaling:DeleteLaunchConfiguration",
                "autoscaling:DeletePolicy",
                "autoscaling:DeleteTags",
                "autoscaling:Describe*",
                "autoscaling:DetachInstances",
                "autoscaling:DetachLoadBalancerTargetGroups",
                "autoscaling:DetachLoadBalancers",
                "autoscaling:LaunchInstances",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:SetInstanceHealth",
                "autoscaling:UpdateAutoScalingGroup",

                "ec2:AcceptVpcEndpointConnections",
                "ec2:AllocateAddress",
                "ec2:Associate*",
                "ec2:Attach*",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateClientVpnRoute",
                "ec2:CreateInternetGateway",
                "ec2:CreateLaunchTemplate",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:CreateNatGateway",
                "ec2:CreateNetworkAcl",
                "ec2:CreateNetworkInterface",
                "ec2:CreatePlacementGroup",
                "ec2:CreateRoute",
                "ec2:CreateRouteTable",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSubnet",
                "ec2:CreateTags",
                "ec2:CreateVpc",
                "ec2:DeleteLaunchTemplate",
                "ec2:DeleteLaunchTemplateVersions",
                "ec2:DeleteNatGateway",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteRoute",
                "ec2:DeleteRouteTable",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSubnet",
                "ec2:DeleteTags",
                "ec2:DeleteVpc",
                "ec2:Describe*",
                "ec2:Get*",
                "ec2:List*",
                "ec2:Detach*",
                "ec2:Disassociate*",
                "ec2:ModifySecurityGroupRules",
                "ec2:PutResourcePolicy",
                "ec2:ReleaseAddress",
                "ec2:ReplaceRoute",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RunInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances",

                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteRule",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:Get*",
                "elasticloadbalancing:Modify*",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
              ],
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
              Effect   = "Allow"
              Resource = "*"
              Action = [
                "acm:Add*",
                "acm:Delete*",
                "acm:Describe*",
                "acm:Get*",
                "acm:List*",
                "acm:RemoveTagsFrom*",
                "acm:Renew*",
                "acm:Request*",
                "acm:Revoke*",

                "codebuild:BatchGet*",
                "codebuild:CreateProject",
                "codebuild:Delete*",
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*",
                "codebuild:StartBuild",
                "codebuild:StopBuild",
                "codebuild:UpdateProject",

                "codeconnections:CreateConnection",
                "codeconnections:Delete*",
                "codeconnections:Get*",
                "codeconnections:List*",
                "codeconnections:PassConnection",
                "codeconnections:UseConnection",

                "cloudformation:Describe*",
                "cloudformation:Get*",
                "cloudformation:List*",
                "cloudformation:Tag*",
                "cloudformation:Untag*",

                "codepipeline:CreatePipeline",
                "codepipeline:Delete*",
                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:Put*",
                "codepipeline:StartPipelineExecution",
                "codepipeline:StopPipelineExecution",
                "codepipeline:Tag*",
                "codepipeline:Untag*",
                "codepipeline:Update*",

                "codestar:CreateProject",
                "codestar:Delete*",
                "codestar:Describe*",
                "codestar:List*",
                "codestar:Tag*",
                "codestar:Untag*",
                "codestar:Update*",

                "codestar-connections:CreateConnection",
                "codestar-connections:DeleteConnection",
                "codestar-connections:Get*",
                "codestar-connections:List*",
                "codestar-connections:PassConnection",
                "codestar-connections:Tag*",
                "codestar-connections:Untag*",
                "codestar-connections:UseConnection",

                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGet*",
                "ecr:BatchImportUpstreamImage",
                "ecr:CompleteLayerUpload",
                "ecr:CreateRepository",
                "ecr:Delete*",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:InitiateLayerUpload",
                "ecr:List*",
                "ecr:Put*",
                "ecr:Replicate*",
                "ecr:Set*",
                "ecr:Tag*",
                "ecr:Untag*",
                "ecr:Upload*",

                "ecs:CreateCapacityProvider",
                "ecs:CreateCluster",
                "ecs:CreateService",
                "ecs:CreateTaskSet",
                "ecs:DeleteCapacityProvider",
                "ecs:DeleteCluster",
                "ecs:DeleteService",
                "ecs:DeleteTaskDefinitions",
                "ecs:DeleteTaskSet",
                "ecs:DeregisterContainerInstance",
                "ecs:DeregisterTaskDefinition",
                "ecs:Describe*",
                "ecs:List*",
                "ecs:PutClusterCapacityProviders",
                "ecs:Register*",
                "ecs:RunTask",
                "ecs:StartTask",
                "ecs:StopTask",
                "ecs:Tag*",
                "ecs:Untag*",
                "ecs:Update*",

                "cloudfront:AssociateAlias",
                "cloudfront:Create*",
                "cloudfront:DeleteDistribution",
                "cloudfront:Describe*",
                "cloudfront:Get*",
                "cloudfront:List*",
                "cloudfront:Tag*",
                "cloudfront:Untag*",
                "cloudfront:UpdateDistribution",

                "iam:AddRoleToInstanceProfile",
                "iam:AttachRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:CreateLoginProfile",
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "iam:CreateRole",
                "iam:CreateServiceLinkedRole",
                "iam:CreateUser",
                "iam:DeleteInstanceProfile",
                "iam:DeleteLoginProfile",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:DeleteRole",
                "iam:DeleteRolePermissionsBoundary",
                "iam:DeleteRolePolicy",
                "iam:DeleteServiceLinkedRole",
                "iam:DeleteUser",
                "iam:DetachRolePolicy",
                "iam:Get*",
                "iam:List*",
                "iam:PassRole",
                "iam:PutRolePolicy",
                "iam:PutUserPolicy",
                "iam:TagInstanceProfile",
                "iam:TagPolicy",
                "iam:TagRole",
                "iam:Untag*",
                "iam:Update*",

                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:DeleteBucketPolicy",
                "s3:DeleteBucketWebsite",
                "s3:DeleteObject",
                "s3:DeleteObjectTagging",
                "s3:DeleteObjectVersion",
                "s3:DeleteObjectVersionTagging",
                "s3:Describe*",
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
                "s3:Tag*",
                "s3:Untag*",

                "logs:CreateDelivery",
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:Delete*",
                "logs:Describe*",
                "logs:Get*",
                "logs:List*",
                "logs:Tag*",
                "logs:Untag*",
                "logs:Put*",

                "route53:CreateHostedZone",
                "route53:ChangeResourceRecordSets",
                "route53:ChangeTagsForResource",
                "route53:Get*",
                "route53:list*",
                "route53:UpdateHosted*",

                "ssm:AddTagsToResource",
                "ssm:Delete*",
                "ssm:Describe*",
                "ssm:Get*",
                "ssm:List*",
                "ssm:PutParameter",
                "ssm:Tag*",
                "ssm:Untag*",

                "autoscaling:AttachInstances",
                "autoscaling:AttachLoadBalancerTargetGroups",
                "autoscaling:AttachLoadBalancers",
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:CreateLaunchConfiguration",
                "autoscaling:CreateOrUpdateTags",
                "autoscaling:DeleteAutoScalingGroup",
                "autoscaling:DeleteLaunchConfiguration",
                "autoscaling:DeletePolicy",
                "autoscaling:DeleteTags",
                "autoscaling:Describe*",
                "autoscaling:DetachInstances",
                "autoscaling:DetachLoadBalancerTargetGroups",
                "autoscaling:DetachLoadBalancers",
                "autoscaling:LaunchInstances",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:SetInstanceHealth",
                "autoscaling:UpdateAutoScalingGroup",

                "ec2:AcceptVpcEndpointConnections",
                "ec2:AllocateAddress",
                "ec2:Associate*",
                "ec2:Attach*",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateClientVpnRoute",
                "ec2:CreateInternetGateway",
                "ec2:CreateLaunchTemplate",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:CreateNatGateway",
                "ec2:CreateNetworkAcl",
                "ec2:CreateNetworkInterface",
                "ec2:CreatePlacementGroup",
                "ec2:CreateRoute",
                "ec2:CreateRouteTable",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSubnet",
                "ec2:CreateTags",
                "ec2:CreateVpc",
                "ec2:DeleteInternetGateway",
                "ec2:DeleteLaunchTemplate",
                "ec2:DeleteLaunchTemplateVersions",
                "ec2:DeleteNatGateway",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteRoute",
                "ec2:DeleteRouteTable",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSubnet",
                "ec2:DeleteTags",
                "ec2:DeleteVpc",
                "ec2:Describe*",
                "ec2:Get*",
                "ec2:List*",
                "ec2:Detach*",
                "ec2:Disassociate*",
                "ec2:ModifySecurityGroupRules",
                "ec2:ModifyVpcAttribute",
                "ec2:PutResourcePolicy",
                "ec2:ReleaseAddress",
                "ec2:ReplaceRoute",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RunInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances",

                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteRule",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:Get*",
                "elasticloadbalancing:Modify*",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
              ],
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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Allow"
              Resource = "*"
              Action = [
                "codebuild:BatchGet*",
                "codebuild:Describe*",
                "codebuild:Get*",
                "codebuild:ImportSourceCredentials",
                "codebuild:List*",
                "codebuild:StartBuild",
                "codebuild:StopBuild",

                "codeconnections:Get*",
                "codeconnections:List*",
                "codeconnections:PassConnection",
                "codeconnections:UseConnection",

                "cloudformation:Describe*",
                "cloudformation:Get*",
                "cloudformation:List*",

                "codepipeline:Get*",
                "codepipeline:List*",
                "codepipeline:Put*",
                "codepipeline:StartPipelineExecution",
                "codepipeline:StopPipelineExecution",

                "codestar:Describe*",
                "codestar:List*",

                "codestar-connections:Get*",
                "codestar-connections:List*",
                "codestar-connections:PassConnection",
                "codestar-connections:UseConnection",

                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGet*",
                "ecr:BatchImportUpstreamImage",
                "ecr:CompleteLayerUpload",
                "ecr:CreateRepository",
                "ecr:Delete*",
                "ecr:Describe*",
                "ecr:Get*",
                "ecr:InitiateLayerUpload",
                "ecr:List*",
                "ecr:Put*",
                "ecr:Replicate*",
                "ecr:Set*",
                "ecr:Tag*",
                "ecr:Untag*",
                "ecr:Upload*",

                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:DeleteBucketPolicy",
                "s3:DeleteBucketWebsite",
                "s3:DeleteObject",
                "s3:DeleteObjectTagging",
                "s3:DeleteObjectVersion",
                "s3:DeleteObjectVersionTagging",
                "s3:Describe*",
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
                "s3:Tag*",
                "s3:Untag*",

                "logs:CreateDelivery",
                "logs:CreateLogDelivery",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:Delete*",
                "logs:Describe*",
                "logs:Get*",
                "logs:List*",
                "logs:Tag*",
                "logs:Untag*",
                "logs:Put*",
              ],
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
              Effect   = "Deny",
              Resource = "*",
              Action   = "*",
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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Deny",
              Resource = "*",
              Action   = "*",
            },
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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Deny",
              Resource = "*",
              Action   = "*",
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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Deny",
              Resource = "*",
              Action   = "*",
            },
          ]
        })
      },
      {
        name = "${local.name}-run-unit-test"

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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Deny",
              Resource = "*",
              Action   = "*",
            },
          ]
        })
      },
      {
        name = "${local.name}-run-int-test"

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
          ]
        })

        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
            {
              Effect   = "Deny",
              Resource = "*",
              Action   = "*",
            },
          ]
        })
      },
    ]
  }
}
