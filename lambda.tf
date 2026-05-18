# -------------------------------------------------------
# AWS Lambda — Función de utilidad / backend
# -------------------------------------------------------

# Empaquetado del código
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "main" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "steam-indio-utility"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_role_name}"
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"

  # Configuración de red (VPC)
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Permitir gestión manual del código
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      handler,
      runtime
    ]
  }

  environment {
    variables = {
      ENV          = "production"
      DATABASE_URL = "postgresql://admin:Pirineus12!@${aws_db_instance.postgres.endpoint}/postgres"

      # Authentication
      Authentication__Region                = var.aws_region
      Authentication__Authority             = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
      Authentication__UserPoolId            = aws_cognito_user_pool.main.id
      Authentication__ClientId              = aws_cognito_user_pool_client.client.id
      Authentication__AuthorizationEndpoint = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize"
      Authentication__TokenEndpoint         = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"

      # Database
      Database__ConnectionString = "Host=${aws_db_instance.postgres.address};Port=5432;Database=${aws_db_instance.postgres.db_name};Username=admin;Password=Pirineus12!;SSL Mode=VerifyFull;Root Certificate=./global-bundle.pem"

      # S3
      S3__Region       = var.aws_region
      S3__BucketName   = aws_s3_bucket.game_storage.id
      S3__AccessKey    = var.academy_aws_access_key
      S3__SecretKey    = var.academy_aws_secret_key
      S3__SessionToken = var.academy_aws_session_token

      # Messaging (SQS)
      Messaging__Address      = var.aws_region
      Messaging__AccessKey    = var.academy_aws_access_key
      Messaging__SecretKey    = var.academy_aws_secret_key
      Messaging__SessionToken = var.academy_aws_session_token

      # Stripe
      Stripe__SecretKey      = var.stripe_secret_key
      Stripe__WebhookSecret  = var.stripe_webhook_secret
      Stripe__PublishableKey = var.stripe_publishable_key
      Stripe__Currency       = var.stripe_currency
    }
  }

  tags = {
    Name    = "steam-indio-lambda"
    Project = "steam-indio"
  }
}

# CloudWatch Log Group para la Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/steam-indio-utility"
  retention_in_days = 14
}

# Security Group para la Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "steam-lambda-sg-${random_string.suffix.result}"
  description = "Permite salida de la Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "steam-lambda-sg"
  }
}

# Permiso para que API Gateway invoque la Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}
