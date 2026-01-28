resource "aws_eks_cluster" "lab_cluster" {
  name     = "meu-lab-cluster" 
  
  # Correção: Adicionados os pontos (.)
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_1a.id,
      aws_subnet.private_1a.id,
      aws_subnet.public_1b.id, 
      aws_subnet.private_1b.id  
    ]

    security_group_ids = [aws_security_group.eks_cluster_sg.id]

    endpoint_public_access  = true
    endpoint_private_access = true  
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
  ]
}