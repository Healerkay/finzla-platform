# Platform stack remote state (created by terraform/bootstrap).
# Init with:
#   terraform -chdir=terraform init -backend-config=backend.dev.hcl
# or:
#   terraform -chdir=terraform init -backend-config=backend.prod.hcl

bucket         = "finzla-terraform-state-840432317209"
key            = "platform/dev/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "finzla-terraform-locks"
encrypt        = true
kms_key_id     = "arn:aws:kms:eu-west-1:840432317209:key/1db954ec-0cd8-4344-a9c5-03e01f305af7"
