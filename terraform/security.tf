resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Comunicacao do Control Plane com os Workers"
  vpc_id      = aws_vpc.main.id 

  tags = {
    Name = "eks-cluster-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "cluster_outbound" {
  security_group_id = aws_security_group.eks_cluster_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

resource "aws_vpc_security_group_ingress_rule" "cluster_https_inbound" {
  security_group_id = aws_security_group.eks_cluster_sg.id
  cidr_ipv4         = "0.0.0.0/0" 
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_security_group" "eks_node_sg" {
  name        = "eks-node-sg"
  description = "Security Group dos Worker Nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "eks-node-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "node_outbound" {
  security_group_id = aws_security_group.eks_node_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "node_self" {
  security_group_id = aws_security_group.eks_node_sg.id
  
  referenced_security_group_id = aws_security_group.eks_node_sg.id 
  
  ip_protocol = "-1" 
}

resource "aws_vpc_security_group_ingress_rule" "node_from_cluster" {
  security_group_id = aws_security_group.eks_node_sg.id
  
  referenced_security_group_id = aws_security_group.eks_cluster_sg.id
  
  ip_protocol = "-1"
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Permite trafego publico para o Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-sg"
  }
}

#Permite entrada HTTP (80) de qualquer lugar
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id = aws_security_group.eks_node_sg.id
  
  referenced_security_group_id = aws_security_group.alb_sg.id
  
  ip_protocol = "-1" 
}