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
  description = "Cloudflare API Token"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
}

variable "github_access_token" {
  description = "GitHub Personal Access Token for Amplify"
  sensitive   = true
}
