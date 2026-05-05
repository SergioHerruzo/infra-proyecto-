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
