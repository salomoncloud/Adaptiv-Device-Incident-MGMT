# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Basic Lambda execution policy
resource "aws_iam_policy_attachment" "lambda_basic" {
  name       = "lambda_basic_attach"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB access policy for Lambda functions
resource "aws_iam_policy" "dynamodb_access" {
  name        = "lambda_dynamodb_access"
  description = "IAM policy for Lambda to access DynamoDB tables"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      Resource = [
        "arn:aws:dynamodb:${var.region}:*:table/${var.devices_table_name}",
        "arn:aws:dynamodb:${var.region}:*:table/${var.incidents_table_name}"
      ]
    }]
  })
}

# Attach DynamoDB policy to Lambda role
resource "aws_iam_policy_attachment" "lambda_dynamodb" {
  name       = "lambda_dynamodb_attach"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Build Lambda deployment packages
resource "null_resource" "lambda_build" {
  triggers = {
    # Rebuild if any Python file changes
    create_incident_hash   = filemd5("${path.module}/../../backend/create_incident/handler.py")
    get_recurring_hash     = filemd5("${path.module}/../../backend/get_recurring/handler.py")
    get_all_incidents_hash = filemd5("${path.module}/../../backend/get_all_incidents/handler.py")
    export_csv_hash        = filemd5("${path.module}/../../backend/export_csv/handler.py")
  }

  provisioner "local-exec" {
    command = "chmod +x ./build.sh && ./build.sh"
    working_dir = path.module
  }
}

# Lambda function: Create Incident
resource "aws_lambda_function" "create_incident" {
  depends_on = [null_resource.lambda_build]
  
  function_name = var.incident_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/../../backend/create_incident.zip"
  timeout       = 10

  environment {
    variables = {
      DEVICES_TABLE   = var.devices_table_name
      INCIDENTS_TABLE = var.incidents_table_name
    }
  }

  # Update function if ZIP file changes
  source_code_hash = filebase64sha256("${path.module}/../../backend/create_incident.zip")
}

# Lambda function: Get Recurring Incidents
resource "aws_lambda_function" "recurring_offender" {
  depends_on = [null_resource.lambda_build]
  
  function_name = var.recurring_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/../../backend/get_recurring.zip"
  timeout       = 10

  environment {
    variables = {
      INCIDENTS_TABLE = var.incidents_table_name
      SLACK_TOKEN     = var.slack_token
    }
  }

  source_code_hash = filebase64sha256("${path.module}/../../backend/get_recurring.zip")
}

# Lambda function: Get All Incidents
resource "aws_lambda_function" "get_all_incidents" {
  depends_on = [null_resource.lambda_build]
  
  function_name = "get-all-incidents"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/../../backend/get_all_incidents.zip"
  timeout       = 10

  environment {
    variables = {
      INCIDENTS_TABLE = var.incidents_table_name
    }
  }

  source_code_hash = filebase64sha256("${path.module}/../../backend/get_all_incidents.zip")
}

# Lambda function: Export CSV
resource "aws_lambda_function" "export_csv" {
  depends_on = [null_resource.lambda_build]
  
  function_name = "export-csv"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/../../backend/export_csv.zip"
  timeout       = 10

  environment {
    variables = {
      INCIDENTS_TABLE = var.incidents_table_name
    }
  }

  source_code_hash = filebase64sha256("${path.module}/../../backend/export_csv.zip")
}
