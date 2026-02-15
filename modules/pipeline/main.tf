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

resource "aws_codepipeline" "complete" {
  for_each = {
    for v in var.pipeline : v.branch_name => {
      type            = v.type
      source_branches = distinct(concat([v.branch_name], v.additional_branches))
    } if v.type == "complete"
  }

  name     = "${var.name}-${each.key}"
  role_arn = var.role_arn

  artifact_store {
    location = var.artifact_store_bucket_id
    type     = "S3"
  }

  dynamic "stage" {
    for_each = { for v in each.value.source_branches : v => null }

    content {
      name = "source-${each.key}"

      action {
        name             = "source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["${stage.key}-${random_uuid.artifact_keys["source"].result}"]

        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.githook.arn
          FullRepositoryId = var.git_repo
          BranchName       = stage.key
        }
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
      input_artifacts  = [for branch in each.value.source_branches : "${branch}-${random_uuid.artifact_keys["source"].result}"]
      output_artifacts = ["${each.key}-${random_uuid.artifact_keys["build"].result}"]
      version          = "1"

      configuration = {
        ProjectName = module.job["${var.name}-${each.key}-local"].name
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
        input_artifacts = [for branch in each.value.source_branches : "${branch}-${random_uuid.artifact_keys["source"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-unit-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "main" && var.stages.deploy.test ? local.approval : {}

    content {
      name = "approve_deploy_test"

      action {
        name     = "approve_deploy_test"
        category = stage.value.category
        owner    = stage.value.owner
        provider = stage.value.provider
        version  = stage.value.version
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "main" && var.stages.deploy.test ? local.approval : {}

    content {
      name = "deploy_test"

      action {
        name            = "deploy_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["${each.key}-${random_uuid.artifact_keys["build"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "main" && var.stages.test.int ? local.approval : {}

    content {
      name = "approve_int_test"

      action {
        name     = "approve_int_test"
        category = stage.value.category
        owner    = stage.value.owner
        provider = stage.value.provider
        version  = stage.value.version
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "main" && var.stages.test.int ? local.approval : {}

    content {
      name = "int_test"

      action {
        name            = "int_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["${each.key}-${random_uuid.artifact_keys["source"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-int-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "main" && var.stages.deploy.qa ? local.approval : {}

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
    for_each = each.key == "main" && var.stages.deploy.qa ? local.approval : {}

    content {
      name = "deploy_qa"

      action {
        name            = "deploy_qa"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["${each.key}-${random_uuid.artifact_keys["build"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-qa"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.key == "main" && var.stages.deploy.prod ? local.approval : {}

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
    for_each = each.key == "main" && var.stages.deploy.prod ? local.approval : {}

    content {
      name = "deploy_prod"

      action {
        name            = "deploy_prod"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["${each.key}-${random_uuid.artifact_keys["build"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-prod"].name
        }
      }
    }
  }
}

resource "aws_codepipeline" "build" {
  for_each = {
    for v in var.pipeline : v.branch_name => {
      type            = v.type
      source_branches = distinct(concat([v.branch_name], v.additional_branches))
    } if v.type == "build"
  }

  name     = "${var.name}-${each.key}-${each.value.type}"
  role_arn = var.role_arn

  artifact_store {
    location = var.artifact_store_bucket_id
    type     = "S3"
  }

  dynamic "stage" {
    for_each = { for v in each.value.source_branches : v => null }

    content {
      name = "source-${each.key}"

      action {
        name             = "source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["${stage.key}-${random_uuid.artifact_keys["source"].result}"]

        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.githook.arn
          FullRepositoryId = var.git_repo
          BranchName       = stage.key
        }
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
      input_artifacts  = [for branch in each.value.source_branches : "${branch}-${random_uuid.artifact_keys["source"].result}"]
      output_artifacts = ["${each.key}-${random_uuid.artifact_keys["build"].result}"]
      version          = "1"

      configuration = {
        ProjectName = module.job["${var.name}-${each.key}-local"].name
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
        input_artifacts = [for branch in each.value.source_branches : "${branch}-${random_uuid.artifact_keys["source"].result}"]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-unit-test"].name
        }
      }
    }
  }
}

resource "aws_codepipeline" "release" {
  for_each = {
    for v in var.pipeline : v.branch_name => {
      type = v.type
    } if v.type == "release" && v.branch_name == "main"
  }

  name     = "${var.name}-${each.key}-${each.value.type}"
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
      provider         = "S3"
      version          = "1"
      output_artifacts = [random_uuid.artifact_keys["release"].result]

      configuration = {
        S3Bucket    = var.artifact_store_bucket_id
        S3ObjectKey = "${each.key}-${random_uuid.artifact_keys["build"].result}.zip"
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages.deploy.test ? local.approval : {}

    content {
      name = "approve_deploy_test"

      action {
        name     = "approve_deploy_test"
        category = stage.value.category
        owner    = stage.value.owner
        provider = stage.value.provider
        version  = stage.value.version
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages.deploy.test ? local.approval : {}

    content {
      name = "deploy_test"

      action {
        name            = "deploy_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = [random_uuid.artifact_keys["release"].result]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages.test.int ? local.approval : {}

    content {
      name = "approve_int_test"

      action {
        name     = "approve_int_test"
        category = stage.value.category
        owner    = stage.value.owner
        provider = stage.value.provider
        version  = stage.value.version
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages.test.int ? local.approval : {}

    content {
      name = "int_test"

      action {
        name            = "int_test"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = [random_uuid.artifact_keys["release"].result]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-int-test"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages.deploy.qa ? local.approval : {}

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
    for_each = var.stages.deploy.qa ? local.approval : {}

    content {
      name = "deploy_qa"

      action {
        name            = "deploy_qa"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = [random_uuid.artifact_keys["release"].result]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-qa"].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages.deploy.prod ? local.approval : {}

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
    for_each = var.stages.deploy.prod ? local.approval : {}

    content {
      name = "deploy_prod"

      action {
        name            = "deploy_prod"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = [random_uuid.artifact_keys["release"].result]
        version         = "1"

        configuration = {
          ProjectName = module.job["${var.name}-${each.key}-prod"].name
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
