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

resource "aws_iam_policy_attachment" "lambda_basic" {
  name       = "lambda_basic_attach"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "create_incident" {
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
}

resource "aws_lambda_function" "recurring_offender" {
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
}

resource "aws_lambda_function" "get_all_incidents" {
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
}

resource "aws_lambda_function" "export_csv" {
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
}
