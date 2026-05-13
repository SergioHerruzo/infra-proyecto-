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
      last_modified,
      handler,
      runtime
    ]
  }

  environment {
    variables = {
      ENV          = "production"
      DATABASE_URL = "postgresql://steamadmin:steam_secure_password@${aws_db_instance.postgres.endpoint}/personalsteam"
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
