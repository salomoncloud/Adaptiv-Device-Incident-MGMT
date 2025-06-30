output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "website_url" {
  description = "Website URL with custom domain"
  value       = module.cloudfront.website_url
}

output "s3_website_url" {
  description = "S3 website URL (fallback)"
  value       = module.s3_frontend.website_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = module.cloudfront.cloudfront_domain_name
}

output "route53_zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = module.cloudfront.route53_zone_id
}

output "route53_name_servers" {
  description = "Route 53 Name Servers - Update your domain registrar with these"
  value       = module.cloudfront.route53_name_servers
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito Client ID"
  value       = module.cognito.user_pool_client_id
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = var.frontend_bucket_name
}

output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = module.cloudfront.acm_certificate_arn
}
