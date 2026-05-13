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

# --- Beanstalk (backend HTTP) ---
resource "aws_security_group" "beanstalk_sg" {
  name        = "steam-beanstalk-sg-${random_string.suffix.result}"
  description = "Permite HTTP desde API Gateway y salida libre"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde API Gateway (HTTP_PROXY)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "steam-beanstalk-sg"
    Project = "steam-indio"
  }
}

# --- ECS Fargate ---
resource "aws_security_group" "ecs_sg" {
  name        = "steam-ecs-sg-${random_string.suffix.result}"
  description = "Permite trafico interno al contenedor ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Trafico de aplicacion"
    from_port   = 80
    to_port     = 80
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
    Name    = "steam-ecs-sg"
    Project = "steam-indio"
  }
}
