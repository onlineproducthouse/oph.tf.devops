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

variable "git_repo" {
  description = "The name of the git repository for the pipeline"
  type        = string
  nullable    = false
}

variable "githook_arn" {
  description = "AWS CodeStart Source Connection ARN"
  type        = string
  nullable    = false
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

variable "job" {
  description = "Codebuild job to create for the pipeline"
  nullable    = false

  type = object({
    vpc_id       = string
    vpc_subnets  = list(string)
    role_arn     = string
    timeout      = number
    buildspec    = string
    is_container = bool

    env_variables = list(object({
      key   = string
      value = string
    }))
  })
}
