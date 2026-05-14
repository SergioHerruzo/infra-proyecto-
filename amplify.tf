# -------------------------------------------------------
# AWS Amplify - APP PRODUCCIÓN (Usuarios)
# -------------------------------------------------------

resource "aws_amplify_app" "prod" {
  name       = "steam-prod-frontend"
  repository = var.github_repo_url
  access_token = var.github_token
  platform     = "WEB"

  # Build spec para Vite
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  environment_variables = {
    VITE_AWS_USER_POOL_ID        = aws_cognito_user_pool.main.id
    VITE_AWS_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
    VITE_API_URL                 = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/prod"
  }
}

resource "aws_amplify_branch" "prod_main" {
  app_id      = aws_amplify_app.prod.id
  branch_name = var.github_branch
  stage       = "PRODUCTION"
  enable_auto_build = true
}

# -------------------------------------------------------
# AWS Amplify - APP DESARROLLO (Developers)
# -------------------------------------------------------

resource "aws_amplify_app" "dev" {
  name       = "steam-dev-frontend"
  repository = var.github_repo_url_dev
  access_token = var.github_token
  platform     = "WEB"

  # Build spec (puedes ajustarla si el repo de dev es distinto)
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  environment_variables = {
    VITE_AWS_USER_POOL_ID        = aws_cognito_user_pool.main.id
    VITE_AWS_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
    VITE_API_URL                 = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/prod"
  }
}

resource "aws_amplify_branch" "dev_main" {
  app_id      = aws_amplify_app.dev.id
  branch_name = var.github_branch_dev
  stage       = "DEVELOPMENT"
  enable_auto_build = true
}
