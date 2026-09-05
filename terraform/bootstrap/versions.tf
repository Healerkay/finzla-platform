terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  # This stack's own state stays local on purpose. It creates the S3 bucket
  # and DynamoDB table that the platform stack will use as its backend.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "finzla"
      Environment = "bootstrap"
      ManagedBy   = "terraform"
    }
  }
}
