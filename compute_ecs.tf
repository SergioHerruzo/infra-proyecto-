resource "aws_ecs_cluster" "main" {
  name = "steam-cluster"
}

resource "aws_ecs_task_definition" "game_api" {
  family                   = "game-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  # AWS Academy: Using pre-created LabRole for task execution
  execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_role_name}"
  task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_role_name}"

  container_definitions = jsonencode([
    {
      name      = "game-api-container"
      image     = "nginx:latest" # Placeholder image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        { name = "DATABASE_URL", value = aws_db_instance.postgres.endpoint },
        { name = "S3_BUCKET", value = aws_s3_bucket.game_storage.id }
      ]
    }
  ])
}
