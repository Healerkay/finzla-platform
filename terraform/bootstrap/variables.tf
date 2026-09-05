variable "aws_region" {
  description = "Region for the state bucket and lock table. Must match the platform stack."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  type    = string
  default = "finzla"
}
