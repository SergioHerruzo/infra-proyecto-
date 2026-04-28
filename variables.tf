variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "domain_name" {
  description = "The domain name managed by Route 53 and Cloudflare"
}

variable "lab_role_name" {
  description = "The name of the pre-created LabRole"
  default     = "LabRole"
}

variable "lab_instance_profile_name" {
  description = "The name of the pre-created LabInstanceProfile"
  default     = "LabInstanceProfile"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token (se pedirá al desplegar)"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID del dominio (se pedirá al desplegar)"
}

variable "github_access_token" {
  description = "GitHub Personal Access Token para Amplify (se pedirá al desplegar)"
  sensitive   = true
}

variable "github_repo" {
  description = "URL del repositorio de GitHub para la app Amplify (ej: https://github.com/usuario/mi-repo)"
}
