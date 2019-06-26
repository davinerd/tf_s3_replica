output "s3_policy_arn" {
  value = aws_iam_policy.s3_policy.arn
}

output "s3_bucket" {
  value = local.s3_bucket_id
}

output "s3_bucket_arn" {
  value = local.s3_bucket_arn
}

