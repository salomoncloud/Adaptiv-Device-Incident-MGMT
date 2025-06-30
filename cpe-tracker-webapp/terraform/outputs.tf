output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "website_url" {
  description = "S3 website URL"
  value       = module.s3_frontend.website_url
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
