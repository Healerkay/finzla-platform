output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  value = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  value = aws_dynamodb_table.locks.name
}

output "state_kms_key_arn" {
  value = aws_kms_key.state.arn
}

output "aws_region" {
  value = var.aws_region
}
