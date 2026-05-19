resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# S3 Bucket for games and files
resource "aws_s3_bucket" "game_storage" {
  bucket = "steamindio-storage-${data.aws_caller_identity.current.account_id}-${random_string.suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "game_storage" {
  bucket = aws_s3_bucket.game_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------------------------------------
# RDS — Subnet Group (requiere mínimo 2 AZs)
# -------------------------------------------------------

resource "aws_db_subnet_group" "postgres" {
  name        = "steam-db-subnet-group-${random_string.suffix.result}"
  description = "Subnets privadas para RDS PostgreSQL"
  subnet_ids  = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name    = "steam-db-subnet-group"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# RDS PostgreSQL
# -------------------------------------------------------

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  db_name              = "postgres"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  username             = "dbadminla "
  password             = "Pirineus12!" # En producción usar Secrets Manager
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  storage_encrypted    = true

  # Using default KMS key for RDS (custom key creation blocked in Academy)
  kms_key_id = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/aws/rds"

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name    = "steam-postgres"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# Security Group — RDS (solo tráfico interno VPC)
# -------------------------------------------------------

resource "aws_security_group" "db_sg" {
  name        = "steam-rds-sg-${random_string.suffix.result}"
  description = "Allow PostgreSQL only from within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL desde la VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "steam-rds-sg"
    Project = "steam-indio"
  }
}
