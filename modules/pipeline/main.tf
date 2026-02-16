module "ecr" {
  source     = "../docker/ecr"
  count      = var.is_container ? 1 : 0
  name       = var.git_repo
  account_id = var.account_id
}

resource "aws_codestarconnections_connection" "githook" {
  name          = "${var.name}-${var.git_provider}"
  provider_type = var.git_provider
}

resource "random_uuid" "artifact_keys" {
  for_each = { for v in ["source", "build", "release"] : v => null }
}

resource "aws_codepipeline" "pipeline" {
  for_each = {
    for v in var.pipeline : "${v.type}-${v.branch_name}" => {
      type        = v.type
      branch_name = v.branch_name
    }
  }

  name     = each.value.type == "complete" ? "${var.name}-${each.value.branch_name}" : "${var.name}-${each.key}"
  role_arn = var.role_arn

  artifact_store {
    location = var.artifact_store_bucket_id
    type     = "S3"
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && (each.value.type == "build" || each.value.type == "complete")
    }

    content {
      name = "source"

      action {
        name             = "source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["${each.key}-${random_uuid.artifact_keys["source"].result}"]

        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.githook.arn
          FullRepositoryId = var.git_repo
          BranchName       = each.value.branch_name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && each.value.type == "release"
    }

    content {
      name = "source"

      action {
        name             = "source"
        category         = "Source"
        owner            = "AWS"
        provider         = "S3"
        version          = "1"
        output_artifacts = ["${each.key}-${random_uuid.artifact_keys["release"].result}"]

        configuration = {
          S3Bucket    = var.artifact_store_bucket_id
          S3ObjectKey = "${random_uuid.artifact_keys["release"].result}.zip"
        }
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && (each.value.type == "build" || each.value.type == "complete")
    }

    content {
      name = "build"

      action {
        name             = "build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["${each.key}-${random_uuid.artifact_keys["source"].result}"]
        output_artifacts = ["${each.key}-${random_uuid.artifact_keys["build"].result}"]
        version          = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.value.branch_name}-local"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.test.unit && (each.value.type == "build" || each.value.type == "complete")
    }

    content {
      name = "unit_test"

      action {
        name            = "unit_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["${each.key}-${random_uuid.artifact_keys["source"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.value.branch_name}-unit-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.deploy.test && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "approve_deploy_test"

      action {
        name     = "approve_deploy_test"
        category = local.approval.step.category
        owner    = local.approval.step.owner
        provider = local.approval.step.provider
        version  = local.approval.step.version
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.deploy.test && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "deploy_test"

      action {
        name            = "deploy_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = each.value.type == "complete" ? ["${each.key}-${random_uuid.artifact_keys["build"].result}"] : ["${each.key}-${random_uuid.artifact_keys["release"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.value.branch_name}-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.test.int && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "approve_int_test"

      action {
        name     = "approve_int_test"
        category = local.approval.step.category
        owner    = local.approval.step.owner
        provider = local.approval.step.provider
        version  = local.approval.step.version
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.test.int && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "int_test"

      action {
        name            = "int_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = each.value.type == "complete" ? ["${each.key}-${random_uuid.artifact_keys["source"].result}"] : ["${each.key}-${random_uuid.artifact_keys["release"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.value.branch_name}-int-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.deploy.qa && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "approve_deploy_qa"

      action {
        name     = "approve_deploy_qa"
        category = local.approval.step.category
        owner    = local.approval.step.owner
        provider = local.approval.step.provider
        version  = local.approval.step.version
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.deploy.qa && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "deploy_qa"

      action {
        name            = "deploy_qa"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = each.value.type == "complete" ? ["${each.key}-${random_uuid.artifact_keys["build"].result}"] : ["${each.key}-${random_uuid.artifact_keys["release"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.value.branch_name}-qa"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.deploy.prod && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "approve_deploy_prod"

      action {
        name     = "approve_deploy_prod"
        category = local.approval.step.category
        owner    = local.approval.step.owner
        provider = local.approval.step.provider
        version  = local.approval.step.version
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for v in var.pipeline : v.branch_name => null if each.key == "${v.type}-${v.branch_name}" && var.stages.deploy.prod && each.value.branch_name == "main" && (each.value.type == "release" || each.value.type == "complete")
    }

    content {
      name = "deploy_prod"

      action {
        name            = "deploy_prod"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = each.value.type == "complete" ? ["${each.key}-${random_uuid.artifact_keys["build"].result}"] : ["${each.key}-${random_uuid.artifact_keys["release"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.value.branch_name}-prod"].name
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

  name                   = each.key
  image                  = each.value.image
  vpc_id                 = each.value.vpc_id
  vpc_subnets            = each.value.vpc_subnets
  vpc_security_group_ids = each.value.vpc_security_group_ids
  role_arn               = each.value.role_arn
  timeout                = each.value.timeout
  buildspec              = each.value.buildspec
  is_container           = var.is_container

  env_variables = concat(each.value.env_variables, [
    { key = "IMAGE_REPOSITORY_NAME", value = var.is_container ? module.ecr[0].name : "" },
    { key = "RUN_TEST_COMMAND", value = join(" && ", each.value.test_commands) },
    { key = "RELEASE_ARTIFACT_ZIP_NAME", value = "${random_uuid.artifact_keys["release"].result}.zip" },
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
