resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name

  tags = {
    Environment = "prod"
    Service     = "cpe-tracker"
  }

  force_destroy = true
}

# Remove the bucket policy for now - CloudFront will add it after creation
# The bucket policy will be managed by CloudFront module instead

# Remove public access block since we're using CloudFront OAC
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Keep website configuration for fallback, but CloudFront will be primary access
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Upload frontend files
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${path.root}/../frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.root}/../frontend/index.html")
}

resource "aws_s3_object" "style_css" {
  bucket = aws_s3_bucket.frontend.id
  key          = "style.css"
  source       = "${path.root}/../frontend/style.css"
  content_type = "text/css"
  etag         = filemd5("${path.root}/../frontend/style.css")
}

# Upload app.js with API endpoint replacement
resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "app.js"
  content      = replace(file("${path.root}/../frontend/app.js"), "API_ENDPOINT_PLACEHOLDER", var.api_endpoint)
  content_type = "application/javascript"
  etag         = md5(replace(file("${path.root}/../frontend/app.js"), "API_ENDPOINT_PLACEHOLDER", var.api_endpoint))
}
