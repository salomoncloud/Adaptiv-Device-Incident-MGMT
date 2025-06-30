variable "domain_name" {
  type        = string
  description = "Domain name for the website"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "s3_bucket_domain_name" {
  type        = string
  description = "S3 bucket domain name"
}
