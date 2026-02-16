variable "name" {
  description = "The name given to the pipeline"
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

variable "role_arn" {
  description = "The IAM Role ARN the pipeline should run with"
  type        = string
  nullable    = false
}

variable "artifact_store_bucket_id" {
  description = "The AWS S3 Bucket ID to store artifacts in"
  type        = string
  nullable    = false
}

variable "git_provider" {
  description = "The name of the git repository provider where the hook will be setup"
  type        = string
  default     = "Bitbucket"
}

variable "git_repo" {
  description = "The name of the git repository for the pipeline"
  type        = string
  nullable    = false
}

variable "is_container" {
  description = "Is the project deployed as a docker container?"
  type        = bool
  default     = false
}

variable "job" {
  description = "Codebuild job to create for the pipeline"
  default     = []

  type = list(object({
    name                   = string
    branch_name            = string
    image                  = string
    vpc_id                 = string
    vpc_subnets            = list(string)
    vpc_security_group_ids = list(string)
    role_arn               = string
    timeout                = number
    test_commands          = list(string)

    # AWS S3 Bucket ARN key to buildspec object
    buildspec = string

    env_variables = list(object({
      key   = string
      value = string
    }))
  }))
}

variable "pipeline" {
  description = "List of pipelines to create"
  default     = []

  type = list(object({
    type        = string // complete, build, release
    branch_name = string
  }))
}

variable "stages" {
  description = "Stages to configure for the pipeline, in addition to source and build stages"

  type = object({
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

  default = {
    test = {
      unit = false
      int  = false
    }

    deploy = {
      test = false
      qa   = false
      prod = false
    }
  }
}
