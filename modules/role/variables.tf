variable "name" {
  description = "The name for the devops module"
  type        = string
  nullable    = false
}

variable "region" {
  description = "The name for the AWS region"
  type        = string
  nullable    = false
}

variable "account_id" {
  description = "The 12 digit AWS account id"
  type        = string
  nullable    = false
}

variable "assume_role_policy" {
  description = "JSON encoded IAM assume role policy"
  type        = string
  nullable    = false
}

variable "policy" {
  description = "JSON encoded IAM policy"
  type        = string
  nullable    = false
}
