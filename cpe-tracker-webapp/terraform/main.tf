terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Additional provider for ACM certificates (CloudFront requires us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

module "cognito" {
  source = "./modules/cognito"
  user_pool_name = "cpe-tracker-users"
  shared_username = var.shared_username
  shared_password = var.shared_password
}

module "dynamodb" {
  source = "./modules/dynamodb"
  devices_table_name  = var.devices_table_name
  incidents_table_name = var.incidents_table_name
}

module "lambda" {
  source = "./modules/lambda"
  region = var.aws_region
  incident_function_name = var.incident_function_name
  recurring_function_name = var.recurring_function_name
  devices_table_name = var.devices_table_name
  incidents_table_name = var.incidents_table_name
}

module "api_gateway" {
  source = "./modules/api_gateway"
  api_name = var.api_name

  create_incident_function_arn = module.lambda.create_incident_function_arn
  create_incident_function_name = var.incident_function_name
  
  get_recurring_function_arn   = module.lambda.recurring_offender_function_arn
  get_recurring_function_name  = var.recurring_function_name
  
  get_all_incidents_function_arn = module.lambda.get_all_incidents_function_arn
  get_all_incidents_function_name = "get-all-incidents"
  
  export_csv_function_arn = module.lambda.export_csv_function_arn
  export_csv_function_name = "export-csv"
}

module "s3_frontend" {
  source = "./modules/s3_frontend"
  bucket_name = var.frontend_bucket_name
  api_endpoint = module.api_gateway.api_endpoint
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
}

module "cloudfront" {
  source = "./modules/cloudfront"
  
  domain_name = var.domain_name
  bucket_name = var.frontend_bucket_name
  s3_bucket_domain_name = module.s3_frontend.bucket_domain_name
  
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
  
  depends_on = [module.s3_frontend]
}

module "eventbridge" {
  source = "./modules/eventbridge"
  recurring_function_arn = module.lambda.recurring_offender_function_arn
}
