resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole" 
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name 
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" 
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com" 
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# Habilitar o OIDC Provider para o Cluster
data "tls_certificate" "lab" {
  url = aws_eks_cluster.lab_cluster.identity[0].oidc[0].issuer
}

# Cria o provedor de identidade
resource "aws_iam_openid_connect_provider" "lab" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.lab.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.lab_cluster.identity[0].oidc[0].issuer
}

# Cria a Role que a Aplicação vai usar (ex: acessar DynamoDB)
resource "aws_iam_role" "app_role" {
  name = "eks-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.lab.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.lab.url, "https://", "")}:sub": "system:serviceaccount:default:minha-app-sa"
          }
        }
      }
    ]
  })
}

# Anexa a permissão do DynamoDB nessa Role
resource "aws_iam_role_policy_attachment" "app_dynamo" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" 
}