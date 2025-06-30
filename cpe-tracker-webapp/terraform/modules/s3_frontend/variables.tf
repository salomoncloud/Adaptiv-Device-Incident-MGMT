variable "bucket_name" {
  type = string
}

variable "api_endpoint" {
  type        = string
  description = "API Gateway endpoint URL"
}

variable "cloudfront_distribution_arn" {
  type        = string
  description = "CloudFront distribution ARN for OAC policy"
  default     = ""
}
