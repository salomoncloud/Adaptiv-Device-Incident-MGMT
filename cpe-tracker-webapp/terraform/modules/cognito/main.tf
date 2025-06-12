resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id
  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
  ]
}

resource "aws_cognito_user" "shared_user" {
  user_pool_id         = aws_cognito_user_pool.this.id
  username             = var.shared_username
  temporary_password   = var.shared_password
  force_alias_creation = false
  message_action       = "SUPPRESS"  # ← prevents email from being sent

  attributes = {
    email = "${var.shared_username}@adaptiv.local"
  }

  lifecycle {
    ignore_changes = [password]
  }
}

