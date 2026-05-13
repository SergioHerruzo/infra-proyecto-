# -------------------------------------------------------
# AWS Amplify - Frontend Hosting
# -------------------------------------------------------

resource "aws_amplify_app" "frontend" {
  name       = "steam-indio-frontend"
  repository = var.github_repo_url

  # GitHub OAuth token (Personal Access Token)
  access_token = var.github_token

  # Build spec for Vite projects
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

  # Environment variables injected at build time
  # Cognito values come from auth.tf, API URL from api_gateway.tf
  environment_variables = {
    VITE_AWS_USER_POOL_ID        = aws_cognito_user_pool.main.id
    VITE_AWS_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
    VITE_API_URL                 = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
  }

  tags = {
    Name    = "steam-indio-frontend"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# Amplify Branch
# -------------------------------------------------------

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.github_branch

  # Stage can be: PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST
  stage = "PRODUCTION"

  enable_auto_build = true

  tags = {
    Name = "steam-indio-branch-${var.github_branch}"
  }
}
