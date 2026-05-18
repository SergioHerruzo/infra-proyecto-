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

# -------------------------------------------------------
# Outputs - VPC & Networking
# -------------------------------------------------------

output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas (Beanstalk + ECS)"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas (RDS)"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

# -------------------------------------------------------
# Outputs - Compute
# -------------------------------------------------------

output "backend_ec2_public_ip" {
  description = "IP publica de la instancia EC2 del backend"
  value       = aws_instance.backend.public_ip
}

output "backend_ec2_public_dns" {
  description = "DNS publico de la instancia EC2 del backend"
  value       = aws_instance.backend.public_dns
}

output "rds_endpoint" {
  description = "Endpoint de RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 de almacenamiento"
  value       = aws_s3_bucket.game_storage.id
}

# -------------------------------------------------------
# Outputs - Bastion
# -------------------------------------------------------

output "bastion_public_ip" {
  description = "IP pública estática (EIP) del Bastion Host"
  value       = aws_eip.bastion.public_ip
}

# -------------------------------------------------------
# Outputs - Lambda
# -------------------------------------------------------

output "lambda_function_arn" {
  description = "ARN de la función Lambda de utilidad"
  value       = aws_lambda_function.main.arn
}

# -------------------------------------------------------
# Outputs - Amplify (Frontend)
# -------------------------------------------------------

output "amplify_app_url_prod" {
  description = "URL de producción (rama main)"
  value       = "https://www.${var.domain_name}"
}

output "amplify_app_url_dev" {
  description = "URL de desarrollo (rama develop)"
  value       = "https://dev.${var.domain_name}"
}

