output "create_incident_function_arn" {
  value = aws_lambda_function.create_incident.arn
}

output "recurring_offender_function_arn" {
  value = aws_lambda_function.recurring_offender.arn
}

output "get_all_incidents_function_arn" {
  value = aws_lambda_function.get_all_incidents.arn
}

output "export_csv_function_arn" {
  value = aws_lambda_function.export_csv.arn
}
