variable "name" {
  description = "The name for the docker module"
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

variable "copy_docker_repositories" {
  description = "A list of docker repositories to copy into AWS ECR"
  default     = []

  type = list(object({
    key  = string
    name = string
  }))
}

variable "copy_docker_images" {
  description = "A list of docker images to copy into AWS ECR"
  default     = []

  type = list(object({
    key        = string
    repository = string
    tag        = string
  }))
}
