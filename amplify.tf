resource "aws_amplify_app" "app" {
  name         = "steam-frontend"
  repository   = var.github_repo
  access_token = var.github_access_token
  platform     = "WEB"

  # IMPORTANT: Your GitHub PAT must have 'repo' and 'admin:repo_hook' scopes.
  # The 'Not Found' (404) error on list-repository-webhooks usually means 
  # these permissions are missing.
  enable_auto_branch_creation = false
  enable_branch_auto_build    = false
}

resource "aws_amplify_domain_association" "app" {
  app_id      = aws_amplify_app.app.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = "main"
    prefix      = ""
  }
}
