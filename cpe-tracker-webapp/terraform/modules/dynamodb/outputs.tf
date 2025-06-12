output "devices_table_name" {
  value = aws_dynamodb_table.devices.name
}

output "incidents_table_name" {
  value = aws_dynamodb_table.incidents.name
}
