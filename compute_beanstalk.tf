# Dynamically find the latest available Docker solution stack in this region
data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 .* running Docker$"
}

resource "aws_elastic_beanstalk_application" "steam_workers" {
  name        = "steam-workers-${random_string.suffix.result}"
  description = "Elastic Beanstalk Application for game workers"
}

resource "aws_elastic_beanstalk_environment" "prod" {
  name                = "steam-workers-prod-${random_string.suffix.result}"
  application         = aws_elastic_beanstalk_application.steam_workers.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.docker.name

  # AWS Academy: Single Instance to save credits
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.medium"
  }

  # AWS Academy: pre-created Instance Profile
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.lab_instance_profile_name
  }

  # Security group
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_sg.id
  }

  # VPC
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  # Subnet pública para la instancia (SingleInstance no usa ELB)
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.public_a.id
  }

  # Asignar IP pública para que API Gateway HTTP_PROXY pueda alcanzarla
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }
}
