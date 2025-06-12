variable "region" {
  type = string
}

variable "incident_function_name" {
  type = string
}

variable "recurring_function_name" {
  type = string
}

variable "devices_table_name" {
  type = string
  default = "cpe_devices"
}

variable "incidents_table_name" {
  type = string
  default = "cpe_incidents"
}

variable "slack_token" {
  type = string
  default = ""
}
