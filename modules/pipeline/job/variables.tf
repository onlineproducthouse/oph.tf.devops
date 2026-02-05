variable "name" {
  description = "The name given to the codebuild job"
  type        = string
  nullable    = false
}

variable "image" {
  description = "The name codebuild job image"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "vpc_id" {
  description = "VPC where the CI job runs"
  type        = string
  default     = ""
}

variable "vpc_subnets" {
  description = "VPC Subnets where the CI job runs"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security Group IDs for VPC Subnets where the CI job runs"
  type        = list(string)
  default     = []
}

variable "role_arn" {
  description = "The IAM Role ARN the job should run with"
  type        = string
}

variable "timeout" {
  description = "The jobs run timeout"
  type        = number
  default     = 5
}

variable "buildspec" {
  description = "AWS S3 Bucket ARN key to buildspec object"
  type        = string
  nullable    = false
}

variable "is_container" {
  description = "Flag whether or not this must run with docker enabled"
  type        = bool
  default     = false
}

variable "env_variables" {
  description = "A list of environment variables to set in the job instance"
  default     = []

  type = list(object({
    key   = string
    value = string
  }))
}
