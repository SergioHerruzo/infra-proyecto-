# -------------------------------------------------------
# AWS Cognito - User Pool & Client
# -------------------------------------------------------

resource "aws_cognito_user_pool" "main" {
  name = "steam-user-pool"

  alias_attributes         = ["email", "preferred_username"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "preferred_username"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Tu código de verificación de Steam Indio"
    email_message        = "Tu código de verificación es: {####}"
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name        = "steam-user-pool"
    Environment = "production"
    Project     = "steam-indio"
  }
}

# -------------------------------------------------------
# Cognito User Pool Client (App Client)
# -------------------------------------------------------

resource "aws_cognito_user_pool_client" "client" {
  name         = "steam-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  callback_urls = [var.frontend_callback_url]
  logout_urls   = ["${var.frontend_callback_url}/logout"]
}

# -------------------------------------------------------
# Cognito User Pool Domain
# -------------------------------------------------------

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "steam-indio-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}
