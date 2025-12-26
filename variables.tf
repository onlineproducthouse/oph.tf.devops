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

variable "githook_provider" {
  description = "The name of the git repository provider where the hook will be setup"
  type        = string
  default     = "Bitbucket"
}

variable "projects" {
  description = "A list of CI/CD project configurations"
  default     = []

  type = list(object({
    name         = string
    git_repo     = string
    is_container = bool
    dockerfile   = string

    # VPC where the CI job runs
    vpc_id      = string
    vpc_subnets = list(string)

    pipelines = list(object({
      name        = string
      branch_name = string
    }))

    stages = object({
      test = object({
        unit = bool
        int  = bool
      })

      deploy = object({
        qa   = bool
        prod = bool
      })
    })

    jobs = list(object({
      # Must be one of: dev, release
      branch_name = string

      timeout         = number
      working_dir     = string
      ssm_param_paths = string

      # Must be one of: local, test, qa, prod
      environment_name = string

      # Must be one of: build, deploy
      action = string

      # If projects.jobs.action = build, must be one of: cloud, container, web
      # If projects.jobs.action = deploy, must be one of: cloud, container-app, container-db, web
      action_item = string

      # The following fields are required:
      # If projects.jobs.action = deploy and projects.jobs.action_item = container-app
      task_family                  = string
      task_role                    = string
      container_port               = string
      container_cpu                = string
      container_memory_reservation = string
      cluster_name                 = string
      service_name                 = string
    }))
  }))
}
