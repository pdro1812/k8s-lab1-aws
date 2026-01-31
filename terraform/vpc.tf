resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Subnets públicas
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1a"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/meu-cluster" = "shared"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1b"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/meu-cluster" = "shared"
  }
}

# Subnets privadas
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/meu-cluster" = "shared"
  }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/meu-cluster" = "shared"
  }
}

# NAT Gateway (single AZ)
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "main-nat"
  }
}

# Route table pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

# Route table privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private.id
}

# VPC Endpoints (Conectividade Privada)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name = "dynamodb-endpoint"
  }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Allow HTTPS from VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] 
  }

  tags = {
    Name = "vpc-endpoint-sg"
  }
}

# 3. Interface Endpoint para CloudWatch (Monitoring)
resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.monitoring"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id
  ]

  private_dns_enabled = true

  tags = {
    Name = "cloudwatch-endpoint"
  }
}