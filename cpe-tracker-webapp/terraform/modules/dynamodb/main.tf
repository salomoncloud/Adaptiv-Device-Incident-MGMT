resource "aws_dynamodb_table" "devices" {
  name         = var.devices_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "serial_number"

  attribute {
    name = "serial_number"
    type = "S"
  }

  tags = {
    Environment = "prod"
    Service     = "cpe-tracker"
  }
}

resource "aws_dynamodb_table" "incidents" {
  name         = var.incidents_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "incident_id"

  attribute {
    name = "incident_id"
    type = "S"
  }

  tags = {
    Environment = "prod"
    Service     = "cpe-tracker"
  }
}
