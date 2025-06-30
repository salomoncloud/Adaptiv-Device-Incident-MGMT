resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name

  tags = {
    Environment = "prod"
    Service     = "cpe-tracker"
  }

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

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
  bucket       = aws_s3_bucket.frontend.id
  key          = "style.css"
  source       = "${path.root}/../frontend/style.css"
  content_type = "text/css"
  etag         = filemd5("${path.root}/../frontend/style.css")
}

# Upload app.js with API endpoint replacement
data "template_file" "app_js" {
  template = file("${path.root}/../frontend/app.js")
  vars = {
    API_ENDPOINT_PLACEHOLDER = var.api_endpoint
  }
}

resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "app.js"
  content      = data.template_file.app_js.rendered
  content_type = "application/javascript"
  etag         = md5(data.template_file.app_js.rendered)
}
