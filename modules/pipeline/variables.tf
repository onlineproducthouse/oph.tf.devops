variable "name" {
  description = "The name given to the pipeline"
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
    name        = string
    vpc_id      = string
    vpc_subnets = list(string)
    role_arn    = string
    timeout     = number

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

  type = list(object({
    name        = string
    branch_name = string
  }))

  default = [
    {
      name        = "dev"
      branch_name = "dev"
    },
    {
      name        = "release"
      branch_name = "release/*"
    },
  ]
}

variable "stages" {
  description = "Stages to configure for the pipeline, in addition to source and build stages"

  type = object({
    test = object({
      unit = bool
      int  = bool
    })

    deploy = object({
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
      qa   = false
      prod = false
    }
  }
}
