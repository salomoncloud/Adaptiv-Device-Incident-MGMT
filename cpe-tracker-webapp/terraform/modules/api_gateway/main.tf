resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
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

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

# Integration: GET /incidents
resource "aws_apigatewayv2_integration" "get_all_incidents" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.get_all_incidents_function_arn
  integration_method = "GET"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_all_incidents" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /incidents"
  target    = "integrations/${aws_apigatewayv2_integration.get_all_incidents.id}"
}

# Integration: GET /export-csv
resource "aws_apigatewayv2_integration" "export_csv" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.export_csv_function_arn
  integration_method = "GET"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "export_csv" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /export-csv"
  target    = "integrations/${aws_apigatewayv2_integration.export_csv.id}"
}
