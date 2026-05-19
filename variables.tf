variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "lab_role_name" {
  description = "The name of the pre-created LabRole"
  default     = "LabRole"
}

variable "lab_instance_profile_name" {
  description = "The name of the pre-created LabInstanceProfile"
  default     = "LabInstanceProfile"
}

# -------------------------------------------------------
# Amplify variables
# -------------------------------------------------------

variable "github_repo_url" {
  description = "URL del repositorio GitHub para la web de USUARIOS (PROD)"
}

variable "github_repo_url_dev" {
  description = "URL del repositorio GitHub para la web de DEVS (DEV)"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  sensitive   = true
}

variable "github_branch" {
  description = "Rama para la web de PROD"
  default     = "main"
}

variable "github_branch_dev" {
  description = "Rama para la web de DEV"
  default     = "main"
}

# -------------------------------------------------------
# Networking / DNS
# -------------------------------------------------------

# -------------------------------------------------------
# Bastion / Access
# -------------------------------------------------------

variable "my_ip_cidr" {
  description = "Tu dirección IP pública en formato CIDR (ej: 1.2.3.4/32) para permitir SSH"
  default     = "0.0.0.0/0"
}

variable "bastion_key_name" {
  description = "Nombre del Key Pair de EC2 existente para acceder al bastion (ej: vockey)"
  default     = "vockey"
}

# -------------------------------------------------------
# Stripe Config
# -------------------------------------------------------

variable "stripe_secret_key" {
  description = "Stripe Secret Key"
  sensitive   = true
}

variable "stripe_webhook_secret" {
  description = "Stripe Webhook Secret"
  sensitive   = true
}

variable "stripe_publishable_key" {
  description = "Stripe Publishable Key"
  sensitive   = true
}

variable "stripe_currency" {
  description = "Stripe Currency"
  default     = "eur"
}

# -------------------------------------------------------
# AWS Academy Temporary Credentials (not recommended for prod)
# -------------------------------------------------------

variable "academy_aws_access_key" {
  description = "AWS Academy Access Key"
  sensitive   = true
}

variable "academy_aws_secret_key" {
  description = "AWS Academy Secret Key"
  sensitive   = true
}

variable "academy_aws_session_token" {
  description = "AWS Academy Session Token"
  sensitive   = true
}
