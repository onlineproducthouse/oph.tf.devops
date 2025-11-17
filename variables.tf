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

variable "config" {
  description = "List of configuration variables to add to AWS SSM Parameter Store"
  default     = []

  type = list(object({
    id             = string
    ssm_param_path = string
    key            = string
    value          = string
  }))
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

    jobs = list(object({
      branch_name     = string
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
  }))
}
