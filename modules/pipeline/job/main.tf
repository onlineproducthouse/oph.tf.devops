resource "aws_security_group" "job" {
  count = var.vpc_id == "" ? 0 : 1

  name   = "${var.name}-job"
  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_security_group_rule" "job" {
  count = var.vpc_id == "" ? 0 : 1

  security_group_id = aws_security_group.job[0].id

  type        = "egress"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 0
  to_port     = 0
}

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
    compute_type                = "BUILD_GENERAL1_SMALL"
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
      security_group_ids = [aws_security_group.job[0].id]
    }]

    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }
}
