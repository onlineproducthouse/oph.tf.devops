module "ecr" {
  source = "../docker/ecr"
  count  = var.is_container ? 1 : 0
  name   = var.git_repo
}

resource "aws_codepipeline" "pipeline" {
  for_each = {
    for i, v in var.pipeline : v.name => v
  }

  name     = "${var.name}-${each.key}"
  role_arn = var.role_arn

  artifact_store {
    location = var.artifact_store_bucket_id
    type     = "S3"
  }

  stage {
    name = "source"

    action {
      name             = "source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source-${var.name}-${each.key}"]

      configuration = {
        ConnectionArn    = var.githook_arn
        FullRepositoryId = var.git_repo
        BranchName       = each.value.branch_name
      }
    }
  }

  stage {
    name = "build"

    action {
      name             = "build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source-${var.name}-${each.key}"]
      output_artifacts = ["build-${var.name}-${each.key}"]
      version          = "1"

      configuration = {
        ProjectName = module.job["${each.key}-local"].name
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages.test.unit ? local.approval : {}

    content {
      name = "unit_test"

      action {
        name            = "unit_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.key}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${each.key}-local"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "release" && var.stages.test.int ? local.approval : {}

    content {
      name = "deploy_test"

      action {
        name            = "deploy_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.key}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["release-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "release" && var.stages.test.int ? local.approval : {}

    content {
      name = "int_test"

      action {
        name            = "int_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.key}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["release-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "release" && var.stages.deploy.qa ? local.approval : {}

    content {
      name = "approve_deploy_qa"

      action {
        name     = "approve_deploy_qa"
        category = stage.value.category
        owner    = stage.value.owner
        provider = stage.value.provider
        version  = stage.value.version
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "release" && var.stages.deploy.qa ? local.approval : {}

    content {
      name = "deploy_qa"

      action {
        name            = "deploy_qa"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.key}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["release-qa"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "release" && var.stages.deploy.prod ? local.approval : {}

    content {
      name = "approve_deploy_prod"

      action {
        name     = "approve_deploy_prod"
        category = stage.value.category
        owner    = stage.value.owner
        provider = stage.value.provider
        version  = stage.value.version
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "release" && var.stages.deploy.prod ? local.approval : {}

    content {
      name = "deploy_prod"

      action {
        name            = "deploy_prod"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.key}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["release-prod"].name
        }
      }
    }
  }
}

module "job" {
  source = "./job"

  for_each = {
    for v in var.job : v.name => v
  }

  name         = each.key
  vpc_id       = each.value.vpc_id
  vpc_subnets  = each.value.vpc_subnets
  role_arn     = each.value.role_arn
  timeout      = each.value.timeout
  buildspec    = each.value.buildspec
  is_container = var.is_container

  env_variables = concat(each.value.env_variables, [
    { key = "IMAGE_REPOSITORY_NAME", value = var.is_container ? module.ecr[0].name : "" },
  ])
}

locals {
  approval = {
    step = {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }
}
