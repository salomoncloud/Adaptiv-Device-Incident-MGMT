output "website_url" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "bucket_domain_name" {
  description = "S3 bucket domain name for CloudFront origin"
  value       = aws_s3_bucket.frontend.bucket_domain_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}
