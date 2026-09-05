# Copy to backend.dev.hcl / backend.prod.hcl or pass with:
#   terraform init -backend-config=backend.dev.hcl
#
# Remote state without AdministratorAccess:
# 1. A dedicated state bucket (S3) with versioning, SSE-KMS, and a bucket
#    policy that allows only the Terraform deploy role and a small ops group.
# 2. A DynamoDB table used solely for state locking (Pay-per-request).
# 3. IAM on the CI/deploy role: s3:GetObject/PutObject/ListBucket on that
#    prefix, dynamodb:GetItem/PutItem/DeleteItem on the lock table — not
#    account-wide S3/DynamoDB.
#
# Distinct state keys (or buckets) for dev vs prod prevent concurrent
# applies from trampling each other across environments.
#
# These values match the bootstrap stack in account 840432317209:

bucket         = "finzla-terraform-state-840432317209"
key            = "platform/dev/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "finzla-terraform-locks"
encrypt        = true
kms_key_id     = "arn:aws:kms:eu-west-1:840432317209:key/1db954ec-0cd8-4344-a9c5-03e01f305af7"
