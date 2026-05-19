# -------------------------------------------------------
# AWS Cognito - User Pool & Client
# -------------------------------------------------------

resource "aws_cognito_user_pool" "main" {
  name = "steam-user-pool"

  # Users sign in with their username or preferred_username (nombre)
  alias_attributes = ["preferred_username"]

  # Automatically verify email on sign-up
  auto_verified_attributes = ["email"]

  # Password policy
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

  # Name required at registration
  schema {
    attribute_data_type = "String"
    name                = "name"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  # preferred_username allows login with a chosen name (alias)
  schema {
    attribute_data_type = "String"
    name                = "preferred_username"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  # Email verification message
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Tu código de verificación de Steam Indio"
    email_message        = "Tu código de verificación es: {####}"
  }

  # Account recovery via email
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

  # No client secret (suitable for public clients like SPAs or mobile apps)
  generate_secret = false

  # Allowed OAuth flows
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # Auth flows allowed
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  # Token validity
  access_token_validity  = 1   # hours
  id_token_validity      = 1   # hours
  refresh_token_validity = 30  # days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Prevent user existence errors leaking
  prevent_user_existence_errors = "ENABLED"

  # Callback / logout URLs (update with your real URLs)
  callback_urls = ["https://${var.github_branch}.${aws_amplify_app.prod.default_domain}/callback"]
  logout_urls   = ["https://${var.github_branch}.${aws_amplify_app.prod.default_domain}/logout"]
}

# -------------------------------------------------------
# Cognito User Pool Domain
# -------------------------------------------------------

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "steam-indio-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}
