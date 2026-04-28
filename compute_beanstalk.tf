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

  # AWS Academy: Use Single Instance to save credits, but can be changed to LoadBalanced
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

  # AWS Academy: Critical - Use the pre-created Instance Profile
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.lab_instance_profile_name
  }

  # Service Role is also required but in Academy it's usually pre-linked
  # If it fails, you might need to specify the LabRole ARN here too if the trust is there.
}
