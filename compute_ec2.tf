# -------------------------------------------------------
# EC2 Backend - Docker Host
# -------------------------------------------------------

# Buscar la AMI más reciente de Amazon Linux 2023
data "aws_ami" "amazon_linux_2023_backend" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "backend" {
  ami           = data.aws_ami.amazon_linux_2023_backend.id
  instance_type = "t3.small"

  # Ubicación en subred pública para acceso directo a internet y API Gateway
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.backend_ec2_sg.id]
  associate_public_ip_address = true

  # Key Pair para acceso SSH (definido en variables)
  key_name = var.bastion_key_name

  # IAM Instance Profile para permisos nativos a S3, SQS y SSM (AWS Academy LabRole)
  iam_instance_profile = var.lab_instance_profile_name

  # User Data para instalar Docker y Docker Compose en el arranque
  user_data = <<-EOF
    #!/bin/bash
    # Actualizar sistema
    dnf update -y
    
    # Instalar Docker
    dnf install -y docker
    
    # Iniciar y habilitar servicio de Docker
    systemctl start docker
    systemctl enable docker
    
    # Añadir usuario ec2-user al grupo docker
    usermod -aG docker ec2-user
    
    # Instalar Docker Compose (plugin)
    dnf install -y docker-compose-plugin

    # Instalar Git por si se necesita clonar repositorios
    dnf install -y git
  EOF

  tags = {
    Name    = "steam-backend-ec2"
    Project = "steam-indio"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
