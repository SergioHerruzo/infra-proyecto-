# S3 Bucket for games and files
resource "aws_s3_bucket" "game_storage" {
  bucket = "steamindio-storage-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "game_storage" {
  bucket = aws_s3_bucket.game_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  db_name              = "personalsteam"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  username             = "steamadmin"
  password             = "steam_secure_password" # In production, use a secret manager
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  storage_encrypted    = true
  
  # Using default KMS key for RDS as custom key creation is often blocked in Academy
  kms_key_id = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/aws/rds"
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_security_group" "db_sg" {
  name        = "steam-rds-sg"
  description = "Allow incoming traffic to RDS"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Narrow this down to your VPC CIDR in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
