variable "name" {
  description = "The name for the devops module"
  type        = string
  nullable    = false
}

variable "account_id" {
  description = "The AWS account ID this module is provisioned under"
  type        = string
  nullable    = false
}

variable "region" {
  description = "The AWS region this module is provisioned in"
  type        = string
  nullable    = false
}

variable "repositories" {
  description = "A list of CI/CD project repository configurations"
  default     = []

  type = list(object({
    name = string

    git_provider = string // Bitbucket, GitHub
    git_repo     = string

    is_container = bool
    dockerfile   = string

    pipelines = list(object({
      type        = string
      branch_name = string
    }))

    stages = object({
      test = object({
        unit = bool
        int  = bool
      })

      deploy = object({
        test = bool
        qa   = bool
        prod = bool
      })
    })

    jobs = list(object({
      # Must be one of: dev, release
      branch_name = string

      # VPC where the CI job runs
      vpc_id                 = string
      vpc_subnets            = list(string)
      vpc_security_group_ids = list(string)

      image           = string
      timeout         = number
      working_dir     = string
      ssm_param_paths = string
      test_commands   = list(string)
      target_runtime  = string # e.g. node, go

      # Must be one of: local, test, qa, prod
      environment_name = string

      # Must be one of: build, deploy
      action = string

      # If projects.jobs.action = build, must be one of: cloud, container, web
      # If projects.jobs.action = deploy, must be one of: cloud, container-app, container-db, web
      action_item = string

      upload_release_artifact_zip = bool

      # The following fields are required:
      # If projects.jobs.action = deploy and projects.jobs.action_item = container-app
      task_family                  = string
      task_role                    = string
      container_port               = string
      container_cpu                = string
      container_memory_reservation = string
      cluster_name                 = string
      service_name                 = string
      log_group_name               = string
      log_stream_prefix            = string

      # If projects.jobs.action = deploy and projects.jobs.action_item = web
      s3_host_bucket_name = string
      cdn_id              = string
    }))
  }))
}
