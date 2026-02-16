resource "aws_codebuild_project" "job" {
  name           = var.name
  service_role   = var.role_arn
  build_timeout  = var.timeout
  queued_timeout = var.timeout

  artifacts {
    type     = "CODEPIPELINE"
    location = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec
  }

  environment {
    image                       = var.image
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    privileged_mode = var.is_container

    dynamic "environment_variable" {
      for_each = var.env_variables

      content {
        name  = environment_variable.value.key
        value = environment_variable.value.value
      }
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id == "" ? [] : [{
      vpc_id             = var.vpc_id
      subnets            = var.vpc_subnets
      security_group_ids = var.vpc_security_group_ids
    }]

    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }
}
