output "infra_bucket_id" {
  description = "ID of the infra S3 bucket. Used to configure log destinations and artifact storage."
  value       = aws_s3_bucket.infra.id
}

output "infra_bucket_arn" {
  description = "ARN of the infra S3 bucket. Required for IAM policies that grant access to this bucket."
  value       = aws_s3_bucket.infra.arn
}
