# Same bucket and lock table as dev; different state key so environments
# cannot overwrite each other.

bucket         = "finzla-terraform-state-840432317209"
key            = "platform/prod/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "finzla-terraform-locks"
encrypt        = true
kms_key_id     = "arn:aws:kms:eu-west-1:840432317209:key/1db954ec-0cd8-4344-a9c5-03e01f305af7"
