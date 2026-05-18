# -------------------------------------------------------
# VPC principal
# -------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "steam-indio-vpc"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# Subnets públicas — Beanstalk + ECS (2 AZs)
# assign_public_ip evita el coste de NAT Gateway en Academy
# -------------------------------------------------------

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "steam-public-a"
    Project = "steam-indio"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "steam-public-b"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# Subnets privadas — RDS (2 AZs requeridas por db_subnet_group)
# -------------------------------------------------------

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name    = "steam-private-a"
    Project = "steam-indio"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name    = "steam-private-b"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# Internet Gateway
# -------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "steam-igw"
    Project = "steam-indio"
  }
}

# -------------------------------------------------------
# NAT Gateway — Para dar salida a Internet a subredes privadas
# (Necesario para que la Lambda en VPC conecte a Cognito)
# -------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "steam-nat-eip"
    Project = "steam-indio"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # Ubicado en subred pública

  tags = {
    Name    = "steam-nat-gw"
    Project = "steam-indio"
  }

  # Recomendado: esperar a que el IGW esté listo
  depends_on = [aws_internet_gateway.main]
}

# -------------------------------------------------------
# Route table — pública (con salida a Internet)
# -------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "steam-rt-public"
    Project = "steam-indio"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# -------------------------------------------------------
# Route table — privada (sin NAT: ahorrar créditos Academy)
# RDS solo necesita comunicación interna desde la VPC
# -------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name    = "steam-rt-private"
    Project = "steam-indio"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# -------------------------------------------------------
# Security Groups por servicio
# -------------------------------------------------------

# --- Backend EC2 (Docker) ---
resource "aws_security_group" "backend_ec2_sg" {
  name        = "steam-backend-ec2-sg-${random_string.suffix.result}"
  description = "Permite HTTP desde API Gateway y SSH desde administrador"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde API Gateway (o internet publico)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH para administracion"
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
    Name    = "steam-backend-ec2-sg"
    Project = "steam-indio"
  }
}
