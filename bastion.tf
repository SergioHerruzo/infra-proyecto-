# -------------------------------------------------------
# Bastion Host — acceso SSH a la VPC y túnel a RDS
# -------------------------------------------------------

# AMI: Amazon Linux 2023 más reciente en la región
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group del bastion — solo SSH desde tu IP
resource "aws_security_group" "bastion_sg" {
  name        = "steam-bastion-sg-${random_string.suffix.result}"
  description = "SSH restringido a la IP del administrador"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH desde IP del admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "steam-bastion-sg"
    Project = "steam-indio"
  }
}

# Regla extra en db_sg: permite que el bastion acceda a RDS
resource "aws_security_group_rule" "db_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "PostgreSQL desde bastion"
}

# EC2 Bastion — t3.micro en subnet pública
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = var.bastion_key_name

  # AWS Academy: usar LabInstanceProfile
  iam_instance_profile = var.lab_instance_profile_name

  tags = {
    Name    = "steam-bastion"
    Project = "steam-indio"
  }
}
