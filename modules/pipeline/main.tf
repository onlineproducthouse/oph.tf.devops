resource "aws_codepipeline" "pipeline" {
  for_each = {
    for i, v in local.pipelines : v.name => v
  }

  name     = "${var.name}-${each.value.name}"
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
      output_artifacts = ["source-${var.name}-${each.value.name}"]

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
      input_artifacts  = ["source-${var.name}-${each.value.name}"]
      output_artifacts = ["build-${var.name}-${each.value.name}"]
      version          = "1"

      configuration = {
        ProjectName = module.job[each.value.name].name
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
        input_artifacts = ["build-${var.name}-${each.value.name}"]
        version         = "1"

        configuration = {
          ProjectName = module.job[each.value.name].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.value.name == "release" && var.stages.test.int ? local.approval : {}

    content {
      name = "deploy_test"

      action {
        name            = "deploy_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.value.name}"]
        version         = "1"

        configuration = {
          ProjectName = module.job[each.value.name].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.value.name == "release" && var.stages.test.int ? local.approval : {}

    content {
      name = "int_test"

      action {
        name            = "int_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.value.name}"]
        version         = "1"

        configuration = {
          ProjectName = module.job[each.value.name].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.value.name == "release" && var.stages.deploy.qa ? local.approval : {}

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
    for_each = each.value.name == "release" && var.stages.deploy.qa ? local.approval : {}

    content {
      name = "deploy_qa"

      action {
        name            = "deploy_qa"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.value.name}"]
        version         = "1"

        configuration = {
          ProjectName = module.job[each.value.name].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.value.name == "release" && var.stages.deploy.prod ? local.approval : {}

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
    for_each = each.value.name == "release" && var.stages.deploy.prod ? local.approval : {}

    content {
      name = "deploy_prod"

      action {
        name            = "deploy_prod"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build-${var.name}-${each.value.name}"]
        version         = "1"

        configuration = {
          ProjectName = module.job[each.value.name].name
        }
      }
    }
  }
}

module "job" {
  source = "./job"

  for_each = {
    for i, v in local.pipelines : v.name => v
  }

  name         = "${var.job.name}-${each.value.name}"
  vpc_id       = var.job.vpc_id
  vpc_subnets  = var.job.vpc_subnets
  role_arn     = var.job.role_arn
  timeout      = var.job.timeout
  buildspec    = var.job.buildspec
  is_container = var.job.is_container

  env_variables = concat(var.job.env_variables, [
    { key = "RELEASE_MANIFEST", value = "release_manifest.sh" },
    { key = "GIT_BRANCH", value = each.value.branch_name },
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

  pipelines = [
    {
      name         = "dev"
      branch_name  = "dev"
      environments = ["local"]
    },
    {
      name         = "release"
      branch_name  = "release/*"
      environments = ["test", "qa", "prod"]
    },
  ]
}
