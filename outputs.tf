# -------------------------------------------------------
# Outputs - Cognito
# -------------------------------------------------------

output "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN del User Pool de Cognito"
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint del User Pool de Cognito"
  value       = aws_cognito_user_pool.main.endpoint
}

output "cognito_app_client_id" {
  description = "ID del cliente de aplicación de Cognito"
  value       = aws_cognito_user_pool_client.client.id
}

output "cognito_hosted_ui_url" {
  description = "URL de la interfaz de login alojada de Cognito"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}
