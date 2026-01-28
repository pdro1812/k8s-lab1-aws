resource "aws_eks_node_group" "lab_nodes" {
  cluster_name    = aws_eks_cluster.lab_cluster.name
  node_group_name = "lab-node-group"
  
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1b.id
  ]

  instance_types = ["t3.medium"] # t3.medium é o mínimo recomendável para EKS
  
  capacity_type  = "SPOT" 

  scaling_config {
    desired_size = 2 # Começa com 2
    max_size     = 3 # Pode crescer até 3
    min_size     = 1 # Nunca fica com menos de 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry,
  ]
}