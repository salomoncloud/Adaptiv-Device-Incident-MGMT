output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "route53_zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Route 53 Name Servers"
  value       = aws_route53_zone.main.name_servers
}

output "website_url" {
  description = "Website URL with custom domain"
  value       = "https://${var.domain_name}"
}

output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.cloudfront_cert.arn
}
