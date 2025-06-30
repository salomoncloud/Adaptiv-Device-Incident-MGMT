variable "aws_access_key_id" {
type = string
}

variable "aws_secret_access_key" {
type = string
}

variable "aws_region" {
type = string
default = "ca-central-1"
}

variable "shared_username" {
type = string
default = "Adaptiv_user"
}

variable "shared_password" {
type = string
}

variable "devices_table_name" {
  type    = string
  default = "cpe_devices"
}

variable "incidents_table_name" {
type    = string
default = "cpe_incidents"
}

variable "incident_function_name" {
type    = string
default = "create-incident-handler"
}

variable "recurring_function_name" {
type    = string
default = "recurring-offender-checker"
}

variable "frontend_bucket_name" {
type    = string
default = "cpe-tracker-frontend-bucket"
}

variable "api_name" {
type    = string
default = "cpe-tracker-api"
}

variable "slack_token" {
  type        = string
  description = "Slack bot token for notifications (eventual addition)"
}
