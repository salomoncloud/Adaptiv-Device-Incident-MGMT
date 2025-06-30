resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = []
    max_age          = 86400
  }
}

resource "aws_apigatewayv2_integration" "create_incident" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.create_incident_function_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "get_recurring" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.get_recurring_function_arn
  integration_method = "GET"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "get_all_incidents" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.get_all_incidents_function_arn
  integration_method = "GET"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "export_csv" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.export_csv_function_arn
  integration_method = "GET"
  payload_format_version = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "post_incident" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /incident"
  target    = "integrations/${aws_apigatewayv2_integration.create_incident.id}"
}

resource "aws_apigatewayv2_route" "get_recurring" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /recurring"
  target    = "integrations/${aws_apigatewayv2_integration.get_recurring.id}"
}

resource "aws_apigatewayv2_route" "get_all_incidents" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /incidents"
  target    = "integrations/${aws_apigatewayv2_integration.get_all_incidents.id}"
}

resource "aws_apigatewayv2_route" "export_csv" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /export-csv"
  target    = "integrations/${aws_apigatewayv2_integration.export_csv.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "create_incident" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.create_incident_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_recurring" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.get_recurring_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_all_incidents" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.get_all_incidents_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "export_csv" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.export_csv_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
