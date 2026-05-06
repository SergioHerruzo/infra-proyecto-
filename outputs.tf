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

# -------------------------------------------------------
# Outputs - API Gateway
# -------------------------------------------------------

output "api_gateway_url" {
  description = "URL de invocación del API Gateway REST (usar como VITE_API_URL)"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "api_gateway_id" {
  description = "ID del API Gateway REST"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_key" {
  description = "API Key para el frontend (sensible)"
  value       = aws_api_gateway_api_key.frontend.value
  sensitive   = true
}
