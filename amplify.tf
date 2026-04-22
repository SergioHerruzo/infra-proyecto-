resource "aws_amplify_app" "app_one" {
  name       = "steam-frontend-one"
  repository = "https://github.com/example/repo-one" # Placeholder
  
  # Often blocked in Academy, check permissions
}

resource "aws_amplify_app" "app_two" {
  name       = "steam-frontend-two"
  repository = "https://github.com/example/repo-two" # Placeholder
}

resource "aws_amplify_domain_association" "app_one" {
  app_id      = aws_amplify_app.app_one.id
  domain_name = "app1.${var.domain_name}"

  sub_domain {
    branch_name = "main"
    prefix      = ""
  }
}

resource "aws_amplify_domain_association" "app_two" {
  app_id      = aws_amplify_app.app_two.id
  domain_name = "app2.${var.domain_name}"

  sub_domain {
    branch_name = "main"
    prefix      = ""
  }
}
