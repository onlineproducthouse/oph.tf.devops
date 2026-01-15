variable "name" {
  description = "The name for the ECR repository to create"
  type        = string
  nullable    = false
}

variable "account_id" {
  description = "The AWS account ID this module is provisioned under"
  type        = string
  nullable    = false
}

variable "force_delete" {
  description = "(Optional) If true, will delete the repository even if it contains images. Defaults to true"
  type        = string
  default     = true
}
