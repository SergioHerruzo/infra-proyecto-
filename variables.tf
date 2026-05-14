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

variable "domain_name" {
  description = "Nombre de dominio público para la aplicación (ej: steamindio.com)"
}
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
