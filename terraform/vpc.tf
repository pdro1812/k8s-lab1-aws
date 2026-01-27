# vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # Defina seu bloco de IP
  
  tags = {
    Name = "main-vpc"
  }
}

# 2. INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# 3. SUBNET PÚBLICA
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" 
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1a"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/meu-cluster" = "shared"
  }
}

# 4. SUBNET PRIVADA
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-1a"
    "kubernetes.io/role/internal-elb" = "1" 
    "kubernetes.io/cluster/meu-cluster" = "shared"
  }
}

# 5. NAT GATEWAY 
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "main-nat"
  }
  
  depends_on = [aws_internet_gateway.igw]
}

#rota publica
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"               
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

#rota privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id 
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}