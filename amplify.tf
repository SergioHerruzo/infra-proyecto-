resource "aws_amplify_app" "app" {
  name         = "steam-frontend"
  repository   = var.github_repo
  access_token = var.github_access_token
}

resource "aws_amplify_domain_association" "app" {
  app_id      = aws_amplify_app.app.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = "main"
    prefix      = ""
  }
}
