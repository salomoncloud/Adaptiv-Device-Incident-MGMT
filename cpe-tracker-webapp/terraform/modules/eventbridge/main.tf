resource "aws_cloudwatch_event_rule" "recurring_offender_schedule" {
  name                = "recurring-offender-daily-check"
  description         = "Daily trigger for recurring offender Lambda"
  schedule_expression = "rate(24 hours)"  # change to cron if needed
}

resource "aws_cloudwatch_event_target" "recurring_offender_target" {
  rule      = aws_cloudwatch_event_rule.recurring_offender_schedule.name
  arn       = var.recurring_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.recurring_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.recurring_offender_schedule.arn
}
