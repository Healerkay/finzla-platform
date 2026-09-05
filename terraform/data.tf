data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_kms_alias" "tf_state" {
  name = "alias/finzla-terraform-state"
}
